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
}
