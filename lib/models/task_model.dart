class TaskModel {
  const TaskModel({
    required this.id,
    required this.title,
    required this.courseCode,
    required this.dueDate,
    this.isCompleted = false,
    this.priority = 'medium',
  });

  final String id;
  final String title;
  final String courseCode;
  final String dueDate;
  final bool isCompleted;
  final String priority;

  TaskModel copyWith({
    String? id,
    String? title,
    String? courseCode,
    String? dueDate,
    bool? isCompleted,
    String? priority,
  }) =>
      TaskModel(
        id: id ?? this.id,
        title: title ?? this.title,
        courseCode: courseCode ?? this.courseCode,
        dueDate: dueDate ?? this.dueDate,
        isCompleted: isCompleted ?? this.isCompleted,
        priority: priority ?? this.priority,
      );

  factory TaskModel.fromMap(Map<String, dynamic> map) => TaskModel(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        courseCode: map['courseCode'] as String? ?? map['courseId'] as String? ?? 'Chung',
        dueDate: map['dueDate'] as String? ?? '',
        isCompleted: map['isCompleted'] as bool? ?? false,
        priority: map['priority'] as String? ?? 'medium',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'courseCode': courseCode,
        'dueDate': dueDate,
        'isCompleted': isCompleted,
        'priority': priority,
      };

  /// Parsed deadline. Accepts `dd/MM/yyyy`, `d/M/yyyy`, ISO-8601 and
  /// `dd/MM/yyyy HH:mm`. Returns null for free text like
  /// "Hạn nộp theo thông báo kỳ" so such tasks are never treated as overdue.
  DateTime? get dueDateValue => parseDueDate(dueDate);

  static DateTime? parseDueDate(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return null;
    final iso = DateTime.tryParse(text);
    if (iso != null) return iso;
    final match = RegExp(
      r'^(\d{1,2})/(\d{1,2})/(\d{4})(?:\s+(\d{1,2}):(\d{2}))?',
    ).firstMatch(text);
    if (match == null) return null;
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    if (day == null || month == null || year == null) return null;
    final hour = int.tryParse(match.group(4) ?? '') ?? 0;
    final minute = int.tryParse(match.group(5) ?? '') ?? 0;
    final parsed = DateTime(year, month, day, hour, minute);
    // DateTime normalizes 31/02 into March; reject values that moved.
    if (parsed.day != day || parsed.month != month) return null;
    return parsed;
  }
}
