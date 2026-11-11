import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter/foundation.dart';

/// Central place for App Check activation and diagnostics.
///
/// Release builds use Play Integrity / App Attest. Side-loaded APKs on an
/// emulator cannot pass Play Integrity (`-14`), so an explicit build flag can
/// force the debug provider:
///
/// ```
/// flutter build apk --release --dart-define=APP_CHECK_DEBUG=true
/// ```
///
/// The debug provider token is pinned below instead of being generated per
/// installation, so rebuilds, re-installs and debug↔release switches keep the
/// same token already registered in Firebase Console → App Check → Apps →
/// Manage debug tokens. No new Console entry is needed.
class AppCheckService {
  AppCheckService._();

  static const bool forceDebugProvider = bool.fromEnvironment(
    'APP_CHECK_DEBUG',
  );

  /// Registered in Firebase Console for this project's Android app. It only
  /// bypasses App Check attestation for demo builds; Firebase Authentication
  /// and Security Rules still apply. Play Store releases should use Play
  /// Integrity instead, i.e. build without `APP_CHECK_DEBUG`.
  static const String _debugToken = '55097a8a-52b2-4efc-b732-f18d170c547b';

  static bool get usesDebugProvider => kDebugMode || forceDebugProvider;

  /// True once the SDK exchanged a token successfully.
  static bool tokenOk = false;

  static String get providerLabel => usesDebugProvider
      ? 'Debug provider'
      : 'Play Integrity / App Attest';

  /// Activates App Check and, in debug mode, captures the debug token.
  /// Throws when activation fails so the caller can keep the app usable but
  /// report the real cause.
  static Future<void> activate() async {
    await FirebaseAppCheck.instance.activate(
      providerAndroid: usesDebugProvider
          ? const AndroidDebugProvider(debugToken: _debugToken)
          : const AndroidPlayIntegrityProvider(),
      providerApple: usesDebugProvider
          ? const AppleDebugProvider()
          : const AppleAppAttestProvider(),
    );
    debugPrint('[AppCheck] Provider: $providerLabel');
    if (!usesDebugProvider) return;
    try {
      final result = await FirebaseAppCheck.instance.getTokenResult();
      tokenOk = (result?.token.trim().isNotEmpty) ?? false;
      debugPrint('[AppCheck] Token exchange ${tokenOk ? 'OK' : 'empty'}');
    } catch (e) {
      tokenOk = false;
      debugPrint('[AppCheck] Token exchange failed: $e');
    }
  }
}
