import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../services/local_notification_service.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/tasks_viewmodel.dart';

/// Feeds the student's tasks into [LocalNotificationService] whenever they
/// change, and routes notification taps to the right screen.
///
/// A null service (hermetic widget tests, unsupported platforms) makes this a
/// plain pass-through: nothing touches the OS notification plugin.
class ReminderSync extends StatefulWidget {
  const ReminderSync({super.key, required this.child});

  final Widget child;

  @override
  State<ReminderSync> createState() => _ReminderSyncState();
}

class _ReminderSyncState extends State<ReminderSync> {
  String? _signature;
  Timer? _debounce;
  bool _frameScheduled = false;
  bool _clearedForSignedOut = false;
  LocalNotificationService? _boundService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final service = context.read<LocalNotificationService?>();
    if (identical(service, _boundService)) return;
    _boundService?.pendingPayload.removeListener(_openFromPayload);
    _boundService = service;
    service?.pendingPayload.addListener(_openFromPayload);
    if (service?.pendingPayload.value != null) _openFromPayload();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _boundService?.pendingPayload.removeListener(_openFromPayload);
    super.dispose();
  }

  void _openFromPayload() {
    final service = _boundService;
    final payload = service?.pendingPayload.value;
    if (payload == null || payload.isEmpty) return;
    service!.pendingPayload.value = null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = context.read<AuthViewModel>();
      if (!auth.isAuthenticated) return;
      if (payload == 'tasks') {
        Navigator.of(context).pushNamed('/tasks');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<LocalNotificationService?>();
    final auth = context.watch<AuthViewModel>();
    final tasks = context.watch<TasksViewModel>();

    final uid = auth.currentUserId;
    if (service == null) return widget.child;

    if (uid == null || uid.isEmpty) {
      // Signed out (or app opened signed out): never leave the previous
      // student's reminders on the device.
      if (!_clearedForSignedOut && !_frameScheduled) {
        _frameScheduled = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _frameScheduled = false;
          if (!mounted || _clearedForSignedOut) return;
          _clearedForSignedOut = true;
          _signature = null;
          _debounce?.cancel();
          service.clearAll();
        });
      }
      return widget.child;
    }
    _clearedForSignedOut = false;

    final allTasks = tasks.allTasks;
    final signature = _signatureOf(uid, allTasks);
    if (signature != _signature && !_frameScheduled) {
      _frameScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _frameScheduled = false;
        if (!mounted || _signature == signature) return;
        _signature = signature;
        _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 800), () {
          service.syncReminders(tasks: allTasks);
        });
      });
    }

    return widget.child;
  }

  /// Everything that can change a scheduled reminder. Timestamps are excluded
  /// on purpose: only edits to deadlines should reschedule.
  static String _signatureOf(String uid, List<TaskModel> tasks) {
    final buffer = StringBuffer(uid);
    for (final task in tasks) {
      buffer.write(
        '|t:${task.id}:${task.isCompleted ? 1 : 0}:${task.dueDate}:'
        '${task.title}',
      );
    }
    return buffer.toString();
  }
}
