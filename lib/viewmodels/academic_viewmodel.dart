import 'dart:async';

import '../models/academic_profile.dart';
import '../models/app_state.dart';
import '../models/course_model.dart';
import '../models/schedule_rules.dart';
import '../models/slot_catalog.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'base_viewmodel.dart';

class AcademicViewModel extends BaseViewModel<AcademicProfile> {
  AcademicViewModel({
    required this.authService,
    required this.firestoreService,
  }) {
    _authSub = authService.authStateChanges.listen((_) {
      if (_loadedUid != authService.currentUserId) {
        _plannedGrades.clear();
        _selectedSemester = null;
        _saving = false;
        _profile = const AcademicProfile();
        _courses = [];
        loadData();
      }
    });
    loadData();
  }
  final AuthService authService;
  final FirestoreService firestoreService;
  StreamSubscription<bool>? _authSub;
  String? _loadedUid;
  int _version = 0;
  bool _saving = false;
  AcademicProfile _profile = const AcademicProfile();
  List<CourseModel> _courses = [];
  final Map<String, double> _plannedGrades = {};
  AcademicProfile get profile => _profile;
  List<CourseModel> get courses => List.unmodifiable(_courses);
  bool get isSaving => _saving;
  List<CourseModel> get semesterCourses =>
      _courses.where((c) => c.semester == selectedSemester).toList();
  int? _selectedSemester;
  int? get selectedSemester =>
      _selectedSemester ??
      _profile.currentSemester ??
      (_courses.isEmpty
          ? null
          : _courses.map((c) => c.semester).reduce((a, b) => a > b ? a : b));
  List<int> get semesters =>
      _courses.map((c) => c.semester).toSet().toList()..sort();
  void selectSemester(int value) {
    _selectedSemester = value;
    notifyListeners();
  }

  double? plannedGrade(String courseCode) => _plannedGrades[courseCode];
  void setPlannedGrade(String courseCode, double? grade) {
    if (grade == null) {
      _plannedGrades.remove(courseCode);
    } else {
      _plannedGrades[courseCode] = grade.clamp(0, 10);
    }
    notifyListeners();
  }

  List<CourseModel> get plannedCourses =>
      semesterCourses.where((c) => _plannedGrades.containsKey(c.code)).toList();
  int get plannedCredits => plannedCourses.fold(0, (sum, c) => sum + c.credits);
  double? get plannedGpa => plannedCredits == 0
      ? null
      : plannedCourses.fold<double>(
              0,
              (sum, c) => sum + _plannedGrades[c.code]! * c.credits,
            ) /
            plannedCredits;

  List<String> missingPrerequisites(CourseModel course) => course.prerequisites
      .where((code) => !_profile.completedCodes.contains(code))
      .toList();
  bool isRetake(CourseModel course) =>
      _profile.transcript.any(
        (entry) => entry.courseCode == course.code && !entry.passed,
      ) &&
      !_profile.completedCodes.contains(course.code);

  // ── Class schedule ──────────────────────────────────────────────────────

  /// Central slot catalogue used by the editor and the weekly view.
  SlotCatalog get slotCatalog => SlotCatalog.sampleDefault;

  List<TimetableEntry> get timetable => _profile.timetable;

  List<TimetableEntry> sessionsFor(String courseCode) => _profile.timetable
      .where((e) => e.courseCode.toUpperCase() == courseCode.toUpperCase())
      .toList();

  /// Every overlap in the saved schedule, across all courses.
  List<ScheduleConflict> get allScheduleConflicts =>
      ScheduleRules.allConflicts(_profile.timetable);

  /// Overlaps that involve a course planned for [selectedSemester] — the check
  /// the strategy screen shows.
  List<String> get conflicts {
    final codes = plannedCourses.map((c) => c.code.toUpperCase()).toSet();
    return [
      for (final conflict in allScheduleConflicts)
        if (codes.contains(conflict.first.courseCode.toUpperCase()) ||
            codes.contains(conflict.second.courseCode.toUpperCase()))
          conflict.description,
    ];
  }

  /// Checks a candidate session against the persisted schedule without saving.
  List<ScheduleConflict> conflictsFor(TimetableEntry candidate) =>
      ScheduleRules.conflictsWith(candidate, _profile.timetable);

  bool isDuplicateSession(TimetableEntry candidate) =>
      ScheduleRules.isDuplicate(candidate, _profile.timetable);

  /// Adds one weekly session. Returns false (with [lastError]) when invalid,
  /// duplicated or persisted unsuccessfully.
  Future<bool> addSession(TimetableEntry entry) =>
      _mutateSchedule((list) => [...list, _withId(entry)]);

  Future<bool> updateSession(TimetableEntry entry) => _mutateSchedule(
    (list) => [
      for (final e in list)
        if (e.id == entry.id) entry else e,
    ],
  );

  Future<bool> deleteSession(String sessionId) => _mutateSchedule(
    (list) => [
      for (final e in list)
        if (e.id != sessionId) e,
    ],
  );

  /// Copies a session to the same course with a fresh id; the caller edits the
  /// copy's day/slot afterwards.
  Future<bool> duplicateSession(String sessionId) {
    TimetableEntry? source;
    for (final e in _profile.timetable) {
      if (e.id == sessionId) source = e;
    }
    if (source == null) {
      setLastError('Không tìm thấy buổi học để nhân bản.');
      return Future.value(false);
    }
    return _mutateSchedule((list) => [...list, _withId(source!.copyWith(id: ''))]);
  }

  /// Persists the whole timetable list after running [transform], so one
  /// session edit can never drop unrelated sessions.
  Future<bool> _mutateSchedule(
    List<TimetableEntry> Function(List<TimetableEntry>) transform,
  ) async {
    if (_saving) return false;
    final uid = authService.currentUserId;
    if (uid == null) {
      setLastError('Chưa đăng nhập.');
      return false;
    }
    final next = transform(_profile.timetable).map(_normalized).toList();
    for (final entry in next) {
      final errors = ScheduleRules.validate(
        courseCode: entry.courseCode,
        courseName: entry.courseName,
        weekday: entry.weekday,
        slotNumber: entry.slotNumber,
        startTime: entry.startTime,
        endTime: entry.endTime,
        catalog: slotCatalog,
        effectiveStart: entry.effectiveStart,
        effectiveEnd: entry.effectiveEnd,
        requireName: false,
      );
      if (errors.isNotEmpty) {
        setLastError(errors.values.first);
        return false;
      }
    }
    _saving = true;
    clearLastError();
    notifyListeners();
    try {
      await firestoreService.saveAcademicProfile(uid, {
        'timetable': next.map((e) => e.toMap()).toList(),
        'scheduleUpdatedAt': DateTime.now().toIso8601String(),
      });
      if (isDisposed || uid != authService.currentUserId) return false;
      _profile = AcademicProfile(
        transcript: _profile.transcript,
        timetable: next,
        passedCourses: _profile.passedCourses,
        currentSemester: _profile.currentSemester,
        targetGpa: _profile.targetGpa,
      );
      return true;
    } catch (e) {
      setLastError('Không lưu được thời khóa biểu. Kiểm tra kết nối và thử lại.');
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  /// Ids are assigned in memory (never written on load) so legacy sessions
  /// become editable/deletable; the next schedule write persists them.
  AcademicProfile _withMigratedIds(AcademicProfile profile) {
    if (profile.timetable.every((e) => e.id.isNotEmpty)) return profile;
    return AcademicProfile(
      transcript: profile.transcript,
      timetable: [for (final e in profile.timetable) _withId(e)],
      passedCourses: profile.passedCourses,
      currentSemester: profile.currentSemester,
      targetGpa: profile.targetGpa,
    );
  }

  int _idSeed = 0;

  /// Stores times as canonical 'HH:mm' (the editor accepts '9:10') so conflict
  /// and duplicate checks compare one format.
  static TimetableEntry _normalized(TimetableEntry entry) {
    if (!entry.hasValidRange) return entry;
    final start = TimetableEntry.formatClock(entry.startMinutes!);
    final end = TimetableEntry.formatClock(entry.endMinutes!);
    return start == entry.startTime && end == entry.endTime
        ? entry
        : entry.copyWith(startTime: start, endTime: end);
  }

  TimetableEntry _withId(TimetableEntry entry) => entry.id.isNotEmpty
      ? entry
      : entry.copyWith(
          id: 's${DateTime.now().microsecondsSinceEpoch}_${_idSeed++}',
        );

  @override
  Future<void> loadData() async {
    final version = ++_version;
    final uid = authService.currentUserId;
    _loadedUid = uid;
    setState(const AsyncViewState.loading());
    if (uid == null) {
      _profile = const AcademicProfile();
      _courses = [];
      setState(const AsyncViewState.empty());
      return;
    }
    try {
      final profile = await firestoreService.getUserProfile(uid);
      final courses = await firestoreService.getCourses(uid);
      if (isDisposed ||
          version != _version ||
          uid != authService.currentUserId) {
        return;
      }
      _profile = _withMigratedIds(AcademicProfile.fromMap(profile));
      _courses = courses.map(CourseModel.fromMap).toList();
      setState(AsyncViewState.data(_profile));
    } catch (e) {
      if (isDisposed ||
          version != _version ||
          uid != authService.currentUserId) {
        return;
      }
      setState(
        const AsyncViewState.error(
          'Không tải được dữ liệu học tập. Kiểm tra kết nối và thử lại.',
        ),
      );
    }
  }

  /// Format is explicit and validation happens before any Firestore mutation.
  /// Each transcript row: code,credits,grade,semester,passed(true/false).
  static List<TranscriptEntry> parseTranscript(String input) {
    final result = <TranscriptEntry>[];
    final seen = <String>{};
    for (final row
        in input.split('\n').where((line) => line.trim().isNotEmpty)) {
      final p = row.split(',').map((s) => s.trim()).toList();
      if (p.length != 5) {
        throw const FormatException(
          'Bảng điểm: mỗi dòng cần mã môn,tín chỉ,điểm,kỳ,đã qua(true/false).',
        );
      }
      final credits = int.tryParse(p[1]);
      final grade = double.tryParse(p[2]);
      final semester = int.tryParse(p[3]);
      if (p[0].isEmpty ||
          credits == null ||
          credits <= 0 ||
          grade == null ||
          !grade.isFinite ||
          grade < 0 ||
          grade > 10 ||
          semester == null ||
          semester <= 0 ||
          !['true', 'false'].contains(p[4].toLowerCase())) {
        throw const FormatException(
          'Bảng điểm có giá trị không hợp lệ. Điểm 0–10, tín chỉ/kỳ là số nguyên dương.',
        );
      }
      if (!seen.add(p[0].toUpperCase())) {
        throw const FormatException(
          'Mỗi môn chỉ nhập một kết quả hiện hành; xử lý học lại theo bảng điểm chính thức.',
        );
      }
      result.add(
        TranscriptEntry(
          courseCode: p[0].toUpperCase(),
          credits: credits,
          grade: grade,
          semester: semester,
          passed: p[4].toLowerCase() == 'true',
        ),
      );
    }
    return result;
  }

  /// Each timetable row: code,ISO weekday,startSlot,slotCount.
  /// Superseded by the session editor; kept so old pasted schedules still parse
  /// and migrate into [TimetableEntry]s with catalog-derived clock times.
  static List<TimetableEntry> parseTimetable(String input) {
    return input.split('\n').where((line) => line.trim().isNotEmpty).map((row) {
      final p = row.split(',').map((s) => s.trim()).toList();
      if (p.length != 4) {
        throw const FormatException(
          'Lịch học: mã môn,thứ ISO(1=T2…7=CN),slot đầu,số slot.',
        );
      }
      final day = int.tryParse(p[1]);
      final start = int.tryParse(p[2]);
      final count = int.tryParse(p[3]);
      if (p[0].isEmpty ||
          day == null ||
          day < 1 ||
          day > 7 ||
          start == null ||
          start < 1 ||
          count == null ||
          count < 1) {
        throw const FormatException(
          'Lịch học không hợp lệ. Thứ ISO 1–7; slot và số slot là số nguyên dương.',
        );
      }
      return TimetableEntry.fromMap({
        'courseCode': p[0].toUpperCase(),
        'weekday': day,
        'startSlot': start,
        'slotCount': count,
      });
    }).toList();
  }

  String get transcriptText => _profile.transcript
      .map(
        (e) =>
            '${e.courseCode},${e.credits},${e.grade},${e.semester},${e.passed}',
      )
      .join('\n');
  String get timetableText => _profile.timetable
      .map(
        (e) =>
            '${e.courseCode},${e.weekday},${e.startTime},${e.endTime}',
      )
      .join('\n');

  /// Saves transcript/goal only. The timetable has its own operations
  /// ([addSession], [updateSession], [deleteSession]) so this write can never
  /// overwrite schedule edits made in between.
  Future<bool> save({
    required String transcript,
    required int semester,
    required double targetGpa,
  }) async {
    if (_saving) return false;
    final uid = authService.currentUserId;
    if (uid == null) {
      setLastError('Chưa đăng nhập.');
      return false;
    }
    try {
      final grades = parseTranscript(transcript);
      if (semester < 1 ||
          !targetGpa.isFinite ||
          targetGpa < 0 ||
          targetGpa > 10) {
        throw const FormatException('Kỳ học hoặc mục tiêu GPA không hợp lệ.');
      }
      _saving = true;
      clearLastError();
      notifyListeners();
      await firestoreService.saveAcademicProfile(uid, {
        'transcript': grades.map((e) => e.toMap()).toList(),
        'currentSemester': semester,
        'targetGpa': targetGpa,
        'academicDataSource': 'user_entered',
      });
      if (isDisposed || uid != authService.currentUserId) return false;
      _selectedSemester = semester;
      await loadData();
      return state.state == ViewState.data;
    } on FormatException catch (e) {
      setLastError(e.message);
      return false;
    } catch (e) {
      if (uid == authService.currentUserId) {
        setLastError('Không lưu được dữ liệu. Kiểm tra kết nối và thử lại.');
      }
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _version++;
    _authSub?.cancel();
    super.dispose();
  }
}
