import '../models/app_state.dart';
import '../models/task_model.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'base_viewmodel.dart';

class TasksViewModel extends BaseViewModel<List<TaskModel>> {
  TasksViewModel({
    this.authService,
    this.firestoreService,
    this.analyticsService,
  }) {
    loadData();
  }

  final AuthService? authService;
  final FirestoreService? firestoreService;
  final AnalyticsService? analyticsService;

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

  List<TaskModel> get filteredTasks {
    switch (_filter) {
      case 'pending':
        return _allTasks.where((t) => !t.isCompleted).toList();
      case 'completed':
        return _allTasks.where((t) => t.isCompleted).toList();
      default:
        return List.unmodifiable(_allTasks);
    }
  }

  int get pendingCount => _allTasks.where((t) => !t.isCompleted).length;
  int get completedCount => _allTasks.where((t) => t.isCompleted).length;

  @override
  Future<void> loadData() async {
    setState(const AsyncViewState.loading());

    try {
      final firestore = firestoreService;
      final uid = currentUserId;
      if (firestore == null || uid == null) {
        // No backend / no identity: empty state — never seeded mock tasks.
        _allTasks = [];
        setState(const AsyncViewState.empty());
        return;
      }
      final docs = await firestore.getTasks(uid);
      _allTasks = docs.map(TaskModel.fromMap).toList();

      if (_allTasks.isEmpty) {
        setState(const AsyncViewState.empty());
      } else {
        setState(AsyncViewState.data(filteredTasks));
      }
    } catch (e) {
      setState(AsyncViewState.error('Không thể tải danh sách việc cần làm: $e'));
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
        await firestore.addTask({
          ...newTask.toMap(),
          'userId': uid!,
        });
      } catch (e) {
        _allTasks.removeWhere((t) => t.id == newTask.id);
        setState(AsyncViewState.data(filteredTasks));
        setLastError('Không thể lưu việc cần làm. Kiểm tra kết nối và thử lại.');
        return false;
      }
    }
    clearLastError();

    analyticsService?.logTaskCreate(category: courseCode);
    return true;
  }

  /// Toggles completion and persists the change. Reverts the toggle and sets
  /// [lastError] if the write fails.
  Future<bool> toggleTask(String taskId) async {
    final uid = currentUserId;
    if (firestoreService != null && uid == null) {
      setLastError('Bạn chưa đăng nhập — không thể cập nhật việc cần làm.');
      return false;
    }

    final index = _allTasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return false;

    final task = _allTasks[index];
    final updated = task.copyWith(isCompleted: !task.isCompleted);
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
        _allTasks[index] = task;
        setState(AsyncViewState.data(filteredTasks));
        setLastError('Không thể cập nhật việc cần làm. Kiểm tra kết nối và thử lại.');
        return false;
      }
    }
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
        _allTasks[index] = oldTask;
        setState(AsyncViewState.data(filteredTasks));
        setLastError('Không thể sửa việc cần làm. Kiểm tra kết nối và thử lại.');
        return false;
      }
    }
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
        _allTasks.insert(index, removed);
        setState(AsyncViewState.data(filteredTasks));
        setLastError('Không thể xóa việc cần làm. Kiểm tra kết nối và thử lại.');
        return false;
      }
    }
    clearLastError();
    return true;
  }
}
