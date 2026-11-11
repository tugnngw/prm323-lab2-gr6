import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/app_state.dart';
import '../models/academic_profile.dart';
import '../models/course_model.dart';
import '../models/course_progress.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'base_viewmodel.dart';

class RoadmapViewModel extends BaseViewModel<List<CourseModel>> {
  RoadmapViewModel({
    this.authService,
    this.firestoreService,
    this.analyticsService,
  }) {
    loadData();
    // passedCourses is user-scoped: on logout the roadmap must drop back to
    // "no transcript" instead of showing the previous user's results.
    // Guard on uid change so a stream replay cannot race a concurrent load.
    _authSub = authService?.authStateChanges.listen((_) {
      if (currentUserId != _loadedUid) loadData();
    });
  }

  final AuthService? authService;
  final FirestoreService? firestoreService;
  final AnalyticsService? analyticsService;
  StreamSubscription<bool>? _authSub;
  int _loadVersion = 0;
  String? _loadedUid;

  /// Authenticated UID, or null when no identity is available. Used for the
  /// user-owned course read; never falls back to a persona ID or constant.
  String? get currentUserId {
    final uid = authService?.currentUserId;
    return (uid == null || uid.isEmpty) ? null : uid;
  }

  List<CourseModel> _allCourses = [];
  String _searchQuery = '';
  bool _filterPrerequisitesOnly = false;
  int _selectedSemester = 5;
  bool _semesterPickedByUser = false;
  String _selectedMajor = '';
  int _totalSemesters = 9;
  List<MajorModel> _availableMajors = const [];

  // Passed-course transcript, loaded from the signed-in user's Firestore
  // profile (`users/{uid}.passedCourses`). Empty until loaded — an empty
  // transcript means "no prerequisites satisfied", never seeded demo data.
  Set<String> _passedCourses = {};

  // `users/{uid}/courseProgress/*` keyed by course document id.
  Map<String, CourseProgress> _progress = {};

  // ── Semester 5 course catalog ──
  // The catalog is Firestore-only now (no mockdata fallback). Staff import the
  // real FLM curriculum from the web admin; an empty collection surfaces as the
  // empty state below.

  /// Document id used for per-student progress rows. Legacy catalog entries
  /// can lack `id`, so derive the same `major__code` shape the importer uses.
  static String courseDocIdOf(CourseModel course) => course.id.isNotEmpty
      ? course.id
      : (course.major.isEmpty
            ? course.code
            : '${course.major}__${course.code}');

  /// Parses `users/{uid}` profile into the passed-course set.
  /// Codes are normalized to upper case so FLM variants such as `DMS301m`
  /// and user-entered `DMS301M` satisfy the same prerequisite.
  static Set<String> parsePassedCourses(Map<String, dynamic>? profile) {
    return AcademicProfile.fromMap(profile).completedCodes
        .map((code) => code.trim().toUpperCase())
        .where((code) => code.isNotEmpty)
        .toSet();
  }

  // Getters
  List<CourseModel> get allCourses => List.unmodifiable(_allCourses);
  String get searchQuery => _searchQuery;
  bool get filterPrerequisitesOnly => _filterPrerequisitesOnly;
  int get selectedSemester => _selectedSemester;
  Set<String> get passedCourses => Set.unmodifiable(_passedCourses);
  String get selectedMajor => _selectedMajor;
  String get selectedMajorName {
    final match = _availableMajors.where(
      (m) => m.code.toUpperCase() == _selectedMajor.toUpperCase(),
    );
    if (match.isNotEmpty && match.first.name.trim().isNotEmpty) {
      return match.first.name.trim();
    }
    return _selectedMajor;
  }

  int get majorCourseCount => _allCourses.where((course) {
    if (_selectedMajor.isEmpty) return true;
    if (course.major.isEmpty) return true;
    return course.major.toUpperCase() == _selectedMajor.toUpperCase();
  }).length;
  int get totalSemesters => _totalSemesters;
  List<int> get availableSemesters =>
      List.generate(_totalSemesters, (i) => i + 1);
  List<MajorModel> get availableMajors => List.unmodifiable(_availableMajors);

  /// Changes the curriculum from the roadmap selector. Persists the choice and
  /// reloads only the new major's courses; the semester default is recalculated
  /// from that curriculum.
  Future<void> selectMajor(String major) async {
    final normalized = major.trim();
    if (normalized.isEmpty) return;
    if (_selectedMajor.toUpperCase() == normalized.toUpperCase()) return;
    final previous = _selectedMajor;
    _selectedMajor = normalized;
    _semesterPickedByUser = false;
    setState(const AsyncViewState.loading());

    final firestore = firestoreService;
    final uid = currentUserId;
    if (firestore == null || uid == null) {
      await loadData();
      return;
    }
    try {
      await firestore.saveAcademicProfile(uid, {'major': normalized});
    } catch (e) {
      if (isDisposed) return;
      _selectedMajor = previous;
      setState(AsyncViewState.error('Không đổi được chuyên ngành: $e'));
      return;
    }
    await loadData();
  }

  List<CourseModel> get filteredCourses {
    return _allCourses.where((course) {
      // Semester filter
      if (course.semester != _selectedSemester) return false;

      // Major filter (relaxed: match major if specified on both side)
      if (_selectedMajor.isNotEmpty &&
          course.major.isNotEmpty &&
          course.major.toUpperCase() != _selectedMajor.toUpperCase()) {
        return false;
      }

      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final matchCode = course.code.toLowerCase().contains(query);
        final matchName = course.name.toLowerCase().contains(query);
        if (!matchCode && !matchName) return false;
      }

      // Prerequisite filter
      if (_filterPrerequisitesOnly) {
        if (course.prerequisites.isEmpty && course.prerequisiteNote.isEmpty) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  @override
  Future<void> loadData() async {
    if (isDisposed) return;
    final version = ++_loadVersion;
    final uid = currentUserId;
    if (uid != _loadedUid) {
      // New identity: never inherit the previous student's major/semester.
      _selectedMajor = '';
      _semesterPickedByUser = false;
      _progress = {};
    }
    setState(const AsyncViewState.loading());

    try {
      final firestore = firestoreService;
      _loadedUid = uid;
      if (firestore == null || uid == null) {
        // No backend / no identity: show the empty state. Never fall back to
        // seeded mock courses (Lab 3 §1.4 fail-loud, no mockdata).
        _allCourses = [];
        _passedCourses = {};
        _progress = {};
        setState(const AsyncViewState.empty());
        return;
      }

      // Transcript drives prerequisite checks; courses come from Firestore.
      final profileDoc = await firestore.getUserProfile(uid);
      if (isDisposed || version != _loadVersion || uid != currentUserId) return;
      final passed = parsePassedCourses(profileDoc);
      final profileMajor = profileDoc?['major'] as String?;
      if (profileMajor != null && profileMajor.isNotEmpty) {
        _selectedMajor = profileMajor;
      }
      try {
        final remoteMajors = await firestore.getMajors();
        _availableMajors = remoteMajors.map(MajorModel.fromMap).toList();
      } catch (_) {}
      final activeMatches = _availableMajors.where(
        (m) => m.code.toUpperCase() == _selectedMajor.toUpperCase(),
      );
      if (activeMatches.isNotEmpty) {
        _totalSemesters = activeMatches.first.totalSemesters;
      }

      // Only the selected curriculum is downloaded. A student with no major
      // yet is stopped by the onboarding gate and gets no catalog at all.
      final docs = _selectedMajor.isEmpty
          ? const <Map<String, dynamic>>[]
          : await firestore.getCoursesForMajor(_selectedMajor);
      if (isDisposed || version != _loadVersion || uid != currentUserId) return;
      _passedCourses = passed;
      _allCourses = docs.map(CourseModel.fromMap).toList();

      // Per-student slot progress + lecturer. A read failure must not take the
      // whole roadmap down: fall back to "nothing completed yet".
      try {
        final progressRows = await firestore.getCourseProgress(uid);
        if (isDisposed || version != _loadVersion || uid != currentUserId) {
          return;
        }
        final loaded = <String, CourseProgress>{};
        for (final row in progressRows) {
          final progress = CourseProgress.fromMap(row);
          if (progress.courseDocId.isNotEmpty) {
            loaded[progress.courseDocId] = progress;
          }
        }
        _progress = loaded;
      } catch (_) {
        _progress = {};
      }

      // The majors collection can be unreadable/empty while courses still
      // carry a `major` code, so derive a selectable major from the catalog.
      if (_availableMajors.isEmpty && _allCourses.isNotEmpty) {
        final codes = <String>{
          for (final course in _allCourses)
            if (course.major.trim().isNotEmpty) course.major.trim(),
        };
        _availableMajors =
            codes
                .map(
                  (code) => MajorModel(
                    code: code,
                    name: code,
                    totalSemesters: _allCourses
                        .where(
                          (c) => c.major.toUpperCase() == code.toUpperCase(),
                        )
                        .fold<int>(
                          1,
                          (max, c) => c.semester > max ? c.semester : max,
                        ),
                  ),
                )
                .toList()
              ..sort((a, b) => a.code.compareTo(b.code));
      }

      if (!_semesterPickedByUser) {
        final profileSemester = (profileDoc?['currentSemester'] as num?)
            ?.toInt();
        if (profileSemester != null && profileSemester >= 1) {
          _selectedSemester = profileSemester;
        }
        final majorSemesters = _allCourses
            .where(
              (c) =>
                  _selectedMajor.isEmpty ||
                  c.major.isEmpty ||
                  c.major.toUpperCase() == _selectedMajor.toUpperCase(),
            )
            .map((c) => c.semester)
            .where((s) => s > 0)
            .toSet();
        if (majorSemesters.isNotEmpty &&
            !majorSemesters.contains(_selectedSemester)) {
          _selectedSemester = majorSemesters.reduce((a, b) => a < b ? a : b);
        }
      }
      if (_selectedSemester > _totalSemesters) {
        _selectedSemester = _totalSemesters;
      }

      if (_allCourses.isEmpty) {
        setState(const AsyncViewState.empty());
      } else {
        setState(AsyncViewState.data(filteredCourses));
      }
    } catch (e) {
      if (isDisposed || version != _loadVersion || uid != currentUserId) return;
      setState(AsyncViewState.error('Không thể tải lộ trình môn học: $e'));
    }
  }

  Timer? _searchDebounce;

  void setSearchQuery(String query) {
    _searchQuery = query;
    setState(AsyncViewState.data(filteredCourses));
    // Log one search_course per settled query, not per keystroke.
    _searchDebounce?.cancel();
    if (query.trim().isNotEmpty) {
      _searchDebounce = Timer(const Duration(milliseconds: 600), () {
        if (_searchQuery == query) logSearch(query);
      });
    }
  }

  void togglePrerequisiteFilter() {
    _filterPrerequisitesOnly = !_filterPrerequisitesOnly;
    setState(AsyncViewState.data(filteredCourses));
  }

  void selectSemester(int semester) {
    _selectedSemester = semester;
    _semesterPickedByUser = true;
    setState(AsyncViewState.data(filteredCourses));
  }

  /// Checks if the signed-in student satisfies all prerequisites for [course].
  /// Pure predicate — safe to call from `build` (no side effects).
  bool isEligibleForCourse(CourseModel course) {
    if (course.prerequisites.isEmpty) return true;
    return course.prerequisites.every(
      (code) => _passedCourses.contains(code.trim().toUpperCase()),
    );
  }

  /// Explicit prerequisite check invoked from a user action; logs the
  /// `prerequisite_check` event exactly once per tap (not per rebuild).
  bool checkEligibilityForCourse(CourseModel course) {
    final isEligible = isEligibleForCourse(course);
    analyticsService?.logPrerequisiteCheck(
      courseId: course.id,
      isEligible: isEligible,
    );
    return isEligible;
  }

  /// Returns missing prerequisites for [course]
  List<String> getMissingPrerequisites(CourseModel course) => course
      .prerequisites
      .where((code) => !_passedCourses.contains(code.trim().toUpperCase()))
      .toList();

  /// Course catalog for any major, used by pickers in Tasks/Notes. The active
  /// major comes from memory; other majors are fetched on demand.
  Future<List<CourseModel>> coursesForMajor(String major) async {
    final normalized = major.trim();
    if (normalized.isEmpty) return const [];
    if (_selectedMajor.toUpperCase() == normalized.toUpperCase() &&
        _allCourses.isNotEmpty) {
      return List.unmodifiable(_allCourses);
    }
    final firestore = firestoreService;
    if (firestore == null) {
      return _allCourses
          .where(
            (c) =>
                c.major.isEmpty ||
                c.major.toUpperCase() == normalized.toUpperCase(),
          )
          .toList();
    }
    try {
      final rows = await firestore.getCoursesForMajor(normalized);
      return rows.map(CourseModel.fromMap).toList();
    } catch (_) {
      return const [];
    }
  }

  // ── Per-student slot progress & lecturer ──

  int slotCountOf(CourseModel course) =>
      course.totalSlots > 0 ? course.totalSlots : course.slots.length;

  CourseProgress progressFor(CourseModel course) {
    final docId = courseDocIdOf(course);
    return _progress[docId] ?? CourseProgress(courseDocId: docId);
  }

  Set<int> completedSlotsFor(CourseModel course) =>
      progressFor(course).completedSlotNumbers;

  int completedSlotCount(CourseModel course) =>
      progressFor(course).completedCount(slotCountOf(course));

  double slotProgress(CourseModel course) =>
      progressFor(course).progress(slotCountOf(course));

  bool isCourseCompleted(CourseModel course) =>
      progressFor(course).courseCompleted;

  bool isSlotCompleted(CourseModel course, int slotNumber) =>
      progressFor(course).isSlotCompleted(slotNumber);

  String lecturerFor(CourseModel course) {
    final personal = progressFor(course).lecturer.trim();
    return personal.isNotEmpty ? personal : course.lecturer.trim();
  }

  Future<bool> setSlotCompleted(
    CourseModel course,
    int slotNumber, {
    required bool completed,
  }) {
    final current = progressFor(course);
    final total = slotCountOf(course);
    Set<int> slots;
    if (current.courseCompleted) {
      // Un-ticking one slot on a fully-completed course must keep the rest.
      slots = {for (var i = 1; i <= total; i++) i}..remove(slotNumber);
      if (completed) slots.add(slotNumber);
    } else {
      slots = {...current.completedSlotNumbers};
      if (completed) {
        slots.add(slotNumber);
      } else {
        slots.remove(slotNumber);
      }
    }
    slots = slots.where((n) => n >= 1 && (total <= 0 || n <= total)).toSet();
    return _writeProgress(
      course,
      current.copyWith(completedSlotNumbers: slots, courseCompleted: false),
    );
  }

  Future<bool> setCourseCompleted(
    CourseModel course, {
    required bool completed,
  }) {
    final current = progressFor(course);
    final total = slotCountOf(course);
    return _writeProgress(
      course,
      current.copyWith(
        courseCompleted: completed,
        completedSlotNumbers: completed
            ? {for (var i = 1; i <= total; i++) i}
            : <int>{},
      ),
    );
  }

  Future<bool> resetCourseProgress(CourseModel course) {
    final current = progressFor(course);
    return _writeProgress(
      course,
      current.copyWith(courseCompleted: false, completedSlotNumbers: <int>{}),
    );
  }

  Future<bool> saveCourseLecturer(CourseModel course, String lecturer) {
    final current = progressFor(course);
    return _writeProgress(course, current.copyWith(lecturer: lecturer.trim()));
  }

  /// Optimistically writes one progress row, reverting on failure so the UI
  /// never claims a save that Firestore rejected.
  Future<bool> _writeProgress(CourseModel course, CourseProgress next) async {
    final firestore = firestoreService;
    final uid = currentUserId;
    if (firestore == null || uid == null) {
      setLastError('Bạn chưa đăng nhập — không thể lưu tiến độ môn học.');
      return false;
    }
    final docId = courseDocIdOf(course);
    final previous = _progress[docId];
    _progress = {..._progress, docId: next};
    clearLastError();
    setState(AsyncViewState.data(filteredCourses));
    try {
      await firestore.saveCourseProgress(uid, docId, next.toMap());
      return true;
    } catch (e) {
      if (isDisposed || uid != currentUserId) return false;
      debugPrint('[Roadmap] progress write failed: ${e.runtimeType}: $e');
      final reverted = {..._progress};
      if (previous == null) {
        reverted.remove(docId);
      } else {
        reverted[docId] = previous;
      }
      _progress = reverted;
      setState(AsyncViewState.data(filteredCourses));
      setLastError(_progressWriteError(e));
      return false;
    }
  }

  /// Turns a Firestore/service failure into one actionable line. The exact
  /// error code is kept so a stale deployed ruleset is recognisable.
  static String _progressWriteError(Object error) {
    if (error is FirebaseException) {
      switch (error.code) {
        case 'permission-denied':
          return 'Firestore từ chối quyền ghi (permission-denied). Quy tắc bảo mật trên máy chủ chưa có courseProgress — cần triển khai lại firebase/firestore.rules.';
        case 'unauthenticated':
          return 'Phiên đăng nhập đã hết hạn (unauthenticated). Hãy đăng nhập lại.';
        case 'unavailable':
          return 'Không kết nối được Firestore (unavailable). Kiểm tra mạng rồi thử lại.';
        case 'deadline-exceeded':
          return 'Firestore phản hồi quá lâu (deadline-exceeded). Thử lại.';
        case 'failed-precondition':
          return 'Firestore báo failed-precondition — thường do App Check hoặc cấu hình dự án.';
        default:
          return 'Firestore báo lỗi ${error.code}.';
      }
    }
    return 'Không lưu được tiến độ: $error';
  }

  /// Pure lookup — no analytics side effect (events must not fire from `build`).
  CourseModel? findCourseById(String courseId) {
    for (final course in _allCourses) {
      if (course.id == courseId) return course;
    }
    final code = courseId.toUpperCase();
    final byCode = _allCourses
        .where((course) => course.code.toUpperCase() == code)
        .toList();
    if (byCode.isEmpty) return null;
    final preferred = byCode.where(
      (course) => course.major.toUpperCase() == _selectedMajor.toUpperCase(),
    );
    return preferred.isNotEmpty ? preferred.first : byCode.first;
  }

  /// Called once when a student submits a community experience note.
  void logExperienceNoteSubmitted(CourseModel course) {
    analyticsService?.logEvent(
      'experience_note_submit',
      parameters: {'course_code': course.code, 'major': course.major},
    );
  }

  /// Called once when Course Detail opens; logs `course_view`.
  void logCourseOpened(String courseId) {
    final course = findCourseById(courseId);
    if (course == null) return;
    analyticsService?.logCourseView(courseId: course.id, code: course.code);
  }

  /// Called when a search is committed (debounced by the view); logs
  /// `search_course` once per query, not per keystroke.
  void logSearch(String query) {
    if (query.trim().isEmpty) return;
    analyticsService?.logSearchCourse(query: query);
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
