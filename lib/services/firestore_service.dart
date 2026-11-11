/// Interface for Firestore data operations.
///
/// Will be implemented with Cloud Firestore in the Integrate phase.
abstract class FirestoreService {
  // ── Courses / Roadmap ──
  Future<List<Map<String, dynamic>>> getCourses(String userId);

  /// Only the courses belonging to [majorCode]. Students download one
  /// curriculum, not the whole catalog.
  Future<List<Map<String, dynamic>>> getCoursesForMajor(String majorCode);

  Future<Map<String, dynamic>?> getCourse(String courseId);
  Future<List<Map<String, dynamic>>> getMajors() async => [];

  /// Owner's profile document (`users/{userId}`) — carries the passed-course
  /// transcript used for prerequisite checks. Null when not provisioned yet;
  /// callers must treat a missing profile as "no passed courses", never as
  /// seeded demo data.
  Future<Map<String, dynamic>?> getUserProfile(String userId);

  /// Live `users/{uid}.role` for the mobile role gate. Emits null while the
  /// profile document does not exist yet.
  Stream<String?> watchUserRole(String userId);

  /// Merge user-entered transcript without replacing other profile fields.
  Future<void> saveAcademicProfile(String userId, Map<String, dynamic> data);

  /// Replaces the whole `componentScores` field. Unlike [saveAcademicProfile]
  /// this must not deep-merge: clearing a score has to remove the stored key.
  Future<void> saveComponentScores(
    String userId,
    Map<String, dynamic> componentScores,
  );

  // ── Per-student course progress ──
  /// `users/{userId}/courseProgress/*` — slot ticks, "course done" flag and
  /// the lecturer the student recorded for themselves.
  Future<List<Map<String, dynamic>>> getCourseProgress(String userId);
  Future<void> saveCourseProgress(
    String userId,
    String courseDocId,
    Map<String, dynamic> data,
  );

  // ── Announcements (server-wide) ──
  /// School announcements written by staff. They are merged into the in-app
  /// Notification Center because students cannot read other users' inboxes.
  Future<List<Map<String, dynamic>>> getAnnouncements();
  Stream<List<Map<String, dynamic>>> watchAnnouncements();

  // ── Tasks ──
  Future<List<Map<String, dynamic>>> getTasks(String userId);
  Future<void> addTask(Map<String, dynamic> task);
  Future<void> updateTask(String taskId, Map<String, dynamic> data);

  /// Deletes [taskId] from [userId]'s subcollection. Fails if the item is
  /// missing or the remote write is rejected.
  Future<void> deleteTask(String userId, String taskId);

  // ── Notes ──
  Future<List<Map<String, dynamic>>> getNotes(String userId);
  Future<void> saveNote(
    Map<String, dynamic> note, {
    (String?, String?)? attachmentBefore,
    bool preserveAttachment = false,
  });

  /// Deletes [noteId] from [userId]'s subcollection. Fails if the item is
  /// missing or the remote write is rejected.
  Future<void> deleteNote(String userId, String noteId);

  // ── Report metadata (PDF export) ──
  /// Stores a generated study-report's metadata under
  /// `users/{userId}/sync/{reportId}` so exports are auditable.
  Future<void> saveReportMetadata(String userId, Map<String, dynamic> metadata);
  Future<List<Map<String, dynamic>>> getRecentReportMetadata(String userId);

  // ── Notification Center ──
  Future<List<Map<String, dynamic>>> getNotifications(String userId);

  /// Live inbox: a staff review decision writes into this subcollection, so
  /// the student sees the approval message without pulling to refresh.
  Stream<List<Map<String, dynamic>>> watchNotifications(String userId);
  Future<void> saveNotification(
    String userId,
    Map<String, dynamic> data, {
    String? notificationId,
  });
  Future<void> markNotificationRead(String userId, String notificationId);

  // ── FCM device tokens ──
  Future<void> registerToken(String userId, String token);
}
