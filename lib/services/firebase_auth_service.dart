import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseAuthService {
  FirebaseAuth get _auth {
    if (Firebase.apps.isEmpty) {
      throw Exception('Firebase has not been initialized. Call Firebase.initializeApp() first.');
    }
    return FirebaseAuth.instance;
  }

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Get auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign in with email and password
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
    } catch (e) {
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  // Get user email
  String? get userEmail => _auth.currentUser?.email;
}

