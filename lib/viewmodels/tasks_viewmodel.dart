import '../models/app_state.dart';
import '../models/task_model.dart';
import '../services/analytics_service.dart';
import '../services/firebase_analytics_service.dart';
import '../services/firestore_service.dart';
import 'base_viewmodel.dart';

class TasksViewModel extends BaseViewModel<List<TaskModel>> {
  TasksViewModel({
    this.firestoreService,
    this.analyticsService,
  }) {
    loadData();
  }

  final FirestoreService? firestoreService;
  final AnalyticsService? analyticsService;

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
      if (firestore != null) {
        final docs = await firestore.getTasks('user_p02');
        if (docs.isNotEmpty) {
          _allTasks = docs.map(TaskModel.fromMap).toList();
        } else {
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

  Future<void> addTask({
    required String title,
    required String courseCode,
    required String dueDate,
    String priority = 'medium',
  }) async {
    final newTask = TaskModel(
      id: 'task_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      courseCode: courseCode,
      dueDate: dueDate,
      priority: priority,
    );

    _allTasks.insert(0, newTask);
    setState(AsyncViewState.data(filteredTasks));

    // Async save to firestore
    final firestore = firestoreService;
    if (firestore != null) {
      try {
        await firestore.addTask({
          ...newTask.toMap(),
          'userId': 'user_p02',
        });
      } catch (_) {}
    }

    final analytics = analyticsService;
    if (analytics is FirebaseAnalyticsService) {
      analytics.logTaskCreate(category: courseCode);
    }
  }

  Future<void> toggleTask(String taskId) async {
    final index = _allTasks.indexWhere((t) => t.id == taskId);
    if (index == -1) return;

    final task = _allTasks[index];
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    _allTasks[index] = updated;
    setState(AsyncViewState.data(filteredTasks));

    final firestore = firestoreService;
    if (firestore != null) {
      try {
        await firestore.updateTask(taskId, {
          'isCompleted': updated.isCompleted,
          'userId': 'user_p02',
        });
      } catch (_) {}
    }

    final analytics = analyticsService;
    if (updated.isCompleted && analytics is FirebaseAnalyticsService) {
      analytics.logTaskComplete(taskId: taskId);
    }
  }

  Future<void> deleteTask(String taskId) async {
    _allTasks.removeWhere((t) => t.id == taskId);
    setState(AsyncViewState.data(filteredTasks));

    final firestore = firestoreService;
    if (firestore != null) {
      try {
        await firestore.deleteTask(taskId);
      } catch (_) {}
    }
  }
}
