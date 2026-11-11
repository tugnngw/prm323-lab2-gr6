/// Per-student progress for a course, stored at
/// `users/{uid}/courseProgress/{courseDocId}`. Catalog slot counters stay
/// shared; this document is the only place a student's own ticks live.
class CourseProgress {
  const CourseProgress({
    this.courseDocId = '',
    this.completedSlotNumbers = const {},
    this.courseCompleted = false,
    this.lecturer = '',
  });

  final String courseDocId;
  final Set<int> completedSlotNumbers;

  /// Marks the whole course done without requiring every syllabus slot to be
  /// ticked (a student may skip self-study slots).
  final bool courseCompleted;

  /// Lecturer the student recorded for themselves; empty means "use catalog".
  final String lecturer;

  bool isSlotCompleted(int slotNumber) =>
      courseCompleted || completedSlotNumbers.contains(slotNumber);

  int completedCount(int totalSlots) {
    if (courseCompleted) return totalSlots;
    if (totalSlots <= 0) return completedSlotNumbers.length;
    return completedSlotNumbers.where((n) => n >= 1 && n <= totalSlots).length;
  }

  double progress(int totalSlots) {
    if (totalSlots <= 0) return 0;
    return (completedCount(totalSlots) / totalSlots).clamp(0.0, 1.0);
  }

  factory CourseProgress.fromMap(Map<String, dynamic> map) => CourseProgress(
    courseDocId: map['courseDocId']?.toString() ?? '',
    completedSlotNumbers: (map['completedSlotNumbers'] as List? ?? const [])
        .map((value) => value is num ? value.toInt() : int.tryParse('$value'))
        .whereType<int>()
        .where((value) => value > 0)
        .toSet(),
    courseCompleted: map['courseCompleted'] == true,
    lecturer: map['lecturer']?.toString() ?? '',
  );

  Map<String, dynamic> toMap() => {
    'courseDocId': courseDocId,
    'completedSlotNumbers': completedSlotNumbers.toList()..sort(),
    'courseCompleted': courseCompleted,
    'lecturer': lecturer,
  };

  CourseProgress copyWith({
    String? courseDocId,
    Set<int>? completedSlotNumbers,
    bool? courseCompleted,
    String? lecturer,
  }) => CourseProgress(
    courseDocId: courseDocId ?? this.courseDocId,
    completedSlotNumbers: completedSlotNumbers ?? this.completedSlotNumbers,
    courseCompleted: courseCompleted ?? this.courseCompleted,
    lecturer: lecturer ?? this.lecturer,
  );
}
