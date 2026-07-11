import 'package:firebase_auth/firebase_auth.dart' as fa;
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl {
  final AuthRemoteDatasource remoteDatasource;
  AuthRepositoryImpl(this.remoteDatasource);

  // Added 'role' parameter here
  Future<fa.User> signUp(
      String email, String password, String name, String role) {
    return remoteDatasource.signUp(
        email: email, password: password, name: name, role: role);
  }

  Future<fa.User> signIn(String email, String password) {
    return remoteDatasource.signIn(email: email, password: password);
  }

  Future<void> signOut() {
    return remoteDatasource.signOut();
  }

  Future<fa.User?> getCurrentUser() {
    return remoteDatasource.getCurrentUser();
  }
}
