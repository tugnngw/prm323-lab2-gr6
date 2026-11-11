import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// A server-wide announcement written by staff/admin to `announcements/{id}`.
/// Shared by every signed-in student, so read state lives on the user profile
/// (`readAnnouncementIds`), not on the announcement document.
class AnnouncementModel {
  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    this.publishedAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime? publishedAt;

  String get publishedLabel => publishedAt == null
      ? ''
      : DateFormat('dd/MM/yyyy HH:mm').format(publishedAt!);

  factory AnnouncementModel.fromMap(Map<String, dynamic> map) {
    final raw = map['publishedAt'];
    DateTime? published;
    if (raw is Timestamp) {
      published = raw.toDate();
    } else if (raw is DateTime) {
      published = raw;
    } else if (raw is String) {
      published = DateTime.tryParse(raw);
    }
    return AnnouncementModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      body: map['body']?.toString() ?? '',
      publishedAt: published,
    );
  }
}
