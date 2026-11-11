import 'dart:async';

import '../models/academic_profile.dart';
import '../models/app_state.dart';
import '../models/course_model.dart';
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
  List<MajorModel> _availableMajors = const [];
  final Map<String, double> _plannedGrades = {};
  AcademicProfile get profile => _profile;
  List<CourseModel> get courses => List.unmodifiable(_courses);
  List<MajorModel> get availableMajors => List.unmodifiable(_availableMajors);
  bool get isSaving => _saving;

  /// Number of semesters in the selected curriculum, used by the transcript
  /// semester picker instead of asking the student to type it.
  int get majorTotalSemesters {
    final major = _profile.major.trim().toUpperCase();
    final match = _availableMajors.where(
      (m) => m.code.toUpperCase() == major,
    );
    if (match.isNotEmpty) return match.first.totalSemesters;
    final fromCourses = _courses.fold<int>(
      0,
      (max, course) => course.semester > max ? course.semester : max,
    );
    return fromCourses > 0 ? fromCourses : 9;
  }
  List<CourseModel> get majorCourses {
    final major = _profile.major.trim().toUpperCase();
    if (major.isEmpty) return _courses;
    return _courses
        .where((c) => c.major.isEmpty || c.major.toUpperCase() == major)
        .toList();
  }

  List<CourseModel> get semesterCourses => majorCourses
      .where((c) => c.semester == selectedSemester)
      .toList();
  int? _selectedSemester;
  int? get selectedSemester =>
      _selectedSemester ??
      _profile.currentSemester ??
      (majorCourses.isEmpty
          ? null
          : majorCourses
              .map((c) => c.semester)
              .reduce((a, b) => a > b ? a : b));
  List<int> get semesters =>
      majorCourses.map((c) => c.semester).toSet().toList()..sort();
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

  List<String> missingPrerequisites(CourseModel course) {
    final completed = _profile.completedCodes
        .map((code) => code.trim().toUpperCase())
        .toSet();
    return course.prerequisites
        .where((code) => !completed.contains(code.trim().toUpperCase()))
        .toList();
  }

  bool isRetake(CourseModel course) {
    final code = course.code.trim().toUpperCase();
    final completed = _profile.completedCodes
        .map((entry) => entry.trim().toUpperCase())
        .toSet();
    return _profile.transcript.any(
          (entry) =>
              entry.courseCode.trim().toUpperCase() == code && !entry.passed,
        ) &&
        !completed.contains(code);
  }

  /// Component scores the student already saved for [courseCode], keyed by
  /// assessment id from the FLM syllabus.
  Map<String, double> componentScoresFor(String courseCode) =>
      Map<String, double>.from(
        _profile.componentScores[courseCode.trim().toUpperCase()] ?? const {},
      );

  static double totalWeight(CourseModel course) => course.labs.fold<double>(
    0,
    (sum, lab) => (lab.weight ?? 0) > 0 ? sum + lab.weight! : sum,
  );

  /// Weighted average on the 0–10 scale. Returns null until every assessment
  /// with a positive weight has a score — a partial average would mislead.
  static double? weightedTotal(
    CourseModel course,
    Map<String, double> scores,
  ) {
    var weighted = 0.0;
    var weights = 0.0;
    for (final lab in course.labs) {
      final weight = lab.weight ?? 0;
      if (weight <= 0) continue;
      final score = scores[lab.id];
      if (score == null) return null;
      weighted += score * weight;
      weights += weight;
    }
    if (weights <= 0) return null;
    return weighted / weights;
  }

  /// Saves component scores for [course]. When [applyToTranscript] is set, the
  /// weighted total is also written as the course grade (pass = total >= 5),
  /// because the student explicitly asked to record it.
  Future<bool> saveComponentScores({
    required CourseModel course,
    required Map<String, double> scores,
    bool applyToTranscript = false,
  }) async {
    if (_saving) return false;
    final uid = authService.currentUserId;
    if (uid == null) {
      setLastError('Chưa đăng nhập.');
      return false;
    }
    final code = course.code.trim().toUpperCase();
    for (final score in scores.values) {
      if (!score.isFinite || score < 0 || score > 10) {
        setLastError('Điểm thành phần phải nằm trong khoảng 0–10.');
        return false;
      }
    }
    final total = weightedTotal(course, scores);
    if (applyToTranscript && total == null) {
      setLastError(
        'Cần nhập đủ điểm các đầu điểm có trọng số trước khi ghi vào bảng điểm.',
      );
      return false;
    }
    try {
      _saving = true;
      clearLastError();
      notifyListeners();
      final merged = <String, Map<String, double>>{
        ..._profile.componentScores,
        code: Map<String, double>.from(scores),
      };
      await firestoreService.saveComponentScores(
        uid,
        merged.map(
          (key, value) => MapEntry(key, Map<String, double>.from(value)),
        ),
      );
      var transcript = _profile.transcript;
      if (applyToTranscript && total != null) {
        final existingIndex = transcript.indexWhere(
          (entry) => entry.courseCode.trim().toUpperCase() == code,
        );
        final existing = existingIndex == -1 ? null : transcript[existingIndex];
        final entry = TranscriptEntry(
          courseCode: code,
          credits: existing?.credits ??
              (course.credits > 0 ? course.credits : 3),
          grade: (total * 100).round() / 100,
          semester: existing?.semester ??
              _profile.currentSemester ??
              (course.semester > 0 ? course.semester : 1),
          passed: total >= 5,
        );
        transcript = [...transcript];
        if (existingIndex == -1) {
          transcript.add(entry);
        } else {
          transcript[existingIndex] = entry;
        }
        await firestoreService.saveAcademicProfile(uid, {
          'transcript': transcript.map((e) => e.toMap()).toList(),
          'academicDataSource': 'user_entered',
        });
      }
      if (isDisposed || uid != authService.currentUserId) return false;
      _profile = _profile.copyWith(
        componentScores: merged,
        transcript: transcript,
      );
      setState(AsyncViewState.data(_profile));
      return true;
    } catch (e) {
      if (uid == authService.currentUserId) {
        setLastError(
          'Không lưu được điểm thành phần. Kiểm tra kết nối và thử lại.',
        );
      }
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
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
      if (isDisposed ||
          version != _version ||
          uid != authService.currentUserId) {
        return;
      }
      _profile = AcademicProfile.fromMap(profile);
      try {
        final remoteMajors = await firestoreService.getMajors();
        _availableMajors = remoteMajors.map(MajorModel.fromMap).toList();
      } catch (_) {}
      // No major yet: the student must pick one first, so do not download any
      // course catalog. Once picked, only that curriculum is fetched.
      final major = _profile.major.trim();
      final courses = major.isEmpty
          ? const <Map<String, dynamic>>[]
          : await firestoreService.getCoursesForMajor(major);
      if (isDisposed ||
          version != _version ||
          uid != authService.currentUserId) {
        return;
      }
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

  String get transcriptText => _profile.transcript
      .map(
        (e) =>
            '${e.courseCode},${e.credits},${e.grade},${e.semester},${e.passed}',
      )
      .join('\n');

  /// Records a course-level grade immediately, so satisfying a prerequisite
  /// does not require going through the whole transcript form first.
  Future<bool> recordCourseGrade({
    required String courseCode,
    required double grade,
    int credits = 0,
    int? semester,
  }) async {
    if (_saving) return false;
    final uid = authService.currentUserId;
    if (uid == null) {
      setLastError('Chưa đăng nhập.');
      return false;
    }
    final code = courseCode.trim().toUpperCase();
    if (code.isEmpty || !grade.isFinite || grade < 0 || grade > 10) {
      setLastError('Điểm phải nằm trong khoảng 0–10.');
      return false;
    }
    final catalog = _courses
        .where((c) => c.code.trim().toUpperCase() == code)
        .toList();
    final catalogCourse = catalog.isEmpty ? null : catalog.first;
    try {
      _saving = true;
      clearLastError();
      notifyListeners();
      final transcript = [..._profile.transcript];
      final index = transcript.indexWhere(
        (entry) => entry.courseCode.trim().toUpperCase() == code,
      );
      final existing = index == -1 ? null : transcript[index];
      final entry = TranscriptEntry(
        courseCode: code,
        credits: existing?.credits ??
            (credits > 0 ? credits : (catalogCourse?.credits ?? 3)),
        grade: (grade * 100).round() / 100,
        semester: existing?.semester ??
            semester ??
            _profile.currentSemester ??
            (catalogCourse?.semester ?? 1),
        passed: grade >= 5,
      );
      if (index == -1) {
        transcript.add(entry);
      } else {
        transcript[index] = entry;
      }
      await firestoreService.saveAcademicProfile(uid, {
        'transcript': transcript.map((e) => e.toMap()).toList(),
        'academicDataSource': 'user_entered',
      });
      if (isDisposed || uid != authService.currentUserId) return false;
      _profile = _profile.copyWith(transcript: transcript);
      setState(AsyncViewState.data(_profile));
      return true;
    } catch (_) {
      if (uid == authService.currentUserId) {
        setLastError('Không lưu được điểm. Kiểm tra kết nối và thử lại.');
      }
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  /// Clears the stored major so the onboarding gate asks again. Transcript and
  /// component scores are preserved.
  Future<bool> resetMajor() async {
    if (_saving) return false;
    final uid = authService.currentUserId;
    if (uid == null) {
      setLastError('Chưa đăng nhập.');
      return false;
    }
    try {
      _saving = true;
      clearLastError();
      notifyListeners();
      await firestoreService.saveAcademicProfile(uid, {'major': ''});
      if (isDisposed || uid != authService.currentUserId) return false;
      _profile = _profile.copyWith(major: '');
      _courses = [];
      _selectedSemester = null;
      setState(AsyncViewState.data(_profile));
      return true;
    } catch (_) {
      if (uid == authService.currentUserId) {
        setLastError('Không xoá được chuyên ngành. Kiểm tra kết nối và thử lại.');
      }
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  String get currentMajor => _profile.major;

  /// Saves the first curriculum choice and loads only that major's courses.
  Future<bool> chooseMajor(String code) async {
    if (_saving) return false;
    final uid = authService.currentUserId;
    if (uid == null) {
      setLastError('Chưa đăng nhập.');
      return false;
    }
    final normalized = code.trim();
    if (normalized.isEmpty) {
      setLastError('Hãy chọn một chuyên ngành.');
      return false;
    }
    try {
      _saving = true;
      clearLastError();
      notifyListeners();
      await firestoreService.saveAcademicProfile(uid, {'major': normalized});
      final docs = await firestoreService.getCoursesForMajor(normalized);
      if (isDisposed || uid != authService.currentUserId) return false;
      _profile = _profile.copyWith(major: normalized);
      _courses = docs.map(CourseModel.fromMap).toList();
      _selectedSemester = null;
      setState(AsyncViewState.data(_profile));
      return true;
    } catch (e) {
      if (uid == authService.currentUserId) {
        setLastError(
          'Không lưu được chuyên ngành. Kiểm tra kết nối và thử lại.',
        );
      }
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  Future<bool> save({
    required String transcript,
    double? targetGpa,
  }) async {
    if (_saving) return false;
    final uid = authService.currentUserId;
    if (uid == null) {
      setLastError('Chưa đăng nhập.');
      return false;
    }
    try {
      final grades = parseTranscript(transcript);
      if (targetGpa != null &&
          (!targetGpa.isFinite || targetGpa < 0 || targetGpa > 10)) {
        throw const FormatException('Mục tiêu GPA không hợp lệ.');
      }
      _saving = true;
      clearLastError();
      notifyListeners();
      await firestoreService.saveAcademicProfile(uid, {
        'transcript': grades.map((e) => e.toMap()).toList(),
        'targetGpa': ?targetGpa,
        'academicDataSource': 'user_entered',
      });
      if (isDisposed || uid != authService.currentUserId) return false;
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
