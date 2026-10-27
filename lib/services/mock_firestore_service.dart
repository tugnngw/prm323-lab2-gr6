import 'firestore_service.dart';

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

  final List<Map<String, dynamic>> _tasks = [];
  final List<Map<String, dynamic>> _notes = [];

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
  Future<void> deleteTask(String taskId) async {
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
  Future<void> deleteNote(String noteId) async {
    _notes.removeWhere((n) => n['id'] == noteId);
  }
}
