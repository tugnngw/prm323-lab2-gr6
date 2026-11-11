import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/task_model.dart';

/// OS-level reminders for task deadlines.
///
/// Only data the student entered themselves is scheduled: a task needs a
/// parseable due date. Notification ids are assigned deterministically per
/// sync, and every sync starts by cancelling the previous schedule, so
/// completing or editing a task cannot leave a stale reminder behind.
class LocalNotificationService {
  LocalNotificationService._(this._plugin);

  static const _channelId = 'study_reminders';
  static const _channelName = 'Nhắc deadline việc cần làm';
  static const _channelDescription =
      'Nhắc trước hạn 3 ngày và nhắc đúng ngày đến hạn.';

  static const _deadlineHour = 9;
  static const _maxTaskReminders = 40;

  static const _details = NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    ),
    iOS: DarwinNotificationDetails(),
    macOS: DarwinNotificationDetails(),
  );

  final FlutterLocalNotificationsPlugin _plugin;

  /// Payload of the last notification the student tapped. Consumed by the
  /// navigator once the app is running; only `tasks` is emitted today.
  final ValueNotifier<String?> pendingPayload = ValueNotifier<String?>(null);

  bool _permissionRequested = false;

  static Future<LocalNotificationService?> initialize() async {
    if (kIsWeb) return null;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Ho_Chi_Minh'));

      final plugin = FlutterLocalNotificationsPlugin();
      LocalNotificationService? service;
      final initialized = await plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
          macOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
        onDidReceiveNotificationResponse: (response) {
          final payload = response.payload;
          if (payload != null && payload.isNotEmpty) {
            service?.pendingPayload.value = payload;
          }
        },
      );
      if (initialized == false) return null;

      service = LocalNotificationService._(plugin);
      await service._createChannel();

      final launch = await plugin.getNotificationAppLaunchDetails();
      final payload = launch?.notificationResponse?.payload;
      if (launch?.didNotificationLaunchApp == true &&
          payload != null &&
          payload.isNotEmpty) {
        service.pendingPayload.value = payload;
      }
      return service;
    } catch (e) {
      debugPrint('[LocalNotifications] init failed: $e');
      return null;
    }
  }

  Future<void> _createChannel() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.createNotificationChannel(
      const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ),
    );
  }

  /// Asks for the OS notification permission once per app session. Returns
  /// false when the user declined or the platform refused.
  Future<bool> ensurePermission() async {
    if (_permissionRequested) return true;
    _permissionRequested = true;
    try {
      final android = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      final granted = await android?.requestNotificationsPermission();
      final ios = _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >();
      await ios?.requestPermissions(alert: true, badge: true, sound: true);
      return granted ?? true;
    } catch (e) {
      debugPrint('[LocalNotifications] permission request failed: $e');
      return false;
    }
  }

  /// Replaces every app-scheduled reminder with the current tasks.
  Future<void> syncReminders({required List<TaskModel> tasks}) async {
    if (tasks.isEmpty) {
      await _safeCancelAll();
      return;
    }
    await ensurePermission();
    final now = tz.TZDateTime.now(tz.local);
    await _safeCancelAll();

    var id = 0;
    var taskReminders = 0;
    for (final task in tasks) {
      if (task.isCompleted || taskReminders >= _maxTaskReminders) continue;
      final due = task.dueDateValue;
      if (due == null) continue;
      final courseLine = task.courseCode.isEmpty ? '' : '${task.courseCode} · ';
      for (final daysBefore in const [3, 0]) {
        if (taskReminders >= _maxTaskReminders) break;
        final day = DateTime(
          due.year,
          due.month,
          due.day,
        ).subtract(Duration(days: daysBefore));
        final when = tz.TZDateTime(
          tz.local,
          day.year,
          day.month,
          day.day,
          _deadlineHour,
        );
        if (!when.isAfter(now)) continue;
        await _schedule(
          id: 5000 + id++,
          when: when,
          title: daysBefore == 0
              ? 'Hôm nay đến hạn: ${task.title}'
              : 'Sắp đến hạn: ${task.title}',
          body: daysBefore == 0
              ? '${courseLine}Hạn ${task.dueDate}. Đánh dấu hoàn thành sau khi xong.'
              : '${courseLine}Còn $daysBefore ngày (hạn ${task.dueDate}).',
          payload: 'tasks',
        );
        taskReminders++;
      }
    }
  }

  Future<void> _safeCancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('[LocalNotifications] cancelAll failed: $e');
    }
  }

  /// Drops every reminder, e.g. after sign-out so the next user never sees the
  /// previous student's deadline alerts.
  Future<void> clearAll() => _safeCancelAll();

  Future<void> _schedule({
    required int id,
    required tz.TZDateTime when,
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id: id,
        scheduledDate: when,
        notificationDetails: _details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
        payload: payload,
      );
    } catch (e) {
      debugPrint('[LocalNotifications] schedule $id failed: $e');
    }
  }
}
