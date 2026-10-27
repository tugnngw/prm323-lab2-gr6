/// Interface for Firestore data operations.
///
/// Will be implemented with Cloud Firestore in the Integrate phase.
abstract class FirestoreService {
  // ── Courses / Roadmap ──
  Future<List<Map<String, dynamic>>> getCourses(String userId);
  Future<Map<String, dynamic>?> getCourse(String courseId);

  // ── Tasks ──
  Future<List<Map<String, dynamic>>> getTasks(String userId);
  Future<void> addTask(Map<String, dynamic> task);
  Future<void> updateTask(String taskId, Map<String, dynamic> data);
  Future<void> deleteTask(String taskId);

  // ── Notes ──
  Future<List<Map<String, dynamic>>> getNotes(String userId);
  Future<void> saveNote(Map<String, dynamic> note);
  Future<void> deleteNote(String noteId);
}
