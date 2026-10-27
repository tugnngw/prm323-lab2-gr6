/// Interface for authentication service.
///
/// Will be implemented with Firebase Authentication + Google Sign-In
/// in the Integrate phase.
abstract class AuthService {
  Future<void> signInWithGoogle();
  Future<void> signOut();
  Stream<bool> get authStateChanges;
  String? get currentUserId;
  String? get currentUserEmail;
}
