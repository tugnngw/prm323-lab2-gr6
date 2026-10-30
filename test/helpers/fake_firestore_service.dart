import 'package:prm323_lab3/services/firestore_service.dart';

/// Test double implementing [FirestoreService] for hermetic unit and widget testing.
///
/// Records all calls with their user IDs and supports simulated failures.
class FakeFirestoreService implements FirestoreService {
  final List<Map<String, dynamic>> tasks = [];
  final List<Map<String, dynamic>> notes = [];
  final List<String> deletedTaskCalls = [];
  final List<String> deletedNoteCalls = [];

  bool shouldFailTaskAdd = false;
  bool shouldFailTaskUpdate = false;
  bool shouldFailTaskDelete = false;
  bool shouldFailNoteSave = false;
  bool shouldFailNoteDelete = false;

  @override
  Future<List<Map<String, dynamic>>> getCourses(String userId) async => [];

  @override
  Future<Map<String, dynamic>?> getCourse(String courseId) async => null;

  @override
  Future<List<Map<String, dynamic>>> getTasks(String userId) async =>
      List.from(tasks);

  @override
  Future<void> addTask(Map<String, dynamic> task) async {
    if (shouldFailTaskAdd) {
      throw Exception('Simulated remote addTask network failure');
    }
    tasks.add(Map<String, dynamic>.from(task));
  }

  @override
  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    if (shouldFailTaskUpdate) {
      throw Exception('Simulated remote updateTask failure');
    }
    final idx = tasks.indexWhere((t) => t['id'] == taskId);
    if (idx != -1) {
      tasks[idx].addAll(data);
    }
  }

  @override
  Future<void> deleteTask(String userId, String taskId) async {
    if (shouldFailTaskDelete) {
      throw Exception('Simulated remote deleteTask failure');
    }
    deletedTaskCalls.add('$userId:$taskId');
    tasks.removeWhere((t) => t['id'] == taskId);
  }

  @override
  Future<List<Map<String, dynamic>>> getNotes(String userId) async =>
      List.from(notes);

  @override
  Future<void> saveNote(Map<String, dynamic> note) async {
    if (shouldFailNoteSave) {
      throw Exception('Simulated remote saveNote failure');
    }
    final idx = notes.indexWhere((n) => n['id'] == note['id']);
    if (idx != -1) {
      notes[idx] = Map<String, dynamic>.from(note);
    } else {
      notes.add(Map<String, dynamic>.from(note));
    }
  }

  @override
  Future<void> deleteNote(String userId, String noteId) async {
    if (shouldFailNoteDelete) {
      throw Exception('Simulated remote deleteNote failure');
    }
    deletedNoteCalls.add('$userId:$noteId');
    notes.removeWhere((n) => n['id'] == noteId);
  }
}
