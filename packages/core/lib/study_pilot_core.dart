import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';

class StudyPlanSubmission {
  StudyPlanSubmission({
    required this.id,
    required this.uid,
    required this.semester,
    required this.summary,
    required this.status,
    required this.reason,
    this.courseCode,
  });

  StudyPlanSubmission.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc)
    : id = doc.id,
      uid = doc.data()?.containsKey('uid') == true ? doc.get('uid') as String : '',
      semester = doc.data()?.containsKey('semester') == true ? doc.get('semester') as int : 1,
      summary = doc.data()?.containsKey('summary') == true ? doc.get('summary') as String : '',
      status = doc.data()?.containsKey('status') == true ? doc.get('status') as String : 'pending',
      reason = doc.data()?.containsKey('reason') == true ? doc.get('reason') as String : '',
      courseCode = _extractCourseCode(doc.data()?.containsKey('summary') == true ? doc.get('summary') as String : '');

  final String id;
  final String uid;
  final int semester;
  final String summary;
  final String status;
  final String reason;
  final String? courseCode;

  static String? _extractCourseCode(String text) {
    final match = RegExp(r'^\[([A-Za-z0-9_]{2,16})\]').firstMatch(text.trim());
    return match?.group(1)?.toUpperCase();
  }

  /// Clean display text without the `[COURSE_CODE]` tag
  String get displayBody {
    if (courseCode != null && summary.startsWith('[$courseCode]')) {
      return summary.substring('[$courseCode]'.length).trim();
    }
    return summary;
  }
}

class Announcement {
  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    this.publishedAt,
  });

  Announcement.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc)
    : id = doc.id,
      title = doc.get('title') as String? ?? '',
      body = doc.get('body') as String? ?? '',
      publishedAt = (doc.get('publishedAt') as Timestamp?)?.toDate();

  final String id;
  final String title;
  final String body;
  final DateTime? publishedAt;
}

class ExperienceNote {
  ExperienceNote.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc)
    : id = doc.id,
      courseDocId = doc.get('courseDocId') as String? ?? '',
      courseCode = doc.get('courseCode') as String? ?? '',
      courseName = doc.get('courseName') as String? ?? '',
      major = doc.get('major') as String? ?? '',
      uid = doc.get('uid') as String? ?? '',
      authorName = doc.get('authorName') as String? ?? '',
      title = doc.get('title') as String? ?? '',
      content = doc.get('content') as String? ?? '',
      lecturerTip = doc.get('lecturerTip') as String? ?? '',
      examTip = doc.get('examTip') as String? ?? '',
      rating = (doc.get('rating') as num?)?.toInt() ?? 0,
      status = doc.get('status') as String? ?? 'pending',
      reason = doc.get('reason') as String? ?? '',
      createdAt = (doc.get('createdAt') as Timestamp?)?.toDate(),
      reviewedAt = (doc.get('reviewedAt') as Timestamp?)?.toDate();

  final String id;
  final String courseDocId;
  final String courseCode;
  final String courseName;
  final String major;
  final String uid;
  final String authorName;
  final String title;
  final String content;
  final String lecturerTip;
  final String examTip;
  final int rating;
  final String status;
  final String reason;
  final DateTime? createdAt;
  final DateTime? reviewedAt;

  String get displayTitle =>
      title.trim().isNotEmpty ? title.trim() : 'Bí kíp môn $courseCode';
}

/// One rating per student per tip, stored at `tip_ratings/{tipId}__{uid}`.
class TipRating {
  TipRating.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc)
    : id = doc.id,
      tipId = doc.get('tipId') as String? ?? '',
      courseDocId = doc.get('courseDocId') as String? ?? '',
      uid = doc.get('uid') as String? ?? '',
      displayName = doc.get('displayName') as String? ?? '',
      stars = (doc.get('stars') as num?)?.toInt() ?? 0,
      createdAt = (doc.get('createdAt') as Timestamp?)?.toDate();

  final String id;
  final String tipId;
  final String courseDocId;
  final String uid;
  final String displayName;
  final int stars;
  final DateTime? createdAt;
}

/// Unmoderated discussion entry under a tip.
class TipComment {
  TipComment.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc)
    : id = doc.id,
      tipId = doc.get('tipId') as String? ?? '',
      courseDocId = doc.get('courseDocId') as String? ?? '',
      courseCode = doc.get('courseCode') as String? ?? '',
      uid = doc.get('uid') as String? ?? '',
      authorName = doc.get('authorName') as String? ?? '',
      content = doc.get('content') as String? ?? '',
      createdAt = (doc.get('createdAt') as Timestamp?)?.toDate();

  final String id;
  final String tipId;
  final String courseDocId;
  final String courseCode;
  final String uid;
  final String authorName;
  final String content;
  final DateTime? createdAt;
}

class FinalFirestore {
  FinalFirestore(this.firestore);

  final FirebaseFirestore firestore;

  Stream<List<ExperienceNote>> watchCourseNotes(
    String courseDocId, {
    required String uid,
  }) {
    final controller = StreamController<List<ExperienceNote>>();
    List<ExperienceNote>? approvedNotes;
    List<ExperienceNote>? myNotes;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? approvedSub;
    StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? mineSub;

    void emit() {
      if (approvedNotes == null || myNotes == null || controller.isClosed) {
        return;
      }
      final merged = <String, ExperienceNote>{
        for (final note in approvedNotes!) note.id: note,
        for (final note in myNotes!) note.id: note,
      };
      final list = merged.values.toList()
        ..sort((a, b) {
          final left = a.createdAt?.millisecondsSinceEpoch ?? 0;
          final right = b.createdAt?.millisecondsSinceEpoch ?? 0;
          return right.compareTo(left);
        });
      controller.add(list);
    }

    controller.onListen = () {
      approvedSub = firestore
          .collection('experience_notes')
          .where('courseDocId', isEqualTo: courseDocId)
          .where('status', isEqualTo: 'approved')
          .snapshots()
          .listen((snapshot) {
            approvedNotes = snapshot.docs.map(ExperienceNote.fromDocument).toList();
            emit();
          }, onError: controller.addError);
      mineSub = firestore
          .collection('experience_notes')
          .where('courseDocId', isEqualTo: courseDocId)
          .where('uid', isEqualTo: uid)
          .snapshots()
          .listen((snapshot) {
            myNotes = snapshot.docs.map(ExperienceNote.fromDocument).toList();
            emit();
          }, onError: controller.addError);
    };
    controller.onCancel = () {
      approvedSub?.cancel();
      mineSub?.cancel();
    };
    return controller.stream;
  }

  Future<List<ExperienceNote>> getApprovedExperienceNotes({
    String? courseCode,
  }) async {
    final snapshot = await firestore
        .collection('experience_notes')
        .where('status', isEqualTo: 'approved')
        .get();
    var list = snapshot.docs.map(ExperienceNote.fromDocument).toList();
    if (courseCode != null && courseCode.isNotEmpty) {
      final target = courseCode.toUpperCase();
      list = list
          .where((note) => note.courseCode.toUpperCase() == target)
          .toList();
    }
    list.sort((a, b) {
      final left = a.createdAt?.millisecondsSinceEpoch ?? 0;
      final right = b.createdAt?.millisecondsSinceEpoch ?? 0;
      return right.compareTo(left);
    });
    return list;
  }

  Future<void> submitExperienceNote({
    required String courseDocId,
    required String courseCode,
    required String courseName,
    required String major,
    required String uid,
    required String authorName,
    required String title,
    required String content,
    String lecturerTip = '',
    String examTip = '',
    int rating = 0,
  }) {
    return firestore.collection('experience_notes').add({
      'courseDocId': courseDocId,
      'courseCode': courseCode,
      'courseName': courseName,
      'major': major,
      'uid': uid,
      'authorName': authorName,
      'title': title,
      'content': content,
      if (lecturerTip.isNotEmpty) 'lecturerTip': lecturerTip,
      if (examTip.isNotEmpty) 'examTip': examTip,
      'rating': rating,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// All notes (pending / approved / rejected) authored by [uid], so the
  /// student can review moderation status and rejection reasons.
  Stream<List<ExperienceNote>> watchMyNotes(String uid) => firestore
      .collection('experience_notes')
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((snapshot) {
        final list = snapshot.docs.map(ExperienceNote.fromDocument).toList();
        list.sort((a, b) {
          final left = a.createdAt?.millisecondsSinceEpoch ?? 0;
          final right = b.createdAt?.millisecondsSinceEpoch ?? 0;
          return right.compareTo(left);
        });
        return list;
      });

  /// Ratings for every tip of one course. Aggregates (count / average) are
  /// derived on the client so no Cloud Function is required.
  Stream<List<TipRating>> watchCourseRatings(String courseDocId) => firestore
      .collection('tip_ratings')
      .where('courseDocId', isEqualTo: courseDocId)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(TipRating.fromDocument).toList());

  /// Comments for every tip of one course, newest first.
  Stream<List<TipComment>> watchCourseComments(String courseDocId) => firestore
      .collection('tip_comments')
      .where('courseDocId', isEqualTo: courseDocId)
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(TipComment.fromDocument).toList());

  /// Writes one rating per student (`tipId__uid`) and tells the tip author
  /// through the ordinary Notification Center store. No self-notification.
  Future<void> rateTip({
    required String tipId,
    required String courseDocId,
    required String courseCode,
    required String authorUid,
    required String uid,
    required String displayName,
    required int stars,
  }) async {
    final safeStars = stars.clamp(1, 5);
    await firestore.collection('tip_ratings').doc('${tipId}__$uid').set({
      'tipId': tipId,
      'courseDocId': courseDocId,
      'uid': uid,
      'displayName': displayName,
      'stars': safeStars,
      'createdAt': FieldValue.serverTimestamp(),
    });
    if (authorUid.isEmpty || authorUid == uid) return;
    await firestore
        .collection('users')
        .doc(authorUid)
        .collection('notifications')
        .doc('tip_rating_${tipId}_$uid')
        .set({
          'title': 'Có người đánh giá $safeStars★ cho bí kíp của bạn',
          'body':
              '${displayName.isEmpty ? 'Một sinh viên' : displayName} đã đánh giá '
              '$safeStars sao cho bí kíp môn $courseCode.',
          'type': 'tip_rating',
          'read': false,
          'receivedAt': FieldValue.serverTimestamp(),
          'route': '/course-tips',
          'routeArgument': courseDocId,
          'recipientId': authorUid,
          'actorId': uid,
        });
  }

  Future<void> addTipComment({
    required String tipId,
    required String courseDocId,
    required String courseCode,
    required String uid,
    required String authorName,
    required String content,
  }) {
    return firestore.collection('tip_comments').add({
      'tipId': tipId,
      'courseDocId': courseDocId,
      'courseCode': courseCode,
      'uid': uid,
      'authorName': authorName,
      'content': content.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<StudyPlanSubmission>> watchSubmissions(String uid) => firestore
      .collection('study_plan_submissions')
      .where('uid', isEqualTo: uid)
      .snapshots()
      .map((snapshot) {
        final records = snapshot.docs
            .map(StudyPlanSubmission.fromDocument)
            .toList();
        records.sort((a, b) => b.semester.compareTo(a.semester));
        return records;
      });

  /// Streams approved community reviews/tips for all students to learn from.
  Stream<List<StudyPlanSubmission>> watchApprovedTips([String? courseCode]) =>
      firestore
          .collection('study_plan_submissions')
          .where('status', isEqualTo: 'approved')
          .snapshots()
          .map((snapshot) {
            final list = snapshot.docs
                .map(StudyPlanSubmission.fromDocument)
                .toList();
            if (courseCode == null || courseCode.isEmpty) return list;
            final target = courseCode.toUpperCase();
            return list.where((s) =>
                s.courseCode == target ||
                s.summary.toUpperCase().contains('[$target]') ||
                s.summary.toUpperCase().contains(target)).toList();
          });

  Future<List<StudyPlanSubmission>> getApprovedTips([String? courseCode]) async {
    final snapshot = await firestore
        .collection('study_plan_submissions')
        .where('status', isEqualTo: 'approved')
        .get();
    final list = snapshot.docs.map(StudyPlanSubmission.fromDocument).toList();
    if (courseCode == null || courseCode.isEmpty) return list;
    final target = courseCode.toUpperCase();
    return list.where((s) =>
        s.courseCode == target ||
        s.summary.toUpperCase().contains('[$target]') ||
        s.summary.toUpperCase().contains(target)).toList();
  }

  Future<void> submit(String uid, int semester, String summary) => firestore
      .collection('study_plan_submissions')
      .doc('${uid}_$semester')
      .set({
        'uid': uid,
        'semester': semester,
        'summary': summary,
        'status': 'pending',
        'reason': '',
        'createdAt': FieldValue.serverTimestamp(),
      });

  Stream<List<Announcement>> watchAnnouncements() => firestore
      .collection('announcements')
      .orderBy('publishedAt', descending: true)
      .limit(50)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Announcement.fromDocument).toList());

  Future<String> ensureRole(String uid) =>
      firestore.runTransaction((transaction) async {
        final ref = firestore.collection('users').doc(uid);
        final snapshot = await transaction.get(ref);
        final role = snapshot.data()?['role'];
        if (role is String) return role;
        transaction.set(ref, {'role': 'user'}, SetOptions(merge: true));
        return 'user';
      });
}
