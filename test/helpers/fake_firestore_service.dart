import 'package:prm393_final_gr6/services/firestore_service.dart';

/// Test double implementing [FirestoreService] for hermetic unit and widget
/// testing.
///
/// Holds NO production fallbacks — tests seed exactly the data they assert on
/// (via [courses], [tasks], [notes], [userProfile], [reports],
/// [notifications]) and inspect those lists afterwards. Failure flags arm
/// simulated remote errors.
class FakeFirestoreService implements FirestoreService {
  final List<Map<String, dynamic>> majors = [];

  @override
  Future<List<Map<String, dynamic>>> getMajors() async =>
      List.from(majors);

  @override
  Stream<String?> watchUserRole(String userId) => Stream.value(role);

  String? role;

  @override
  Future<List<Map<String, dynamic>>> getRecentReportMetadata(
    String userId,
  ) async => reports.reversed
      .where((report) => report['userId'] == userId)
      .take(30)
      .toList();
  final List<Map<String, dynamic>> courses = [];
  final List<Map<String, dynamic>> courseProgress = [];
  final List<Map<String, dynamic>> announcements = [];
  final List<Map<String, dynamic>> tasks = [];
  final List<Map<String, dynamic>> notes = [];
  final List<Map<String, dynamic>> reports = [];
  final List<Map<String, dynamic>> notifications = [];
  final List<String> registeredTokens = [];

  final List<String> deletedTaskCalls = [];
  final List<String> deletedNoteCalls = [];

  /// Returned by [getUserProfile]; null means "profile not provisioned".
  Map<String, dynamic>? userProfile;

  bool shouldFailTaskAdd = false;

  @override
  Future<void> saveAcademicProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    userProfile = {...?userProfile, ...data};
  }

  @override
  Future<void> saveComponentScores(
    String userId,
    Map<String, dynamic> componentScores,
  ) async {
    userProfile = {...?userProfile, 'componentScores': componentScores};
  }

  bool shouldFailTaskUpdate = false;
  bool shouldFailTaskDelete = false;
  bool shouldFailNoteSave = false;
  bool shouldFailNoteDelete = false;
  bool shouldFailReportSave = false;
  bool shouldFailCourseLoad = false;
  bool shouldFailTaskLoad = false;
  bool shouldFailNoteLoad = false;

  @override
  Future<List<Map<String, dynamic>>> getCourses(String userId) async {
    if (shouldFailCourseLoad) {
      throw Exception('Simulated course read failure');
    }
    return List.from(courses);
  }

  @override
  Future<List<Map<String, dynamic>>> getCoursesForMajor(
    String majorCode,
  ) async {
    if (shouldFailCourseLoad) {
      throw Exception('Simulated course read failure');
    }
    final code = majorCode.trim().toUpperCase();
    if (code.isEmpty) return [];
    return courses
        .where(
          (course) =>
              (course['major'] ?? '').toString().toUpperCase() == code,
        )
        .toList();
  }

  @override
  Future<Map<String, dynamic>?> getCourse(String courseId) async {
    for (final c in courses) {
      if (c['id'] == courseId) return c;
    }
    return null;
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async =>
      userProfile;

  @override
  Future<List<Map<String, dynamic>>> getCourseProgress(String userId) async =>
      List.from(courseProgress);

  @override
  Future<void> saveCourseProgress(
    String userId,
    String courseDocId,
    Map<String, dynamic> data,
  ) async {
    final idx = courseProgress.indexWhere(
      (p) => p['courseDocId'] == courseDocId || p['id'] == courseDocId,
    );
    final item = {
      'courseDocId': courseDocId,
      'id': courseDocId,
      ...?idx == -1 ? null : courseProgress[idx],
      ...data,
    };
    if (idx == -1) {
      courseProgress.add(item);
    } else {
      courseProgress[idx] = item;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getAnnouncements() async =>
      List.from(announcements);

  @override
  Stream<List<Map<String, dynamic>>> watchAnnouncements() =>
      Stream.value(List.from(announcements));

  @override
  Future<List<Map<String, dynamic>>> getTasks(String userId) async {
    if (shouldFailTaskLoad) {
      throw Exception('Simulated task read failure');
    }
    return List.from(tasks);
  }

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
  Future<List<Map<String, dynamic>>> getNotes(String userId) async {
    if (shouldFailNoteLoad) {
      throw Exception('Simulated note read failure');
    }
    return List.from(notes);
  }

  @override
  Future<void> saveNote(
    Map<String, dynamic> note, {
    (String?, String?)? attachmentBefore,
    bool preserveAttachment = false,
  }) async {
    if (shouldFailNoteSave) {
      throw Exception('Simulated remote saveNote failure');
    }
    final idx = notes.indexWhere((n) => n['id'] == note['id']);
    final previous = idx == -1 ? null : notes[idx];
    if (attachmentBefore != null &&
        (previous == null ||
            (previous['attachmentPath'], previous['attachmentUrl']) !=
                attachmentBefore)) {
      throw StateError('Stale attachment');
    }
    final data = Map<String, dynamic>.of(note);
    if (preserveAttachment && previous != null) {
      for (final field in [
        'attachmentPath',
        'attachmentUrl',
        'attachmentName',
      ]) {
        data[field] = previous[field];
      }
    }
    if (idx != -1) {
      notes[idx] = data;
    } else {
      notes.add(data);
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

  @override
  Future<void> saveReportMetadata(
    String userId,
    Map<String, dynamic> metadata,
  ) async {
    if (shouldFailReportSave) {
      throw Exception('Simulated remote saveReportMetadata failure');
    }
    reports.add({'userId': userId, ...metadata});
  }

  @override
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async =>
      List.from(notifications);

  @override
  Future<void> saveNotification(
    String userId,
    Map<String, dynamic> data, {
    String? notificationId,
  }) async {
    final id = notificationId ?? 'notif_${notifications.length + 1}';
    final index = notifications.indexWhere((n) => n['id'] == id);
    final item = {'id': id, 'userId': userId, ...data};
    if (index == -1) {
      notifications.add(item);
    } else {
      notifications[index] = item;
    }
  }

  @override
  Future<void> markNotificationRead(
    String userId,
    String notificationId,
  ) async {
    final idx = notifications.indexWhere((n) => n['id'] == notificationId);
    if (idx != -1) notifications[idx]['read'] = true;
  }

  @override
  Future<void> registerToken(String userId, String token) async {
    registeredTokens.add('$userId:$token');
  }
}
