import 'package:firebase_auth/firebase_auth.dart';

/// Email/password authentication backed by Firebase Auth.
///
/// Methods let [FirebaseAuthException] propagate; the UI maps the error code
/// to a friendly message with `authErrorMessage()`.
class AuthRepository {
  AuthRepository(this._auth);

  final FirebaseAuth _auth;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) =>
      _auth.signInWithEmailAndPassword(email: email.trim(), password: password);

  Future<void> signUp({required String email, required String password}) =>
      _auth.createUserWithEmailAndPassword(
          email: email.trim(), password: password);

  Future<void> sendPasswordResetEmail(String email) =>
      _auth.sendPasswordResetEmail(email: email.trim());

  Future<void> signOut() => _auth.signOut();
}
