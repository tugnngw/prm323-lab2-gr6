import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'firestore_service.dart';

/// Cloud Firestore implementation with offline persistence enabled.
class FirebaseFirestoreService implements FirestoreService {
  FirebaseFirestoreService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance {
    _initPersistence();
  }

  final FirebaseFirestore _firestore;

  void _initPersistence() {
    try {
      _firestore.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
      );
      debugPrint(
        '[Firestore] Offline persistence enabled with unlimited cache.',
      );
    } catch (e) {
      debugPrint('[Firestore] Persistence config warning: $e');
    }
  }

  // ──────────────────────── Courses / Roadmap ────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getCourses(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('courses')
          .orderBy('semester')
          .get(const GetOptions(source: Source.serverAndCache));

      debugPrint(
        '[Firestore] Course catalog returned ${snapshot.docs.length} documents.',
      );
      return snapshot.docs
          .where((doc) => doc.data()['archived'] != true)
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList();
    } catch (e) {
      debugPrint('[Firestore] getCourses error: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCoursesForMajor(
    String majorCode,
  ) async {
    final code = majorCode.trim();
    if (code.isEmpty) return [];
    try {
      final snapshot = await _firestore
          .collection('courses')
          .where('major', isEqualTo: code)
          .get(const GetOptions(source: Source.serverAndCache));
      final courses = snapshot.docs
          .where((doc) => doc.data()['archived'] != true)
          .map((doc) => {'id': doc.id, ...doc.data()})
          .toList()
        ..sort((a, b) {
          final semesterA = (a['semester'] as num?)?.toInt() ?? 0;
          final semesterB = (b['semester'] as num?)?.toInt() ?? 0;
          final bySemester = semesterA.compareTo(semesterB);
          if (bySemester != 0) return bySemester;
          return (a['code'] ?? '')
              .toString()
              .compareTo((b['code'] ?? '').toString());
        });
      debugPrint(
        '[Firestore] Major $code returned ${courses.length} course documents.',
      );
      return courses;
    } catch (e) {
      debugPrint('[Firestore] getCoursesForMajor error: $e');
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>?> getCourse(String courseId) async {
    try {
      final doc = await _firestore
          .collection('courses')
          .doc(courseId)
          .get(const GetOptions(source: Source.serverAndCache));

      if (!doc.exists || doc.data()?['archived'] == true) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (e) {
      debugPrint('[Firestore] getCourse error: $e');
      rethrow;
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getMajors() async {
    try {
      final snapshot = await _firestore
          .collection('majors')
          .get(const GetOptions(source: Source.serverAndCache));
      final activeMajors = snapshot.docs
          .where((doc) => doc.data()['archived'] != true)
          .toList();
      if (activeMajors.isNotEmpty) {
        return activeMajors
            .map((doc) => {'code': doc.id, ...doc.data()})
            .toList();
      }
      final curSnapshot = await _firestore
          .collection('curriculums')
          .get(const GetOptions(source: Source.serverAndCache));
      final activeCurricula = curSnapshot.docs
          .where((doc) => doc.data()['archived'] != true)
          .toList();
      if (activeCurricula.isNotEmpty) {
        return activeCurricula
            .map((doc) => {'code': doc.id, ...doc.data()})
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('[Firestore] getMajors error: $e');
      return [];
    }
  }

  @override
  Future<Map<String, dynamic>?> getUserProfile(String userId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .get(const GetOptions(source: Source.serverAndCache));
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (e) {
      debugPrint('[Firestore] getUserProfile error: $e');
      rethrow;
    }
  }

  @override
  Stream<String?> watchUserRole(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .snapshots()
      .map((doc) => doc.data()?['role'] as String?);

  // ──────────────────── Per-student course progress ────────────────────

  @override
  Future<List<Map<String, dynamic>>> getCourseProgress(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('courseProgress')
          .get(const GetOptions(source: Source.serverAndCache));
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          ...data,
          'courseDocId': data['courseDocId'] ?? doc.id,
          'id': doc.id,
        };
      }).toList();
    } catch (e) {
      debugPrint('[Firestore] getCourseProgress error: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveCourseProgress(
    String userId,
    String courseDocId,
    Map<String, dynamic> data,
  ) async {
    if (userId.isEmpty) throw ArgumentError('Missing owner UID');
    if (courseDocId.isEmpty) throw ArgumentError('Missing course document ID');
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('courseProgress')
        .doc(courseDocId)
        .set({
          ...data,
          'courseDocId': courseDocId,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  // ──────────────────────── Announcements ────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getAnnouncements() async {
    try {
      final snapshot = await _firestore
          .collection('announcements')
          .orderBy('publishedAt', descending: true)
          .limit(50)
          .get(const GetOptions(source: Source.serverAndCache));
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('[Firestore] getAnnouncements error: $e');
      rethrow;
    }
  }

  @override
  Stream<List<Map<String, dynamic>>> watchAnnouncements() => _firestore
      .collection('announcements')
      .orderBy('publishedAt', descending: true)
      .limit(50)
      .snapshots()
      .map(
        (snapshot) =>
            snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList(),
      );

  // ──────────────────────── Tasks ────────────────────────

  @override
  Future<void> saveAcademicProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    if (userId.isEmpty) throw ArgumentError('Missing owner UID');
    await _firestore.collection('users').doc(userId).set({
      ...data,
      'academicUpdatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Future<void> saveComponentScores(
    String userId,
    Map<String, dynamic> componentScores,
  ) async {
    if (userId.isEmpty) throw ArgumentError('Missing owner UID');
    final ref = _firestore.collection('users').doc(userId);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      final payload = <String, dynamic>{
        'componentScores': componentScores,
        'academicDataSource': 'user_entered',
        'academicUpdatedAt': FieldValue.serverTimestamp(),
      };
      if (snapshot.exists) {
        transaction.update(ref, payload);
      } else {
        transaction.set(ref, payload);
      }
    });
  }

  @override
  Future<List<Map<String, dynamic>>> getTasks(String userId) async {
    try {
      // No server-side dueDate ordering: stored dates are display strings
      // (`dd/MM/yyyy` or free text), so lexicographic order is wrong and a
      // missing field would drop the task. The ViewModel sorts by parsed date.
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .get(const GetOptions(source: Source.serverAndCache));

      // Prefer the actual Firestore document ID as the canonical task ID.
      // For new documents (T03-M11D fix): doc.data()['id'] == snapshot.id.
      // For legacy documents (old .add()): doc.data()['id'] differs from snapshot.id;
      // we use snapshot.id as the canonical ID and preserve the original data.id
      // as a legacy reference field.
      return snapshot.docs.map((doc) {
        final data = doc.data();
        final dataId = data['id'];
        return <String, dynamic>{
          ...data,
          'id': doc.id,
          if (dataId is String && dataId.isNotEmpty && dataId != doc.id)
            'legacyId': dataId,
        };
      }).toList();
    } catch (e) {
      debugPrint('[Firestore] getTasks error: $e');
      rethrow;
    }
  }

  @override
  Future<void> addTask(Map<String, dynamic> task) async {
    try {
      final userId = task['userId'] as String?;
      if (userId == null) throw ArgumentError('Task must include userId');

      // Use the app-generated task ID as the Firestore document ID
      // so that updateTask/deleteTask can target the correct document path.
      var taskId = task['id'] as String?;
      if (taskId == null || taskId.isEmpty) {
        // Fallback: generate an ID and use .doc(id).set() if no ID provided
        taskId = DateTime.now().millisecondsSinceEpoch.toString();
      }
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .set({
            ...task,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Firestore] addTask error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    try {
      final userId = data['userId'] as String?;
      if (userId == null) {
        throw ArgumentError('Update data must include userId');
      }

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .update({...data, 'updatedAt': FieldValue.serverTimestamp()});
    } catch (e) {
      // T03-M11C temporary capture block removed: root cause was the legacy
      // task ID mismatch fixed in T03-M11D/M11E (canonical doc IDs).
      debugPrint('[Firestore] updateTask error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteTask(String userId, String taskId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      debugPrint('[Firestore] deleteTask error: $e');
      rethrow;
    }
  }

  // ──────────────────────── Notes ────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getNotes(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .orderBy('updatedAt', descending: true)
          .get(const GetOptions(source: Source.serverAndCache));

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('[Firestore] getNotes error: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveNote(
    Map<String, dynamic> note, {
    (String?, String?)? attachmentBefore,
    bool preserveAttachment = false,
  }) async {
    try {
      final userId = note['userId'] as String?;
      if (userId == null) throw ArgumentError('Note must include userId');

      final noteId = note['id'] as String?;
      final noteRef = noteId != null && noteId.isNotEmpty
          ? _firestore
                .collection('users')
                .doc(userId)
                .collection('notes')
                .doc(noteId)
          : _firestore
                .collection('users')
                .doc(userId)
                .collection('notes')
                .doc();

      final data = {
        ...note,
        'id': noteRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      };
      if (preserveAttachment) {
        data.remove('attachmentPath');
        data.remove('attachmentUrl');
        data.remove('attachmentName');
      }
      if (attachmentBefore == null) {
        await noteRef.set(data, SetOptions(merge: true));
      } else {
        await _firestore.runTransaction((transaction) async {
          final current = (await transaction.get(noteRef)).data();
          if (current == null ||
              (current['attachmentPath'], current['attachmentUrl']) !=
                  attachmentBefore) {
            throw StateError('Tệp đã thay đổi trên thiết bị khác.');
          }
          transaction.set(noteRef, data, SetOptions(merge: true));
        });
      }
    } catch (e) {
      debugPrint('[Firestore] saveNote error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteNote(String userId, String noteId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId)
          .delete();
    } catch (e) {
      debugPrint('[Firestore] deleteNote error: $e');
      rethrow;
    }
  }

  // ──────────────────────── Report metadata ────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getRecentReportMetadata(
    String userId,
  ) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('sync')
        .orderBy('createdAt', descending: true)
        .limit(30)
        .get(const GetOptions(source: Source.serverAndCache));
    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  @override
  Future<void> saveReportMetadata(
    String userId,
    Map<String, dynamic> metadata,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('sync')
          .doc('report_${DateTime.now().millisecondsSinceEpoch}')
          .set({...metadata, 'createdAt': FieldValue.serverTimestamp()});
      debugPrint('[Firestore] Saved report metadata for $userId');
    } catch (e) {
      debugPrint('[Firestore] saveReportMetadata error: $e');
      rethrow;
    }
  }

  // ──────────────────────── Notification Center ────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getNotifications(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .orderBy('receivedAt', descending: true)
          .limit(50)
          .get(const GetOptions(source: Source.serverAndCache));
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('[Firestore] getNotifications error: $e');
      rethrow;
    }
  }

  @override
  Future<void> saveNotification(
    String userId,
    Map<String, dynamic> data, {
    String? notificationId,
  }) async {
    try {
      final ref = _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId);
      await ref.set({
        ...data,
        'receivedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Firestore] saveNotification error: $e');
      rethrow;
    }
  }

  @override
  Future<void> markNotificationRead(
    String userId,
    String notificationId,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({'read': true});
    } catch (e) {
      debugPrint('[Firestore] markNotificationRead error: $e');
      rethrow;
    }
  }

  @override
  Future<void> registerToken(String userId, String token) async {
    try {
      // Deterministic doc id (hash of token) keeps one row per device token.
      final tokenId = token.length > 24 ? token.substring(0, 24) : token;
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tokens')
          .doc(tokenId)
          .set({
            'token': token,
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      debugPrint('[Firestore] Registered FCM token for $userId');
    } catch (e) {
      debugPrint('[Firestore] registerToken error: $e');
      rethrow;
    }
  }
}
