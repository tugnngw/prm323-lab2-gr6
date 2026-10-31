import 'package:prm323_lab3/services/firestore_service.dart';

/// In-memory Mock implementation of [FirestoreService] for testing.
class MockFirestoreService implements FirestoreService {
  final List<Map<String, dynamic>> _courses = [
    {
      'id': 'PRM323',
      'code': 'PRM323',
      'name': 'Lập trình Di động',
      'credits': 3,
      'semester': 5,
      'major': 'SE',
    },
    {
      'id': 'SWP391',
      'code': 'SWP391',
      'name': 'Dự án Phát triển PM',
      'credits': 5,
      'semester': 5,
      'major': 'SE',
    },
  ];

  final List<Map<String, dynamic>> _tasks = [
    {
      'id': 'task_01',
      'title': 'Hoàn thành Lab 3 PRM323 (Firebase & MVVM)',
      'courseCode': 'PRM323',
      'dueDate': '15/12/2024',
      'isCompleted': false,
      'priority': 'high',
    },
  ];
  final List<Map<String, dynamic>> _notes = [
    {
      'id': 'note_01',
      'title': 'Kiến trúc MVVM & Design Tokens PRM323',
      'courseCode': 'PRM323',
      'content':
          '1. View chỉ phụ trách giao diện và quan sát state qua Provider.\n'
          '2. ViewModel quản lý logic và gọi Service.',
      'updatedAt': 'Hôm nay, 14:30',
      'tags': ['PRM323', 'Flutter', 'MVVM'],
    },
  ];

  @override
  Future<List<Map<String, dynamic>>> getCourses(String userId) async =>
      List.from(_courses);

  @override
  Future<Map<String, dynamic>?> getCourse(String courseId) async =>
      _courses.cast<Map<String, dynamic>?>().firstWhere(
            (c) => c?['id'] == courseId,
            orElse: () => null,
          );

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async => {
        'passedCourses': [
          'PRO192',
          'CSD201',
          'MAD101',
          'OSG202',
          'NWC203c',
          'SSG104',
        ],
      };

  @override
  Future<List<Map<String, dynamic>>> getTasks(String userId) async =>
      List.from(_tasks);

  @override
  Future<void> addTask(Map<String, dynamic> task) async {
    _tasks.add({'id': 'task_${DateTime.now().millisecondsSinceEpoch}', ...task});
  }

  @override
  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    final idx = _tasks.indexWhere((t) => t['id'] == taskId);
    if (idx != -1) {
      _tasks[idx].addAll(data);
    }
  }

  @override
  Future<void> deleteTask(String userId, String taskId) async {
    _tasks.removeWhere((t) => t['id'] == taskId);
  }

  @override
  Future<List<Map<String, dynamic>>> getNotes(String userId) async =>
      List.from(_notes);

  @override
  Future<void> saveNote(Map<String, dynamic> note) async {
    final idx = _notes.indexWhere((n) => n['id'] == note['id']);
    if (idx != -1) {
      _notes[idx] = note;
    } else {
      _notes.add({
        'id': note['id'] ?? 'note_${DateTime.now().millisecondsSinceEpoch}',
        ...note,
      });
    }
  }

  @override
  Future<void> deleteNote(String userId, String noteId) async {
    _notes.removeWhere((n) => n['id'] == noteId);
  }

  @override
  Future<void> saveReportMetadata(
      String userId, Map<String, dynamic> metadata) async {}

  @override
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async =>
      const [];

  @override
  Future<void> saveNotification(String userId, Map<String, dynamic> data) async {}

  @override
  Future<void> markNotificationRead(
      String userId, String notificationId) async {}

  @override
  Future<void> registerToken(String userId, String token) async {}
}
