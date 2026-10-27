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
      debugPrint('[Firestore] Offline persistence enabled with unlimited cache.');
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

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } catch (e) {
      debugPrint('[Firestore] getCourses error: $e');
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

      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } catch (e) {
      debugPrint('[Firestore] getCourse error: $e');
      rethrow;
    }
  }

  // ──────────────────────── Tasks ────────────────────────

  @override
  Future<List<Map<String, dynamic>>> getTasks(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .orderBy('dueDate', descending: false)
          .get(const GetOptions(source: Source.serverAndCache));

      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
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

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .add({
        ...task,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Firestore] addTask error: $e');
      rethrow;
    }
  }

  @override
  Future<void> updateTask(String taskId, Map<String, dynamic> data) async {
    try {
      final userId = data['userId'] as String?;
      if (userId == null) throw ArgumentError('Update data must include userId');

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[Firestore] updateTask error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    // Note: requires knowing userId to delete from user's subcollection
    debugPrint('[Firestore] deleteTask called for $taskId');
  }

  Future<void> deleteTaskForUser(String userId, String taskId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('tasks')
          .doc(taskId)
          .delete();
    } catch (e) {
      debugPrint('[Firestore] deleteTaskForUser error: $e');
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
  Future<void> saveNote(Map<String, dynamic> note) async {
    try {
      final userId = note['userId'] as String?;
      if (userId == null) throw ArgumentError('Note must include userId');

      final noteId = note['id'] as String?;
      final noteRef = noteId != null && noteId.isNotEmpty
          ? _firestore.collection('users').doc(userId).collection('notes').doc(noteId)
          : _firestore.collection('users').doc(userId).collection('notes').doc();

      await noteRef.set({
        ...note,
        'id': noteRef.id,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('[Firestore] saveNote error: $e');
      rethrow;
    }
  }

  @override
  Future<void> deleteNote(String noteId) async {
    debugPrint('[Firestore] deleteNote called for $noteId');
  }

  Future<void> deleteNoteForUser(String userId, String noteId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notes')
          .doc(noteId)
          .delete();
    } catch (e) {
      debugPrint('[Firestore] deleteNoteForUser error: $e');
      rethrow;
    }
  }
}
