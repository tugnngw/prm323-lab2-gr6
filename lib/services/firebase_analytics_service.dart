import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import 'analytics_service.dart';

/// Firebase Analytics implementation with strict PII filtering.
///
/// Lab 3 Requirement: Track ≥7 custom events.
/// Security Rule: Do NOT log personal data (real name, personal email, phone).
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService({FirebaseAnalytics? analytics})
      : _analytics = analytics ??
            (Firebase.apps.isNotEmpty ? FirebaseAnalytics.instance : null);

  final FirebaseAnalytics? _analytics;

  FirebaseAnalyticsObserver? get navigationObserver =>
      _analytics != null ? FirebaseAnalyticsObserver(analytics: _analytics) : null;

  // Blacklist of forbidden PII parameter keys
  static const _piiKeys = {
    'email',
    'user_email',
    'name',
    'user_name',
    'full_name',
    'student_name',
    'phone',
    'phone_number',
    'address',
  };

  /// Sanitizes parameters by removing any potential PII keys
  Map<String, Object>? _sanitizeParameters(Map<String, Object>? params) {
    if (params == null) return null;
    final sanitized = <String, Object>{};
    for (final entry in params.entries) {
      final lowerKey = entry.key.toLowerCase();
      if (!_piiKeys.contains(lowerKey)) {
        sanitized[entry.key] = entry.value;
      } else {
        debugPrint('[Analytics] Sanitized PII key "${entry.key}" removed.');
      }
    }
    return sanitized;
  }

  @override
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    final client = _analytics;
    final sanitized = _sanitizeParameters(parameters);
    if (client == null) {
      debugPrint('[Analytics Mock] Logged event: $name with params: $sanitized');
      return;
    }

    try {
      await client.logEvent(name: name, parameters: sanitized);
      debugPrint('[Analytics] Logged event: $name with params: $sanitized');
    } catch (e) {
      debugPrint('[Analytics] logEvent error: $e');
    }
  }

  @override
  Future<void> setUserId(String id) async {
    final client = _analytics;
    if (client == null) {
      debugPrint('[Analytics Mock] setUserId: $id');
      return;
    }

    try {
      await client.setUserId(id: id);
    } catch (e) {
      debugPrint('[Analytics] setUserId error: $e');
    }
  }

  @override
  Future<void> setCurrentScreen(String screenName) async {
    final client = _analytics;
    if (client == null) {
      debugPrint('[Analytics Mock] ScreenView: $screenName');
      return;
    }

    try {
      await client.logScreenView(screenName: screenName);
      debugPrint('[Analytics] ScreenView: $screenName');
    } catch (e) {
      debugPrint('[Analytics] setCurrentScreen error: $e');
    }
  }

  // ──────────────────────── 8 Predefined Lab 3 Events ────────────────────────

  /// Event 1: Login success
  Future<void> logLoginSuccess({required String method}) =>
      logEvent('login_success', parameters: {'method': method});

  /// Event 2: Course view
  Future<void> logCourseView({required String courseId, required String code}) =>
      logEvent('course_view', parameters: {'course_id': courseId, 'code': code});

  /// Event 3: Prerequisite check
  Future<void> logPrerequisiteCheck({
    required String courseId,
    required bool isEligible,
  }) =>
      logEvent('prerequisite_check', parameters: {
        'course_id': courseId,
        'is_eligible': isEligible ? 1 : 0,
      });

  /// Event 4: Task create
  Future<void> logTaskCreate({required String category}) =>
      logEvent('task_create', parameters: {'category': category});

  /// Event 5: Task complete
  Future<void> logTaskComplete({required String taskId}) =>
      logEvent('task_complete', parameters: {'task_id': taskId});

  /// Event 6: Note create
  Future<void> logNoteCreate({required int contentLength}) =>
      logEvent('note_create', parameters: {'content_length': contentLength});

  /// Event 7: Advisor query
  Future<void> logAdvisorQuery({required String topic}) =>
      logEvent('advisor_query', parameters: {'topic': topic});

  /// Event 8: Sync triggered
  Future<void> logSyncTriggered({required String triggerType}) =>
      logEvent('sync_triggered', parameters: {'trigger_type': triggerType});
}
