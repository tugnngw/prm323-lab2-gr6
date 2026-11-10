import 'slot_catalog.dart';

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

  factory TranscriptEntry.fromMap(Map<String, dynamic> map) => TranscriptEntry(
    courseCode: map['courseCode'] as String,
    credits: (map['credits'] as num).toInt(),
    grade: (map['grade'] as num).toDouble(),
    semester: (map['semester'] as num).toInt(),
    passed: map['passed'] as bool,
  );
  Map<String, dynamic> toMap() => {
    'courseCode': courseCode,
    'credits': credits,
    'grade': grade,
    'semester': semester,
    'passed': passed,
  };
}

/// One recurring weekly class session of a course.
///
/// A course may own several of these (different days, slots, rooms or
/// lecturers). Times are stored as 'HH:mm' so a session keeps the times the
/// user confirmed even after the slot catalog changes.
class TimetableEntry {
  const TimetableEntry({
    this.id = '',
    required this.courseCode,
    this.courseName = '',
    required this.weekday,
    this.slotNumber,
    required this.startTime,
    required this.endTime,
    this.room = '',
    this.campus = '',
    this.lecturer = '',
    this.section = '',
    this.notes = '',
    this.semester,
    this.effectiveStart,
    this.effectiveEnd,
  });

  /// Stable identity for edit/delete/duplicate. Empty on legacy documents.
  final String id;
  final String courseCode;
  final String courseName;

  /// ISO weekday: Monday=1, Sunday=7.
  final int weekday;

  /// Slot the session was created from; null when times are custom.
  final int? slotNumber;

  /// 'HH:mm'.
  final String startTime;

  /// 'HH:mm'.
  final String endTime;

  final String room;
  final String campus;
  final String lecturer;
  final String section;
  final String notes;

  /// Academic term number, e.g. 3 for "Kỳ 3".
  final int? semester;

  /// 'yyyy-MM-dd'; the weekly session repeats inside this range.
  final String? effectiveStart;
  final String? effectiveEnd;

  int? get startMinutes => parseClock(startTime);
  int? get endMinutes => parseClock(endTime);

  /// True when both times parse and end is after start.
  bool get hasValidRange {
    final s = startMinutes;
    final e = endMinutes;
    return s != null && e != null && e > s;
  }

  bool get isLegacy => id.isEmpty;

  /// True when the two sessions could actually meet: same weekday, overlapping
  /// clock range, and intersecting effective periods. Sessions in different
  /// academic periods never clash even at the same time.
  bool overlaps(TimetableEntry other) {
    if (weekday != other.weekday) return false;
    if (!_periodsIntersect(other)) return false;
    final aStart = startMinutes;
    final aEnd = endMinutes;
    final bStart = other.startMinutes;
    final bEnd = other.endMinutes;
    if (aStart == null || aEnd == null || bStart == null || bEnd == null) {
      return false;
    }
    return aStart < bEnd && bStart < aEnd;
  }

  /// Two sessions describe the same class when every structural field matches.
  bool sameSessionAs(TimetableEntry other) =>
      courseCode.toUpperCase() == other.courseCode.toUpperCase() &&
      weekday == other.weekday &&
      _sameClock(startTime, startMinutes, other.startTime, other.startMinutes) &&
      _sameClock(endTime, endMinutes, other.endTime, other.endMinutes) &&
      slotNumber == other.slotNumber &&
      _periodsIntersect(other);

  /// '9:10' and '09:10' are the same time; malformed values fall back to text.
  static bool _sameClock(String a, int? aMinutes, String b, int? bMinutes) =>
      aMinutes != null && bMinutes != null ? aMinutes == bMinutes : a == b;

  /// Open-ended bounds (empty or null) extend to infinity. 'yyyy-MM-dd'
  /// compares correctly as a string.
  bool _periodsIntersect(TimetableEntry other) {
    final aStart = effectiveStart ?? '';
    final bStart = other.effectiveStart ?? '';
    final aEnd = effectiveEnd ?? '';
    final bEnd = other.effectiveEnd ?? '';
    if (aEnd.isNotEmpty && bStart.isNotEmpty && aEnd.compareTo(bStart) < 0) {
      return false;
    }
    if (bEnd.isNotEmpty && aStart.isNotEmpty && bEnd.compareTo(aStart) < 0) {
      return false;
    }
    return true;
  }

  TimetableEntry copyWith({
    String? id,
    String? courseCode,
    String? courseName,
    int? weekday,
    int? slotNumber,
    String? startTime,
    String? endTime,
    String? room,
    String? campus,
    String? lecturer,
    String? section,
    String? notes,
    int? semester,
    String? effectiveStart,
    String? effectiveEnd,
  }) => TimetableEntry(
    id: id ?? this.id,
    courseCode: courseCode ?? this.courseCode,
    courseName: courseName ?? this.courseName,
    weekday: weekday ?? this.weekday,
    slotNumber: slotNumber ?? this.slotNumber,
    startTime: startTime ?? this.startTime,
    endTime: endTime ?? this.endTime,
    room: room ?? this.room,
    campus: campus ?? this.campus,
    lecturer: lecturer ?? this.lecturer,
    section: section ?? this.section,
    notes: notes ?? this.notes,
    semester: semester ?? this.semester,
    effectiveStart: effectiveStart ?? this.effectiveStart,
    effectiveEnd: effectiveEnd ?? this.effectiveEnd,
  );

  /// Parses 'HH:mm' into minutes since midnight; null when malformed.
  static int? parseClock(String value) {
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value.trim());
    if (match == null) return null;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    if (hour > 23 || minute > 59) return null;
    return hour * 60 + minute;
  }

  static String formatClock(int minutes) =>
      '${(minutes ~/ 60).toString().padLeft(2, '0')}:'
      '${(minutes % 60).toString().padLeft(2, '0')}';

  /// Reads both the current schema and the legacy
  /// `{courseCode, weekday, startSlot, slotCount}` rows written before slots
  /// carried clock times. Legacy rows take their times from the sample slot
  /// catalog so old schedules still render in the weekly view.
  factory TimetableEntry.fromMap(Map<String, dynamic> map) {
    final courseCode = (map['courseCode']?.toString() ?? '').toUpperCase();
    final weekday = _int(map['weekday']) ?? 1;
    final startTime = map['startTime']?.toString() ?? '';
    final endTime = map['endTime']?.toString() ?? '';
    final slotNumber = _int(map['slotNumber']);
    if (startTime.isNotEmpty && endTime.isNotEmpty) {
      return TimetableEntry(
        id: _text(map['id']),
        courseCode: courseCode,
        courseName: _text(map['courseName']),
        weekday: weekday,
        slotNumber: slotNumber,
        startTime: startTime,
        endTime: endTime,
        room: _text(map['room']),
        campus: _text(map['campus']),
        lecturer: _text(map['lecturer']),
        section: _text(map['section']),
        notes: _text(map['notes']),
        semester: _int(map['semester']),
        effectiveStart: _text(map['effectiveStart']),
        effectiveEnd: _text(map['effectiveEnd']),
      );
    }
    // Legacy row: derive clock times from the slot catalog.
    final legacyStart = _int(map['startSlot']) ?? 1;
    final legacyCount = _int(map['slotCount']) ?? 1;
    final first = SlotCatalog.sampleDefault.byNumber(legacyStart);
    final last = SlotCatalog.sampleDefault.byNumber(
      legacyStart + (legacyCount < 1 ? 1 : legacyCount) - 1,
    );
    return TimetableEntry(
      courseCode: courseCode,
      courseName: _text(map['courseName']),
      weekday: weekday,
      slotNumber: legacyStart,
      startTime: first?.start ?? '07:30',
      endTime: last?.end ?? first?.end ?? '09:00',
      room: _text(map['room']),
      campus: _text(map['campus']),
      lecturer: _text(map['lecturer']),
      section: _text(map['section']),
      notes: _text(map['notes']),
      semester: _int(map['semester']),
      effectiveStart: _text(map['effectiveStart']),
      effectiveEnd: _text(map['effectiveEnd']),
    );
  }

  /// Tolerates a numeric or otherwise non-string stored value without losing
  /// the record, and treats null as empty.
  static String _text(Object? value) => value?.toString() ?? '';

  /// Accepts `int`, `double` and numeric strings from hand-edited documents.
  static int? _int(Object? value) => switch (value) {
    num() => value.toInt(),
    String() => int.tryParse(value.trim()),
    _ => null,
  };

  Map<String, dynamic> toMap() => {
    'id': id,
    'courseCode': courseCode,
    'courseName': courseName,
    'weekday': weekday,
    'slotNumber': slotNumber,
    'startTime': startTime,
    'endTime': endTime,
    'room': room,
    'campus': campus,
    'lecturer': lecturer,
    'section': section,
    'notes': notes,
    'semester': semester,
    'effectiveStart': effectiveStart,
    'effectiveEnd': effectiveEnd,
  };
}


/// A pair of sessions that occupy the same weekday and overlap in time.
class ScheduleConflict {
  const ScheduleConflict({required this.first, required this.second});

  final TimetableEntry first;
  final TimetableEntry second;

  String get description =>
      '${first.courseCode} ${first.startTime}–${first.endTime} trùng '
      '${second.courseCode} ${second.startTime}–${second.endTime} '
      '(${weekdayLabel(first.weekday)})';

  static String weekdayLabel(int weekday) =>
      weekday == 7 ? 'Chủ nhật' : 'Thứ ${weekday + 1}';
}

class AcademicProfile {
  const AcademicProfile({
    this.transcript = const [],
    this.timetable = const [],
    this.passedCourses = const {},
    this.currentSemester,
    this.targetGpa = 8,
  });
  final List<TranscriptEntry> transcript;
  final List<TimetableEntry> timetable;
  final Set<String> passedCourses;
  final int? currentSemester;

  /// Personal planning target, not a university classification rule.
  final double targetGpa;

  factory AcademicProfile.fromMap(Map<String, dynamic>? data) {
    final map = data ?? const <String, dynamic>{};
    return AcademicProfile(
      transcript: (map['transcript'] as List? ?? const [])
          .map(
            (e) => TranscriptEntry.fromMap(Map<String, dynamic>.from(e as Map)),
          )
          .toList(),
      // A null or non-map row is dropped instead of failing the whole profile,
      // so one corrupt document cannot hide the transcript and GPA.
      timetable: [
        for (final row in (map['timetable'] as List? ?? const []))
          if (row is Map)
            TimetableEntry.fromMap(Map<String, dynamic>.from(row)),
      ],
      passedCourses: (map['passedCourses'] as List? ?? const [])
          .map((e) => e.toString())
          .toSet(),
      currentSemester: (map['currentSemester'] as num?)?.toInt(),
      targetGpa: (map['targetGpa'] as num?)?.toDouble() ?? 8,
    );
  }

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
