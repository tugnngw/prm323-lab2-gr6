class NoteModel {
  const NoteModel({
    required this.id,
    required this.title,
    required this.content,
    required this.courseCode,
    required this.updatedAt,
    this.attachmentUrl,
    this.tags = const [],
  });

  final String id;
  final String title;
  final String content;
  final String courseCode;
  final String updatedAt;
  final String? attachmentUrl;
  final List<String> tags;

  NoteModel copyWith({
    String? id,
    String? title,
    String? content,
    String? courseCode,
    String? updatedAt,
    String? attachmentUrl,
    List<String>? tags,
  }) =>
      NoteModel(
        id: id ?? this.id,
        title: title ?? this.title,
        content: content ?? this.content,
        courseCode: courseCode ?? this.courseCode,
        updatedAt: updatedAt ?? this.updatedAt,
        attachmentUrl: attachmentUrl ?? this.attachmentUrl,
        tags: tags ?? this.tags,
      );

  factory NoteModel.fromMap(Map<String, dynamic> map) => NoteModel(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        content: map['content'] as String? ?? '',
        courseCode: map['courseCode'] as String? ?? map['courseId'] as String? ?? 'Chung',
        updatedAt: map['updatedAt'] as String? ?? 'Vừa xong',
        attachmentUrl: map['attachmentUrl'] as String?,
        tags: (map['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ??
            const [],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'content': content,
        'courseCode': courseCode,
        'updatedAt': updatedAt,
        'attachmentUrl': attachmentUrl,
        'tags': tags,
      };
}
