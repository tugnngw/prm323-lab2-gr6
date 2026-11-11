import 'dart:async';

import '../models/app_state.dart';
import '../models/task_model.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'base_viewmodel.dart';

import 'package:flutter/foundation.dart';

class TasksViewModel extends BaseViewModel<List<TaskModel>> {
  TasksViewModel({
    this.authService,
    this.firestoreService,
    this.analyticsService,
  }) {
    loadData();
    // Logout/login must never leave the previous user's tasks on screen:
    // rebuild the list from the new identity (Lab 3 §5.2 "logout clears local
    // state"). loadData() with a null uid yields the honest empty state.
    // Guarded on uid change so a stream replay of the same identity cannot
    // race a concurrent add/update and clobber the list.
    _authSub = authService?.authStateChanges.listen((_) {
      if (currentUserId != _loadedUid) {
        _filter = "all";
        clearLastError();
        loadData();
      }
    });
  }

  final AuthService? authService;
  final FirestoreService? firestoreService;
  final AnalyticsService? analyticsService;
  StreamSubscription<bool>? _authSub;
  int _loadVersion = 0;
  String? _loadedUid;

  /// Authenticated UID, or null when no identity is available. Used for all
  /// user-owned reads/writes; never falls back to a persona ID or constant.
  String? get currentUserId {
    final uid = authService?.currentUserId;
    return (uid == null || uid.isEmpty) ? null : uid;
  }

  List<TaskModel> _allTasks = [];
  String _filter = 'all'; // 'all', 'pending', 'completed'

  String get currentFilter => _filter;
  List<TaskModel> get allTasks => List.unmodifiable(_allTasks);

  /// Deadline first, undated last, completed last — so the top of the list is
  /// always the task the student should act on next.
  static int compareByDeadline(TaskModel a, TaskModel b) {
    if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
    final aDue = a.dueDateValue;
    final bDue = b.dueDateValue;
    if (aDue == null && bDue == null) return 0;
    if (aDue == null) return 1;
    if (bDue == null) return -1;
    return aDue.compareTo(bDue);
  }

  List<TaskModel> get filteredTasks {
    final list = switch (_filter) {
      'pending' => _allTasks.where((t) => !t.isCompleted).toList(),
      'completed' => _allTasks.where((t) => t.isCompleted).toList(),
      _ => List<TaskModel>.from(_allTasks),
    };
    list.sort(compareByDeadline);
    return list;
  }

  int get pendingCount => _allTasks.where((t) => !t.isCompleted).length;
  int get completedCount => _allTasks.where((t) => t.isCompleted).length;

  /// Calendar days from today to the task deadline (negative = overdue).
  static int? daysUntilDue(TaskModel task, {DateTime? now}) {
    final due = task.dueDateValue;
    if (due == null) return null;
    final today = now ?? DateTime.now();
    return DateTime(due.year, due.month, due.day)
        .difference(DateTime(today.year, today.month, today.day))
        .inDays;
  }

  static bool isOverdue(TaskModel task, {DateTime? now}) {
    final days = daysUntilDue(task, now: now);
    return !task.isCompleted && days != null && days < 0;
  }

  static bool isDueSoon(TaskModel task, {DateTime? now}) {
    final days = daysUntilDue(task, now: now);
    return !task.isCompleted && days != null && days >= 0 && days <= 3;
  }

  static bool isDueSoonOrOverdue(TaskModel task, {DateTime? now}) =>
      isDueSoon(task, now: now) || isOverdue(task, now: now);

  /// Pending tasks due within three days, soonest first.
  List<TaskModel> get dueSoonTasks {
    final list = _allTasks.where((t) => isDueSoon(t)).toList()
      ..sort(compareByDeadline);
    return list;
  }

  int get dueSoonCount => dueSoonTasks.length;

  /// Short Vietnamese label shown next to each deadline chip.
  static String dueLabel(TaskModel task, {DateTime? now}) {
    if (task.isCompleted) return 'Đã xong';
    final days = daysUntilDue(task, now: now);
    if (days == null) return 'Không có hạn';
    if (days < 0) return 'Quá hạn ${-days} ngày';
    if (days == 0) return 'Hạn hôm nay';
    if (days == 1) return 'Còn 1 ngày';
    return 'Còn $days ngày';
  }

  @override
  Future<void> loadData() async {
    if (isDisposed) return;
    final version = ++_loadVersion;
    final uid = currentUserId;
    setState(const AsyncViewState.loading());

    try {
      final firestore = firestoreService;
      _loadedUid = uid;
      if (firestore == null || uid == null) {
        // No backend / no identity: empty state — never seeded mock tasks.
        _allTasks = [];
        setState(const AsyncViewState.empty());
        return;
      }
      final docs = await firestore.getTasks(uid);
      if (isDisposed || version != _loadVersion || uid != currentUserId) return;
      _allTasks = docs.map(TaskModel.fromMap).toList();

      if (_allTasks.isEmpty) {
        setState(const AsyncViewState.empty());
      } else {
        setState(AsyncViewState.data(filteredTasks));
      }
    } catch (e) {
      if (isDisposed || version != _loadVersion || uid != currentUserId) return;
      setState(
        AsyncViewState.error('Không thể tải danh sách việc cần làm: $e'),
      );
    }
  }

  void setFilter(String filter) {
    _filter = filter;
    setState(AsyncViewState.data(filteredTasks));
  }

  /// Adds a task and persists it. Returns true on success; on failure the
  /// optimistic insert is reverted, [lastError] is set, and false is returned.
  Future<bool> addTask({
    required String title,
    required String courseCode,
    required String dueDate,
    String priority = 'medium',
  }) async {
    final uid = currentUserId;
    if (firestoreService != null && uid == null) {
      setLastError('Bạn chưa đăng nhập — không thể lưu việc cần làm.');
      return false;
    }

    final newTask = TaskModel(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      courseCode: courseCode,
      dueDate: dueDate,
      priority: priority,
    );

    _allTasks.insert(0, newTask);
    setState(AsyncViewState.data(filteredTasks));

    final firestore = firestoreService;
    if (firestore != null) {
      try {
        await firestore.addTask({...newTask.toMap(), 'userId': uid!});
      } catch (e) {
        if (isDisposed || uid != currentUserId) return false;
        _allTasks.removeWhere((t) => t.id == newTask.id);
        setState(AsyncViewState.data(filteredTasks));
        setLastError(
          'Không thể lưu việc cần làm. Kiểm tra kết nối và thử lại.',
        );
        return false;
      }
    }
    if (isDisposed || uid != currentUserId) return false;
    clearLastError();

    analyticsService?.logTaskCreate(category: courseCode);
    return true;
  }

  /// Toggles completion and persists the change. Reverts the toggle and sets
  /// [lastError] if the write fails.
  Future<bool> toggleTask(String taskId) async {
    final task = _allTasks.where((t) => t.id == taskId).firstOrNull;
    if (task == null) {
      if (currentUserId == null) {
        setLastError("Bạn chưa đăng nhập — không thể cập nhật việc cần làm.");
      }
      return false;
    }
    return setTaskCompletion(taskId, !task.isCompleted);
  }

  Future<bool> setTaskCompletion(String taskId, bool completed) async {
    final uid = currentUserId;
    if (firestoreService != null && uid == null) {
      setLastError('Bạn chưa đăng nhập — không thể cập nhật việc cần làm.');
      return false;
    }

    final index = _allTasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return false;

    final task = _allTasks[index];
    final updated = task.copyWith(isCompleted: completed);
    _allTasks[index] = updated;
    setState(AsyncViewState.data(filteredTasks));

    final firestore = firestoreService;
    if (firestore != null) {
      try {
        await firestore.updateTask(taskId, {
          'isCompleted': updated.isCompleted,
          'userId': uid!,
        });
      } catch (e) {
        if (isDisposed || uid != currentUserId) return false;
        final restoreIndex = _allTasks.indexWhere((t) => t.id == taskId);
        if (restoreIndex != -1) _allTasks[restoreIndex] = task;
        setState(AsyncViewState.data(filteredTasks));
        setLastError(
          'Không thể cập nhật việc cần làm. Kiểm tra kết nối và thử lại.',
        );
        return false;
      }
    }
    if (isDisposed || uid != currentUserId) return false;
    clearLastError();

    if (updated.isCompleted) {
      analyticsService?.logTaskComplete(taskId: taskId);
    }
    return true;
  }

  /// Edits title/course/due date and persists. On failure the old values are
  /// restored, [lastError] is set, and false is returned.
  Future<bool> editTask(
    String taskId, {
    required String title,
    required String courseCode,
    required String dueDate,
  }) async {
    final uid = currentUserId;
    if (firestoreService != null && uid == null) {
      setLastError('Bạn chưa đăng nhập — không thể sửa việc cần làm.');
      return false;
    }

    final index = _allTasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return false;
    final oldTask = _allTasks[index];
    final updated = oldTask.copyWith(
      title: title,
      courseCode: courseCode,
      dueDate: dueDate,
    );
    _allTasks[index] = updated;
    setState(AsyncViewState.data(filteredTasks));

    final firestore = firestoreService;
    if (firestore != null) {
      try {
        await firestore.updateTask(taskId, {
          'title': updated.title,
          'courseCode': updated.courseCode,
          'dueDate': updated.dueDate,
          'userId': uid!,
        });
      } catch (e) {
        if (isDisposed || uid != currentUserId) return false;
        // T03-M11C temporary capture block removed: root cause was the
        // legacy task ID mismatch fixed in T03-M11D/M11E (canonical doc IDs).
        debugPrint('[ViewModel] editTask error: $e');
        final restoreIndex = _allTasks.indexWhere((t) => t.id == taskId);
        if (restoreIndex != -1) _allTasks[restoreIndex] = oldTask;
        setState(AsyncViewState.data(filteredTasks));
        setLastError(
          'Không thể sửa việc cần làm. Kiểm tra kết nối và thử lại.',
        );
        return false;
      }
    }
    if (isDisposed || uid != currentUserId) return false;
    clearLastError();
    return true;
  }

  /// Deletes a task through the service. On failure the item is restored to
  /// the list, [lastError] is set, and false is returned so the UI never
  /// reports a delete that did not happen.
  Future<bool> deleteTask(String taskId) async {
    final uid = currentUserId;
    if (firestoreService != null && uid == null) {
      setLastError('Bạn chưa đăng nhập — không thể xóa việc cần làm.');
      return false;
    }

    final index = _allTasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return false;
    final removed = _allTasks[index];
    _allTasks.removeAt(index);
    setState(AsyncViewState.data(filteredTasks));

    final firestore = firestoreService;
    if (firestore != null) {
      try {
        await firestore.deleteTask(uid!, taskId);
      } catch (e) {
        if (isDisposed || uid != currentUserId) return false;
        if (!_allTasks.any((t) => t.id == taskId)) {
          _allTasks.insert(index.clamp(0, _allTasks.length), removed);
        }
        setState(AsyncViewState.data(filteredTasks));
        setLastError(
          'Không thể xóa việc cần làm. Kiểm tra kết nối và thử lại.',
        );
        return false;
      }
    }
    if (isDisposed || uid != currentUserId) return false;
    clearLastError();
    return true;
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }
}
