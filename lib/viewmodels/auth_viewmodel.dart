import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/auth_service.dart';
import '../services/firebase_auth_service.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({required this.authService}) {
    _init();
  }

  final AuthService authService;
  StreamSubscription<bool>? _sub;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _isAuthenticated;
  String? get currentUserId => authService.currentUserId;
  String? get currentUserEmail => authService.currentUserEmail;

  void _init() {
    _isAuthenticated = authService.currentUserId != null;
    _sub = authService.authStateChanges.listen((isAuth) {
      _isAuthenticated = isAuth;
      _isLoading = false;
      notifyListeners();
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.signInWithGoogle();
      // On success, authStateChanges will trigger and update _isAuthenticated
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Đã xảy ra lỗi không xác định. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await authService.signOut();
    } on AuthException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Đăng xuất thất bại. Vui lòng thử lại.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
