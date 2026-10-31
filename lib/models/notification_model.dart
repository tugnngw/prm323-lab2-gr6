/// A Notification Center entry (Lab 3 T12 — FCM + Notification Center).
///
/// Mirrors documents at `users/{uid}/notifications/{id}`. Timestamps are kept
/// as display strings because Firestore server timestamps arrive inconsistently
/// across cache/server sources; ordering uses [receivedAt] when parseable and
/// otherwise the document order returned by the service.
class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.type = 'system',
    this.read = false,
    this.receivedAt = '',
  });

  final String id;
  final String title;
  final String body;

  /// 'task_due' | 'sync' | 'advisor' | 'system'
  final String type;
  final bool read;
  final String receivedAt;

  bool get isUnread => !read;

  factory NotificationModel.fromMap(Map<String, dynamic> map) =>
      NotificationModel(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        body: map['body'] as String? ?? '',
        type: map['type'] as String? ?? 'system',
        read: map['read'] as bool? ?? false,
        receivedAt: map['receivedAt'] as String? ?? '',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'body': body,
        'type': type,
        'read': read,
        'receivedAt': receivedAt,
      };

  NotificationModel copyWith({bool? read}) => NotificationModel(
        id: id,
        title: title,
        body: body,
        type: type,
        read: read ?? this.read,
        receivedAt: receivedAt,
      );

  /// Firebase Cloud Messaging payloads carry `title`/`body` plus custom data.
  /// [notificationId] (when present) is the Firestore document id used to mark
  /// the entry read after the user taps it.
  factory NotificationModel.fromPush(
    Map<String, dynamic> payload, {
    String? fallbackId,
  }) {
    final data = payload['data'];
    final map = data is Map
        ? Map<String, dynamic>.from(data)
        : <String, dynamic>{};
    final id = map['notificationId'] as String? ??
        payload['notificationId'] as String? ??
        fallbackId ??
        'local_${DateTime.now().microsecondsSinceEpoch}';
    final ts = map['receivedAt'] as String? ??
        payload['receivedAt'] as String? ??
        DateTime.now().toIso8601String();
    return NotificationModel(
      id: id,
      title: payload['title'] as String? ?? map['title'] as String? ?? '',
      body: payload['body'] as String? ?? map['body'] as String? ?? '',
      type: map['type'] as String? ?? payload['type'] as String? ?? 'system',
      read: false,
      receivedAt: ts,
    );
  }
}
