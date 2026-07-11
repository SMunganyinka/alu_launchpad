import 'package:firebase_auth/firebase_auth.dart' as fa;
import '../../data/repositories/auth_repository_impl.dart';

class SignUpUseCase {
  final AuthRepositoryImpl repository;
  SignUpUseCase(this.repository);

  // Added 'role' parameter here
  Future<fa.User> call(
      String email, String password, String name, String role) {
    return repository.signUp(email, password, name, role);
  }
}
