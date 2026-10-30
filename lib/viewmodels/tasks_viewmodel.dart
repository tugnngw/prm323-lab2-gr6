import '../models/app_state.dart';
import '../models/task_model.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/firebase_analytics_service.dart';
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

  static final List<TaskModel> _defaultTasks = [
    const TaskModel(
      id: 'task_01',
      title: 'Hoàn thành Lab 3 PRM323 (Firebase & MVVM)',
      courseCode: 'PRM323',
      dueDate: '15/12/2024',
      isCompleted: false,
      priority: 'high',
    ),
    const TaskModel(
      id: 'task_02',
      title: 'Đọc Chapter 5 Kiến trúc phần mềm SWP391',
      courseCode: 'SWP391',
      dueDate: '12/12/2024',
      isCompleted: false,
      priority: 'medium',
    ),
    const TaskModel(
      id: 'task_03',
      title: 'Nộp Sprint 2 Retrospective SWP391',
      courseCode: 'SWP391',
      dueDate: '18/12/2024',
      isCompleted: false,
      priority: 'medium',
    ),
    const TaskModel(
      id: 'task_04',
      title: 'Nộp bài Lab 2 PRM323 (Figma Prototype)',
      courseCode: 'PRM323',
      dueDate: '05/11/2024',
      isCompleted: true,
      priority: 'high',
    ),
  ];

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
      if (firestore != null) {
        if (uid != null) {
          final docs = await firestore.getTasks(uid);
          if (docs.isNotEmpty) {
            _allTasks = docs.map(TaskModel.fromMap).toList();
          } else {
            _allTasks = List.from(_defaultTasks);
          }
        } else {
          // Demo/mock mode: no authenticated identity — keep seeded defaults
          // instead of fabricating one.
          _allTasks = List.from(_defaultTasks);
        }
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        _allTasks = List.from(_defaultTasks);
      }

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

    final analytics = analyticsService;
    if (analytics is FirebaseAnalyticsService) {
      analytics.logTaskCreate(category: courseCode);
    }
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

    final analytics = analyticsService;
    if (updated.isCompleted && analytics is FirebaseAnalyticsService) {
      analytics.logTaskComplete(taskId: taskId);
    }
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
