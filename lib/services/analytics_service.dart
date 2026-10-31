import 'package:flutter/widgets.dart' show NavigatorObserver;

/// Interface for analytics tracking.
///
/// Tracks the Lab 3 required ≥7 custom events (9 below). Call sites must use
/// THIS interface — never `is FirebaseAnalyticsService` type checks — so a
/// test double or decorator cannot silently drop events (audit S-07).
///
/// The 9 named events are concrete helpers that funnel into [logEvent], so
/// every implementation (including test doubles) records them uniformly.
abstract class AnalyticsService {
  Future<void> logEvent(String name, {Map<String, Object>? parameters});
  Future<void> setUserId(String id);
  Future<void> setCurrentScreen(String screenName);

  /// Observer(s) to attach to `MaterialApp.navigatorObservers` for screen
  /// tracking. Empty when the backend cannot provide one.
  List<NavigatorObserver> get navigatorObservers;

  // ──────────────────────── 9 Predefined Lab 3 Events ────────────────────────

  /// Event 1: Login success
  Future<void> logLoginSuccess({required String method}) =>
      logEvent('login_success', parameters: {'method': method});

  /// Event 2: Course detail opened (fires once per open, not per rebuild)
  Future<void> logCourseView({required String courseId, required String code}) =>
      logEvent('course_view',
          parameters: {'course_id': courseId, 'code': code});

  /// Event 3: Prerequisite check (fires on explicit check, not from build)
  Future<void> logPrerequisiteCheck({
    required String courseId,
    required bool isEligible,
  }) =>
      logEvent('prerequisite_check',
          parameters: {'course_id': courseId, 'is_eligible': isEligible ? 1 : 0});

  /// Event 4: Curriculum search (fires once per committed query)
  Future<void> logSearchCourse({required String query}) =>
      logEvent('search_course', parameters: {'query_length': query.length});

  /// Event 5: Task create
  Future<void> logTaskCreate({required String category}) =>
      logEvent('task_create', parameters: {'category': category});

  /// Event 6: Task complete
  Future<void> logTaskComplete({required String taskId}) =>
      logEvent('task_complete', parameters: {'task_id': taskId});

  /// Event 7: Note create
  Future<void> logNoteCreate({required int contentLength}) =>
      logEvent('note_create', parameters: {'content_length': contentLength});

  /// Event 8: Advisor query
  Future<void> logAdvisorQuery({required String topic}) =>
      logEvent('advisor_query', parameters: {'topic': topic});

  /// Event 9: Sync triggered
  Future<void> logSyncTriggered({required String triggerType}) =>
      logEvent('sync_triggered', parameters: {'trigger_type': triggerType});

  /// Event 10: PDF report exported (guide v5 §6.5).
  /// [status] is 'success' or 'failed'; sizes/timings are integers only.
  Future<void> logExportReport({
    required String status,
    required int fileSizeKb,
    required int durationMs,
  }) =>
      logEvent('export_report', parameters: {
        'status': status,
        'file_size_kb': fileSizeKb,
        'duration_ms': durationMs,
      });

  /// Event 11: Push notification handled (Lab 3 T12).
  /// [action] is 'foreground' | 'tap'; carries no message contents (PII rule).
  Future<void> logNotificationReceived({
    required String type,
    required String action,
  }) =>
      logEvent('notification_received',
          parameters: {'type': type, 'action': action});
}
