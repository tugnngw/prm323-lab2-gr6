import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Firebase Crashlytics service for monitoring errors and unhandled exceptions.
class CrashlyticsService {
  CrashlyticsService({FirebaseCrashlytics? crashlytics})
      : _crashlytics = crashlytics ??
            (Firebase.apps.isNotEmpty ? FirebaseCrashlytics.instance : null);

  final FirebaseCrashlytics? _crashlytics;

  /// Sets up global error handlers for both Flutter framework errors and
  /// asynchronous platform dispatcher errors.
  Future<void> initialize() async {
    final client = _crashlytics;
    if (client == null) {
      debugPrint('[Crashlytics] No Firebase App initialized, skipping Crashlytics setup.');
      return;
    }

    try {
      // In debug mode, don't flood Crashlytics; keep collection enabled in release
      await client.setCrashlyticsCollectionEnabled(!kDebugMode);

      // Pass all uncaught "fatal" errors from the framework to Crashlytics
      FlutterError.onError = client.recordFlutterFatalError;

      // Pass all uncaught asynchronous errors to Crashlytics
      PlatformDispatcher.instance.onError = (error, stack) {
        client.recordError(error, stack, fatal: true);
        return true;
      };

      debugPrint('[Crashlytics] Initialized error handlers.');
    } catch (e) {
      debugPrint('[Crashlytics] Initialization error: $e');
    }
  }

  /// Records a non-fatal error with optional stack trace and reason
  Future<void> recordError(
    dynamic exception,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    final client = _crashlytics;
    if (client == null) {
      debugPrint('[Crashlytics Mock] recordError: $exception, reason: $reason');
      return;
    }

    try {
      await client.recordError(
        exception,
        stack,
        reason: reason,
        fatal: fatal,
      );
    } catch (e) {
      debugPrint('[Crashlytics] recordError error: $e');
    }
  }

  /// Logs custom message to Crashlytics breadcrumbs
  Future<void> log(String message) async {
    final client = _crashlytics;
    if (client == null) {
      debugPrint('[Crashlytics Mock] log: $message');
      return;
    }

    try {
      await client.log(message);
    } catch (e) {
      debugPrint('[Crashlytics] log error: $e');
    }
  }

  /// Associates the current user ID with crash reports
  Future<void> setUserId(String userId) async {
    final client = _crashlytics;
    if (client == null) {
      debugPrint('[Crashlytics Mock] setUserId: $userId');
      return;
    }

    try {
      await client.setUserIdentifier(userId);
    } catch (e) {
      debugPrint('[Crashlytics] setUserId error: $e');
    }
  }
}
