import 'package:firebase_auth/firebase_auth.dart' as fa;
import 'package:cloud_firestore/cloud_firestore.dart';

abstract class AuthRemoteDatasource {
  Future<fa.User> signIn({required String email, required String password});
  // Added 'role' parameter here
  Future<fa.User> signUp(
      {required String email,
      required String password,
      required String name,
      required String role});
  Future<void> signOut();
  Future<fa.User?> getCurrentUser();
}

class AuthRemoteDatasourceImpl implements AuthRemoteDatasource {
  final fa.FirebaseAuth firebaseAuth;
  final FirebaseFirestore firestore;

  AuthRemoteDatasourceImpl(
      {required this.firebaseAuth, required this.firestore});

  @override
  Future<fa.User> signIn(
      {required String email, required String password}) async {
    final credential = await firebaseAuth.signInWithEmailAndPassword(
        email: email, password: password);
    return credential.user!;
  }

  @override
  Future<fa.User> signUp(
      {required String email,
      required String password,
      required String name,
      required String role}) async {
    final credential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email, password: password);

    // Save the role to Firestore!
    await firestore.collection('users').doc(credential.user!.uid).set({
      'email': email,
      'displayName': name,
      'role': role, // <-- THIS IS WHAT FIXES IT
      'onboardingComplete': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    return credential.user!;
  }

  @override
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<fa.User?> getCurrentUser() async {
    return firebaseAuth.currentUser;
  }
}
