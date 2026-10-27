class CourseLab {
  const CourseLab({
    required this.id,
    required this.title,
    required this.deadline,
    this.score,
    this.status = 'pending', // 'submitted', 'graded', 'pending'
  });

  final String id;
  final String title;
  final String deadline;
  final double? score;
  final String status;

  factory CourseLab.fromMap(Map<String, dynamic> map) => CourseLab(
        id: map['id'] as String? ?? '',
        title: map['title'] as String? ?? '',
        deadline: map['deadline'] as String? ?? '',
        score: (map['score'] as num?)?.toDouble(),
        status: map['status'] as String? ?? 'pending',
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'deadline': deadline,
        'score': score,
        'status': status,
      };
}

class CourseModel {
  const CourseModel({
    required this.id,
    required this.code,
    required this.name,
    required this.credits,
    required this.semester,
    required this.major,
    this.prerequisites = const [],
    this.totalSlots = 30,
    this.completedSlots = 0,
    this.currentGrade,
    this.status = 'enrolled',
    this.lecturer = 'GV. Bộ môn SE',
    this.labs = const [],
  });

  final String id;
  final String code;
  final String name;
  final int credits;
  final int semester;
  final String major;
  final List<String> prerequisites;
  final int totalSlots;
  final int completedSlots;
  final double? currentGrade;
  final String status;
  final String lecturer;
  final List<CourseLab> labs;

  double get progress => totalSlots > 0 ? completedSlots / totalSlots : 0.0;

  factory CourseModel.fromMap(Map<String, dynamic> map) => CourseModel(
        id: map['id'] as String? ?? map['code'] as String? ?? '',
        code: map['code'] as String? ?? '',
        name: map['name'] as String? ?? '',
        credits: (map['credits'] as num?)?.toInt() ?? 3,
        semester: (map['semester'] as num?)?.toInt() ?? 5,
        major: map['major'] as String? ?? 'SE',
        prerequisites: (map['prerequisites'] as List<dynamic>?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        totalSlots: (map['totalSlots'] as num?)?.toInt() ??
            (map['syllabus']?['totalSlots'] as num?)?.toInt() ??
            30,
        completedSlots: (map['completedSlots'] as num?)?.toInt() ??
            (map['syllabus']?['completedSlots'] as num?)?.toInt() ??
            0,
        currentGrade: (map['currentGrade'] as num?)?.toDouble(),
        status: map['status'] as String? ?? 'enrolled',
        lecturer: map['lecturer'] as String? ?? 'GV. Bộ môn SE',
        labs: (map['labs'] as List<dynamic>?)
                ?.map((l) => CourseLab.fromMap(l as Map<String, dynamic>))
                .toList() ??
            const [],
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'code': code,
        'name': name,
        'credits': credits,
        'semester': semester,
        'major': major,
        'prerequisites': prerequisites,
        'totalSlots': totalSlots,
        'completedSlots': completedSlots,
        'currentGrade': currentGrade,
        'status': status,
        'lecturer': lecturer,
        'labs': labs.map((l) => l.toMap()).toList(),
      };
}
