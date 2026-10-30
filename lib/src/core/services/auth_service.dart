import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      debugPrint('Firebase Auth not initialized in current environment: $e');
      return null;
    }
  }

  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? Stream.value(null);

  User? get currentUser => _auth?.currentUser;

  Future<UserCredential?> signUpWithEmail(String email, String password) async {
    final auth = _auth;
    if (auth == null) throw Exception('Firebase no está configurado aún.');
    return await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential?> signInWithEmail(String email, String password) async {
    final auth = _auth;
    if (auth == null) throw Exception('Firebase no está configurado aún.');
    return await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth?.signOut();
  }
}
