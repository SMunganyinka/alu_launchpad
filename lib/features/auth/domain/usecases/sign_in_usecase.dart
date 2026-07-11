import 'package:firebase_auth/firebase_auth.dart' as fa;
import '../../data/repositories/auth_repository_impl.dart';

class SignInUseCase {
  final AuthRepositoryImpl repository;
  SignInUseCase(this.repository);

  Future<fa.User> call(String email, String password) {
    return repository.signIn(email, password);
  }
}
