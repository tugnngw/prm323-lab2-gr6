import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_service.dart';

/// Exception thrown when authentication fails with a user-friendly message.
class AuthException implements Exception {
  const AuthException(this.message, {this.code});

  final String message;
  final String? code;

  @override
  String toString() => message;
}

/// Firebase Authentication implementation supporting Google Sign-In.
class FirebaseAuthService implements AuthService {
  FirebaseAuthService({
    FirebaseAuth? auth,
    GoogleSignIn? googleSignIn,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(scopes: ['email', 'profile']);

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;

  @override
  String? get currentUserId => _auth.currentUser?.uid;

  @override
  String? get currentUserEmail => _auth.currentUser?.email;

  String? get currentUserDisplayName => _auth.currentUser?.displayName;

  String? get currentUserPhotoUrl => _auth.currentUser?.photoURL;

  @override
  Stream<bool> get authStateChanges =>
      _auth.authStateChanges().map((user) => user != null);

  @override
  Future<void> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User cancelled the sign-in flow — return cleanly without throwing error
        debugPrint('[Auth] Google Sign-In was cancelled by user.');
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      debugPrint('[Auth] Google Sign-In succeeded for uid: ${_auth.currentUser?.uid}');
    } on FirebaseAuthException catch (e) {
      debugPrint('[Auth] FirebaseAuthException: ${e.code} — ${e.message}');
      switch (e.code) {
        case 'network-request-failed':
          throw const AuthException(
            'Lỗi kết nối mạng. Vui lòng kiểm tra internet và thử lại.',
            code: 'network-request-failed',
          );
        case 'user-disabled':
          throw const AuthException(
            'Tài khoản này đã bị khóa. Vui lòng liên hệ ban quản trị.',
            code: 'user-disabled',
          );
        case 'account-exists-with-different-credential':
          throw const AuthException(
            'Tài khoản đã tồn tại với phương thức đăng nhập khác.',
            code: 'account-exists',
          );
        default:
          throw AuthException(
            e.message ?? 'Đăng nhập thất bại. Vui lòng thử lại.',
            code: e.code,
          );
      }
    } catch (e) {
      debugPrint('[Auth] Unexpected error during Google Sign-In: $e');
      throw const AuthException(
        'Đã xảy ra lỗi không xác định. Vui lòng thử lại.',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _auth.signOut(),
      ]);
      debugPrint('[Auth] Successfully signed out.');
    } catch (e) {
      debugPrint('[Auth] Error signing out: $e');
      throw const AuthException('Đăng xuất thất bại. Vui lòng thử lại.');
    }
  }
}
