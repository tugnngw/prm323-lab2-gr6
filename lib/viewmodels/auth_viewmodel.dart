import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/crashlytics_service.dart';
import '../services/firebase_auth_service.dart';
import '../services/firestore_service.dart';
import '../services/messaging_service.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required this.authService,
    this.analyticsService,
    this.crashlyticsService,
    this.messagingService,
    this.firestoreService,
  }) {
    _init();
  }

  final AuthService authService;
  final AnalyticsService? analyticsService;
  final CrashlyticsService? crashlyticsService;

  /// Push wiring (Lab 3 T12): on login, ask for permission and register the
  /// device FCM token under `users/{uid}/tokens`. Null in tests that do not
  /// exercise push — token registration is then simply skipped (no fake token
  /// is ever written).
  final MessagingService? messagingService;
  final FirestoreService? firestoreService;
  StreamSubscription<bool>? _sub;

  bool _isLoading = false;
  String? _errorMessage;
  bool _isAuthenticated = false;
  bool _loginInstrumented = false;

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
      if (isAuth) {
        unawaited(_onLogin());
      } else {
        _loginInstrumented = false;
      }
      notifyListeners();
    });
  }

  /// One-time instrumentation after a successful sign-in (Lab 3 §4):
  /// Analytics user id + login_success event, Crashlytics user id + custom key.
  Future<void> _onLogin() async {
    if (_loginInstrumented) return;
    _loginInstrumented = true;

    final uid = currentUserId;
    try {
      if (uid != null) {
        await analyticsService?.setUserId(uid);
        await crashlyticsService?.setUserId(uid);
      }
      await analyticsService?.logLoginSuccess(method: 'google');
      await crashlyticsService?.setCustomKey('auth_method', 'google');
      unawaited(_registerPushToken(uid));
    } catch (e) {
      debugPrint('[Auth] Login instrumentation failed (non-fatal): $e');
    }
  }

  /// FCM permission + token registration (Lab 3 T12). Failures are logged,
  /// never surfaced as fake data: a device without a token simply receives
  /// no pushes and the Notification Center still reads Firestore.
  Future<void> _registerPushToken(String? uid) async {
    final messaging = messagingService;
    final firestore = firestoreService;
    if (messaging == null || firestore == null || uid == null) return;
    try {
      final granted = await messaging.requestPermission();
      if (!granted) {
        debugPrint('[Auth] Notification permission denied — skipping token registration.');
        return;
      }
      final token = await messaging.getToken();
      if (token == null || token.isEmpty) {
        debugPrint('[Auth] No FCM token available — skipping registration.');
        return;
      }
      await firestore.registerToken(uid, token);
      debugPrint('[Auth] Registered FCM token for $uid.');
    } catch (e) {
      debugPrint('[Auth] FCM token registration failed (non-fatal): $e');
    }
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
