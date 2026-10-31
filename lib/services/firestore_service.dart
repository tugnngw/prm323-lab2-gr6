/// Interface for Firestore data operations.
///
/// Will be implemented with Cloud Firestore in the Integrate phase.
abstract class FirestoreService {
  // ── Courses / Roadmap ──
  Future<List<Map<String, dynamic>>> getCourses(String userId);
  Future<Map<String, dynamic>?> getCourse(String courseId);

  /// Owner's profile document (`users/{userId}`) — carries the passed-course
  /// transcript used for prerequisite checks. Null when not provisioned yet;
  /// callers must treat a missing profile as "no passed courses", never as
  /// seeded demo data.
  Future<Map<String, dynamic>?> getUserProfile(String userId);

  // ── Tasks ──
  Future<List<Map<String, dynamic>>> getTasks(String userId);
  Future<void> addTask(Map<String, dynamic> task);
  Future<void> updateTask(String taskId, Map<String, dynamic> data);
  /// Deletes [taskId] from [userId]'s subcollection. Fails if the item is
  /// missing or the remote write is rejected.
  Future<void> deleteTask(String userId, String taskId);

  // ── Notes ──
  Future<List<Map<String, dynamic>>> getNotes(String userId);
  Future<void> saveNote(Map<String, dynamic> note);

  /// Deletes [noteId] from [userId]'s subcollection. Fails if the item is
  /// missing or the remote write is rejected.
  Future<void> deleteNote(String userId, String noteId);

  // ── Report metadata (PDF export) ──
  /// Stores a generated study-report's metadata under
  /// `users/{userId}/sync/{reportId}` so exports are auditable.
  Future<void> saveReportMetadata(
      String userId, Map<String, dynamic> metadata);

  // ── Notification Center ──
  Future<List<Map<String, dynamic>>> getNotifications(String userId);
  Future<void> saveNotification(String userId, Map<String, dynamic> data);
  Future<void> markNotificationRead(String userId, String notificationId);

  // ── FCM device tokens ──
  Future<void> registerToken(String userId, String token);
}
