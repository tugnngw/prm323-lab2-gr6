/// User-entered academic records. Missing records stay missing; course catalog
/// defaults and simulation sliders are never treated as a transcript.
class TranscriptEntry {
  const TranscriptEntry({
    required this.courseCode,
    required this.credits,
    required this.grade,
    required this.semester,
    required this.passed,
  });
  final String courseCode;
  final int credits;
  final double grade;
  final int semester;
  final bool passed;

  factory TranscriptEntry.fromMap(Map<String, dynamic> map) {
    final rawCredits = map['credits'];
    final rawGrade = map['grade'];
    final rawSem = map['semester'];
    final rawPassed = map['passed'];
    return TranscriptEntry(
      courseCode: map['courseCode']?.toString() ?? '',
      credits: (rawCredits is num) ? rawCredits.toInt() : (int.tryParse(rawCredits?.toString() ?? '') ?? 0),
      grade: (rawGrade is num) ? rawGrade.toDouble() : (double.tryParse(rawGrade?.toString() ?? '') ?? 0.0),
      semester: (rawSem is num) ? rawSem.toInt() : (int.tryParse(rawSem?.toString() ?? '') ?? 1),
      passed: rawPassed == true || rawPassed?.toString().toLowerCase() == 'true',
    );
  }
  Map<String, dynamic> toMap() => {
    'courseCode': courseCode,
    'credits': credits,
    'grade': grade,
    'semester': semester,
    'passed': passed,
  };
}

class AcademicProfile {
  const AcademicProfile({
    this.transcript = const [],
    this.passedCourses = const {},
    this.componentScores = const {},
    this.currentSemester,
    this.targetGpa = 8,
    this.major = '',
  });
  final List<TranscriptEntry> transcript;
  final Set<String> passedCourses;

  /// User-entered component scores keyed by uppercase course code, then by
  /// assessment id from the FLM syllabus (`course.labs[].id`).
  final Map<String, Map<String, double>> componentScores;
  final int? currentSemester;

  /// Personal planning target, not a university classification rule.
  final double targetGpa;

  /// Major selected from the real curriculum imported by staff.
  final String major;

  factory AcademicProfile.fromMap(Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};
    final rawScores = map['componentScores'];
    final scores = <String, Map<String, double>>{};
    if (rawScores is Map) {
      rawScores.forEach((courseKey, value) {
        if (value is! Map) return;
        final perLab = <String, double>{};
        value.forEach((labKey, rawScore) {
          final parsed = rawScore is num
              ? rawScore.toDouble()
              : double.tryParse(rawScore?.toString() ?? '');
          if (parsed != null && parsed.isFinite) {
            perLab[labKey.toString()] = parsed;
          }
        });
        if (perLab.isNotEmpty) {
          scores[courseKey.toString().trim().toUpperCase()] = perLab;
        }
      });
    }
    return AcademicProfile(
      transcript: (map['transcript'] as List? ?? const [])
          .whereType<Map>()
          .map(
            (e) => TranscriptEntry.fromMap(Map<String, dynamic>.from(e)),
          )
          .toList(),
      passedCourses: (map['passedCourses'] as List? ?? const [])
          .map((e) => e.toString())
          .toSet(),
      componentScores: scores,
      currentSemester: (map['currentSemester'] as num?)?.toInt(),
      targetGpa: (map['targetGpa'] as num?)?.toDouble() ?? 8,
      major: map['major']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'transcript': transcript.map((e) => e.toMap()).toList(),
    'passedCourses': passedCourses.toList(),
    'componentScores': componentScores.map(
      (course, labs) => MapEntry(course, Map<String, double>.from(labs)),
    ),
    if (currentSemester != null) 'currentSemester': currentSemester,
    'targetGpa': targetGpa,
    'major': major,
  };

  AcademicProfile copyWith({
    List<TranscriptEntry>? transcript,
    Set<String>? passedCourses,
    Map<String, Map<String, double>>? componentScores,
    int? currentSemester,
    double? targetGpa,
    String? major,
  }) => AcademicProfile(
    transcript: transcript ?? this.transcript,
    passedCourses: passedCourses ?? this.passedCourses,
    componentScores: componentScores ?? this.componentScores,
    currentSemester: currentSemester ?? this.currentSemester,
    targetGpa: targetGpa ?? this.targetGpa,
    major: major ?? this.major,
  );

  double? get cumulativeGpa {
    if (transcript.isEmpty) return null;
    final credits = transcript.fold<int>(
      0,
      (sum, entry) => sum + entry.credits,
    );
    if (credits == 0) return null;
    return transcript.fold<double>(
          0,
          (sum, entry) => sum + entry.grade * entry.credits,
        ) /
        credits;
  }

  Set<String> get completedCodes => {
    ...passedCourses.where(
      (code) => !transcript.any((entry) => entry.courseCode == code),
    ),
    ...transcript
        .where((entry) => entry.passed)
        .map((entry) => entry.courseCode),
  };
}
