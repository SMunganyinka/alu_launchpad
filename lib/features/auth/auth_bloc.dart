import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'domain/usecases/sign_in_usecase.dart';
import 'domain/usecases/sign_up_usecase.dart';
import 'data/repositories/auth_repository_impl.dart';

// --- EVENTS ---
abstract class AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String email, password;
  AuthLoginRequested(this.email, this.password);
}

class AuthRegisterRequested extends AuthEvent {
  final String email, password, name, role;
  AuthRegisterRequested(this.email, this.password, this.name, this.role);
}

class AuthLogoutRequested extends AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

// --- STATES ---
abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String uid;
  final String role;
  final bool isVerified;
  final bool onboardingComplete;

  AuthAuthenticated(
    this.uid, {
    this.role = 'student',
    this.isVerified = false,
    this.onboardingComplete = false,
  });
}

class AuthUnauthenticated extends AuthState {}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}

// --- BLOC ---
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final SignInUseCase signInUseCase;
  final SignUpUseCase signUpUseCase;
  final AuthRepositoryImpl repository;

  AuthBloc({
    required this.signInUseCase,
    required this.signUpUseCase,
    required this.repository,
  }) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onCheck);
    on<AuthLoginRequested>(_onLogin);
    on<AuthRegisterRequested>(_onRegister);
    on<AuthLogoutRequested>(_onLogout);
  }

  Future<AuthAuthenticated> _determineUserState(fa.User user) async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = userDoc.data();
    final role = data?['role'] ?? 'student';
    final isOnboarded = data?['onboardingComplete'] ?? false;

    bool isVerified = false;
    if (role == 'founder') {
      final startupQuery = await FirebaseFirestore.instance
          .collection('startups')
          .where('founderId', isEqualTo: user.uid)
          .where('isVerified', isEqualTo: true)
          .limit(1)
          .get();
      isVerified = startupQuery.docs.isNotEmpty;
    }

    return AuthAuthenticated(user.uid,
        role: role, isVerified: isVerified, onboardingComplete: isOnboarded);
  }

  Future<void> _onCheck(AuthCheckRequested e, Emitter<AuthState> emit) async {
    try {
      final user = await repository.getCurrentUser();
      if (user != null) {
        final state = await _determineUserState(user);
        emit(state);
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onLogin(AuthLoginRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await signInUseCase(e.email, e.password);
      final state = await _determineUserState(user);
      emit(state);
    } catch (_) {
      emit(AuthError("Login failed. Check your credentials."));
    }
  }

  Future<void> _onRegister(
      AuthRegisterRequested e, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final user = await signUpUseCase(e.email, e.password, e.name, e.role);
      emit(AuthAuthenticated(user.uid, role: e.role));
    } catch (_) {
      emit(AuthError("Registration failed. Email might be in use."));
    }
  }

  Future<void> _onLogout(AuthLogoutRequested e, Emitter<AuthState> emit) async {
    await repository.signOut();
    emit(AuthUnauthenticated());
  }
}
