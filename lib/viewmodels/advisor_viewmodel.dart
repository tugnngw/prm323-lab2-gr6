import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:study_pilot_core/study_pilot_core.dart';

import '../models/course_model.dart';
import '../services/ai_service.dart';
import '../services/analytics_service.dart';
import '../services/app_check_service.dart';
import '../services/auth_service.dart';
import '../services/remote_config_service.dart';
import '../services/report_media_storage_service.dart';
import '../utils/ai_failure_messages.dart';
import 'academic_viewmodel.dart';

/// Consultation level for an advisor question — the four levels required by
/// rubric §6.4 (môn học / kỳ học / chương trình / điểm số).
enum AdvisorLevel {
  course('course', 'Môn'),
  semester('semester', 'Kỳ'),
  program('program', 'Chương trình'),
  score('score', 'Điểm');

  const AdvisorLevel(this.id, this.label);

  /// Stable slug used in analytics parameters and message metadata.
  final String id;

  /// Vietnamese label shown in the level selector.
  final String label;

  static AdvisorLevel fromId(String? id) =>
      values.firstWhere((l) => l.id == id, orElse: () => AdvisorLevel.course);
}

/// Whether Gemini can be used right now. `unknown` means no question has been
/// attempted yet in this session.
enum AiStatus { unknown, available, unavailable }

/// Where a message's content came from, shown as a badge in the chat.
enum AdvisorSource {
  local('Trên thiết bị'),
  hybrid('Gemini + thiết bị'),
  aiUnavailable('Không kết nối AI');

  const AdvisorSource(this.label);
  final String label;
}

/// A deterministic, on-device question the student can pick instead of
/// guessing what the advisor understands.
enum LocalQuestionKind {
  courseOverview(
    'course_overview',
    'Tóm tắt môn học',
    'Tín chỉ, giảng viên, tiên quyết, số slot, đầu điểm',
    AdvisorLevel.course,
    needsCourse: true,
  ),
  courseAssessments(
    'course_assessments',
    'Bài kiểm tra & trọng số',
    'Các đầu điểm, thời lượng và tiêu chí đánh giá',
    AdvisorLevel.course,
    needsCourse: true,
  ),
  courseSlots(
    'course_slots',
    'Nội dung từng slot',
    'Chủ đề, tài liệu và nhiệm vụ theo slot',
    AdvisorLevel.course,
    needsCourse: true,
  ),
  coursePrerequisites(
    'course_prerequisites',
    'Tiên quyết môn này',
    'Đã đủ hay còn thiếu môn nào',
    AdvisorLevel.course,
    needsCourse: true,
  ),
  courseGrade(
    'course_grade',
    'Điểm môn này',
    'Điểm trong bảng điểm và điểm thành phần đã lưu',
    AdvisorLevel.course,
    needsCourse: true,
  ),
  courseTips(
    'course_tips',
    'Bí kíp đã duyệt',
    'Kinh nghiệm từ tiền bối cho môn này',
    AdvisorLevel.course,
    needsCourse: true,
  ),
  courseStudyPlan(
    'course_study_plan',
    'Chiến lược ôn môn này',
    'Ưu tiên theo trọng số và slot có nhiệm vụ',
    AdvisorLevel.course,
    needsCourse: true,
  ),
  semesterOverview(
    'semester_overview',
    'Tổng quan kỳ học',
    'Số môn, tín chỉ, môn đủ điều kiện',
    AdvisorLevel.semester,
    needsSemester: true,
  ),
  semesterAssessments(
    'semester_assessments',
    'Đầu điểm cả kỳ',
    'Tóm tắt đánh giá của từng môn trong kỳ',
    AdvisorLevel.semester,
    needsSemester: true,
  ),
  blockedPrerequisites(
    'program_prerequisites',
    'Môn vướng tiên quyết',
    'Toàn bộ môn còn thiếu điều kiện',
    AdvisorLevel.program,
  ),
  retakes(
    'program_retakes',
    'Môn cần học lại',
    'Môn chưa qua trong bảng điểm',
    AdvisorLevel.program,
  ),
  eligibleCourses(
    'program_eligible',
    'Môn có thể đăng ký',
    'Đủ tiên quyết và chưa hoàn thành',
    AdvisorLevel.program,
  ),
  gpaSummary(
    'score_gpa',
    'GPA từng kỳ & tích lũy',
    'Điểm trung bình theo tín chỉ',
    AdvisorLevel.score,
  ),
  completedCredits('score_credits', 'Tín chỉ đã qua', 'Tổng tín chỉ hoàn thành', AdvisorLevel.score);

  const LocalQuestionKind(
    this.id,
    this.label,
    this.description,
    this.level, {
    this.needsCourse = false,
    this.needsSemester = false,
  });

  final String id;
  final String label;
  final String description;
  final AdvisorLevel level;
  final bool needsCourse;
  final bool needsSemester;

  /// Prompts offered for a given consultation level.
  static List<LocalQuestionKind> forLevel(AdvisorLevel level) =>
      values.where((kind) => kind.level == level).toList();
}

class AdvisorMessage {
  const AdvisorMessage({
    required this.id,
    required this.sender, // 'user' or 'ai'
    required this.text,
    required this.timestamp,
    this.level = AdvisorLevel.course,
    this.source = AdvisorSource.local,
    this.isError = false,
  });

  final String id;
  final String sender;
  final String text;
  final String timestamp;
  final AdvisorLevel level;
  final AdvisorSource source;
  final bool isError;
}

/// Combines Gemini guidance from the shared catalog with private calculations
/// on the device. The on-device layer always works; Gemini is an optional
/// enhancement that is short-circuited after a failure until the user retries.
class AdvisorViewModel extends ChangeNotifier {
  AdvisorViewModel({
    this.remoteConfigService,
    this.academicViewModel,
    this.analyticsService,
    this.authService,
    this.aiService,
    this.store,
    this.askGemini,
  }) {
    _initDefaults();
    _sessionUid = authService?.currentUserId;
    _authSub = authService?.authStateChanges.listen((_) {
      final uid = authService?.currentUserId;
      if (uid == _sessionUid) return;
      _sessionUid = uid;
      _requestVersion++;
      _messages.clear();
      _consentGranted = false;
      _failedQuestion = null;
      _errorMessage = null;
      _isLoading = false;
      _selectedLevel = AdvisorLevel.course;
      _localCourseCode = null;
      _aiStatus = AiStatus.unknown;
      _aiFailure = null;
      _lastRawError = null;
      _prmScore = 8.5;
      _swpScore = 8.0;
      _swrScore = 8.0;
      _initDefaults();
      notifyListeners();
    });
    remoteConfigService?.addListener(_onConfigChanged);
  }

  StreamSubscription<bool>? _authSub;
  String? _sessionUid;
  int _requestVersion = 0;
  bool _disposed = false;

  void _onConfigChanged() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _requestVersion++;
    _authSub?.cancel();
    remoteConfigService?.removeListener(_onConfigChanged);
    super.dispose();
  }

  final RemoteConfigService? remoteConfigService;
  final AnalyticsService? analyticsService;
  final AuthService? authService;
  final AcademicViewModel? academicViewModel;
  final AiService? aiService;
  final FinalFirestore? store;
  final Future<String> Function(
    String uid,
    String question,
    String level,
    String catalog,
  )?
  askGemini;

  final List<AdvisorMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _failedQuestion;
  AdvisorLevel _failedLevel = AdvisorLevel.course;
  AdvisorLevel _selectedLevel = AdvisorLevel.course;
  String? _localCourseCode;
  int? _localSemester;

  /// Share consent (rubric §6.4). [askQuestion] fails closed until the user
  /// has confirmed what is sent; the screen shows the dialog before the first
  /// question and calls [grantConsent] on accept. Local prompts never need it.
  bool _consentGranted = false;

  AiStatus _aiStatus = AiStatus.unknown;
  String? _aiFailure;
  String? _lastRawError;

  // Simulation state — hypothetical slider values, NOT stored/real grades.
  double _prmScore = 8.5;
  double _swpScore = 8.0;
  double _swrScore = 8.0;

  List<ExperienceNote> _cachedApprovedTips = const [];

  void updateApprovedTips(List<ExperienceNote> tips) {
    _cachedApprovedTips = tips;
  }

  List<AdvisorMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isAiEnabled => remoteConfigService?.isAiAdvisorEnabled ?? true;
  bool get hasConsent => _consentGranted;
  bool get usesGemini =>
      askGemini != null || (aiService != null && isAiEnabled);

  /// Currently selected consultation level (drives the UI selector).
  AdvisorLevel get selectedLevel => _selectedLevel;

  /// Last advisor failure; the chat shows it with a Retry action.
  String? get errorMessage => _errorMessage;

  AiStatus get aiStatus => _aiStatus;
  String? get aiFailure => _aiFailure;

  /// Raw `runtimeType: message` of the last failure, shown in diagnostics.
  String? get lastRawError => _lastRawError;

  String get aiModelLabel =>
      remoteConfigService?.aiAdvisorModel ?? 'gemini-3.5-flash-lite';

  String get aiProviderLabel => AppCheckService.providerLabel;

  bool get usesDebugAppCheck => AppCheckService.usesDebugProvider;

  /// True when AI is configured and the last attempt failed (or config is off).
  bool get aiUnavailable =>
      !isAiEnabled || _aiStatus == AiStatus.unavailable;

  String get aiStatusTitle {
    if (!isAiEnabled) return 'AI đang tắt';
    if (_aiStatus == AiStatus.available) return 'AI sẵn sàng';
    if (_aiStatus == AiStatus.unavailable) return 'AI không hoạt động';
    if (!usesGemini) return 'Chỉ dùng dữ liệu trên thiết bị';
    return 'AI chưa kiểm tra';
  }

  String get aiStatusDetail {
    if (!isAiEnabled) {
      return 'Remote Config đang tắt lớp Gemini. Cố vấn vẫn trả lời đầy đủ '
          'bằng dữ liệu trên thiết bị.';
    }
    if (_aiStatus == AiStatus.unavailable) {
      final reason = (_aiFailure ?? 'Không gọi được Gemini.')
          .split('Cách xử lý:')
          .first
          .trim();
      return '$reason\nMở "Chi tiết AI" (biểu tượng ⓘ) để xem cách xử lý.';
    }
    if (_aiStatus == AiStatus.available) {
      return 'Gemini sẽ bổ sung gợi ý từ đề cương. Điểm và hồ sơ của bạn vẫn '
          'được xử lý trên thiết bị.';
    }
    if (!usesGemini) {
      return 'Chưa cấu hình Gemini. Mọi câu trả lời lấy từ dữ liệu trên thiết bị.';
    }
    return 'Hỏi một câu để kiểm tra Gemini ($aiModelLabel). Nếu lỗi, app sẽ '
        'chuyển sang trả lời trên thiết bị.';
  }

  /// Technical details for the help dialog.
  String get diagnostics => [
    'AI: ${isAiEnabled ? 'bật' : 'tắt'} · model $aiModelLabel',
    'App Check: $aiProviderLabel'
        '${AppCheckService.tokenOk ? ' · token OK' : ''}',
    if (_lastRawError != null) 'Lỗi gần nhất: $_lastRawError',
  ].join('\n');

  List<CourseModel> get catalogCourses =>
      academicViewModel?.courses ?? const [];

  List<int> get catalogSemesters => academicViewModel?.semesters ?? const [];

  String? get selectedLocalCourse => _localCourseCode;
  int? get selectedLocalSemester => _localSemester;

  /// Catalog course to preselect: the first one in the student's current
  /// semester, otherwise the first course of the major.
  CourseModel? get defaultLocalCourse {
    final courses = catalogCourses;
    if (courses.isEmpty) return null;
    final semester = defaultLocalSemester;
    for (final course in courses) {
      if (course.semester == semester) return course;
    }
    return courses.first;
  }

  /// Semester to preselect: the student's current semester.
  int? get defaultLocalSemester =>
      _localSemester ??
      academicViewModel?.selectedSemester ??
      (catalogSemesters.isEmpty ? null : catalogSemesters.last);

  void selectLocalCourse(String? code) {
    final normalized = code?.trim().toUpperCase();
    _localCourseCode = (normalized == null || normalized.isEmpty)
        ? null
        : normalized;
    notifyListeners();
  }

  void selectLocalSemester(int? semester) {
    _localSemester = semester;
    notifyListeners();
  }

  double get prmScore => _prmScore;
  double get swpScore => _swpScore;
  double get swrScore => _swrScore;

  /// Predicted term GPA for the 11-credit semester sandbox (simulated values).
  double get predictedSemesterGpa {
    const totalCredits = 3 + 5 + 3; // 11
    final weighted = (_prmScore * 3) + (_swpScore * 5) + (_swrScore * 3);
    return weighted / totalCredits;
  }

  /// The sandbox compares term GPA against the honors threshold directly —
  /// a real cumulative GPA would come from the transcript, which this build
  /// does not fabricate.
  bool get reachesHonorsTarget => predictedSemesterGpa >= 8.0;

  void grantConsent() {
    if (_consentGranted) return;
    _consentGranted = true;
    notifyListeners();
  }

  void selectLevel(AdvisorLevel level) {
    if (_selectedLevel == level) return;
    _selectedLevel = level;
    notifyListeners();
  }

  void updateSimulation({double? prm, double? swp, double? swr}) {
    if (prm != null) _prmScore = prm;
    if (swp != null) _swpScore = swp;
    if (swr != null) _swrScore = swr;
    notifyListeners();
  }

  /// Preset scenario applied in the Strategy Simulator — logs event 13
  /// (guide §6.4 "tạo strategy"). Slider edits are NOT logged (they fire per
  /// pixel; analytics rule is once per user action).
  void applyPreset({
    required String preset,
    double? prm,
    double? swp,
    double? swr,
  }) {
    updateSimulation(prm: prm, swp: swp, swr: swr);
    analyticsService?.logStrategyPresetApplied(preset: preset);
  }

  /// Simulator opened (guide §6.4 "xem strategy"). Called once from the
  /// home screen's GPA card — not from build().
  void logStrategyOpened({String source = 'advisor'}) {
    analyticsService?.logStrategyView(source: source);
  }

  void _initDefaults() {
    final email = authService?.currentUserEmail;
    final name = email != null && email.isNotEmpty
        ? email.split('@').first
        : 'bạn';
    _messages.add(
      AdvisorMessage(
        id: 'msg_welcome',
        sender: 'ai',
        text:
            'Xin chào $name! Mình là Cố vấn học tập FPTU.\n\n'
            'Bấm **Hỏi nhanh trên thiết bị** để chọn câu hỏi về môn học, kỳ học, '
            'chương trình hoặc GPA — trả lời ngay, không cần mạng.\n\n'
            '${usesGemini ? 'Khi có mạng, Gemini bổ sung gợi ý từ đề cương. Điểm và hồ sơ của bạn vẫn ở trên máy.' : 'Bản này chỉ dùng dữ liệu học tập trên thiết bị.'}',
        timestamp: 'Vừa xong',
        level: AdvisorLevel.program,
      ),
    );
  }

  /// Re-asks the failed question after an AI failure (retry branch). With no
  /// failed question this only clears the cached failure so the next question
  /// tries Gemini again.
  Future<void> retryLastQuestion() async {
    final failed = _failedQuestion;
    _failedQuestion = null;
    _errorMessage = null;
    _aiStatus = AiStatus.unknown;
    _aiFailure = null;
    if (failed == null) {
      notifyListeners();
      return;
    }
    await _askQuestion(failed, level: _failedLevel, retry: true);
  }

  String _errorId(String question) =>
      'msg_err_${question.hashCode.toUnsigned(32)}';

  String _fallbackId(String question) =>
      'msg_local_${question.hashCode.toUnsigned(32)}';

  Future<void> askQuestion(String question, {AdvisorLevel? level}) =>
      _askQuestion(question, level: level);

  /// Answers a catalogued on-device question. No consent or network needed.
  Future<void> askLocalPrompt(
    LocalQuestionKind kind, {
    String? courseCode,
    int? semester,
  }) async {
    if (_disposed || _isLoading) return;
    final academic = academicViewModel;
    final course = kind.needsCourse
        ? _findCourse(academic, courseCode ?? _localCourseCode)
        : null;
    final prompt = _promptLabel(kind, course, semester ?? _localSemester);
    _messages.add(
      AdvisorMessage(
        id: 'msg_q_${DateTime.now().microsecondsSinceEpoch}',
        sender: 'user',
        text: prompt,
        timestamp: 'Vừa xong',
        level: kind.level,
      ),
    );
    _isLoading = true;
    _selectedLevel = kind.level;
    notifyListeners();
    try {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (_disposed) return;
      final answer = _localAnswer(
        kind,
        academic,
        course,
        semester ?? _localSemester,
      );
      _messages.add(
        AdvisorMessage(
          id: 'msg_local_${DateTime.now().microsecondsSinceEpoch}',
          sender: 'ai',
          text: answer,
          timestamp: 'Vừa xong',
          level: kind.level,
          source: AdvisorSource.local,
        ),
      );
    } finally {
      if (!_disposed) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  String _promptLabel(
    LocalQuestionKind kind,
    CourseModel? course,
    int? semester,
  ) {
    final target = course?.code;
    final suffix = target != null
        ? ' · $target'
        : semester != null && kind.needsSemester
        ? ' · kỳ $semester'
        : '';
    return '${kind.label}$suffix';
  }

  Future<void> _askQuestion(
    String question, {
    AdvisorLevel? level,
    bool retry = false,
  }) async {
    if (_disposed || _isLoading) return;
    final request = ++_requestVersion;
    final useLevel = level ?? _selectedLevel;

    // Fail closed: no question leaves the device without consent.
    if (!_consentGranted) {
      debugPrint('[Advisor] askQuestion blocked — share consent not granted.');
      return;
    }
    if (question.trim().isEmpty) return;
    if (question.length > 500) {
      _errorMessage = 'Câu hỏi tối đa 500 ký tự.';
      notifyListeners();
      return;
    }

    final uid = authService?.currentUserId;
    _selectedLevel = useLevel;
    _errorMessage = null;

    if (retry) {
      _messages.removeWhere(
        (message) =>
            message.id == _errorId(question) ||
            message.id == _fallbackId(question),
      );
    } else {
      _messages.add(
        AdvisorMessage(
          id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
          sender: 'user',
          text: question,
          timestamp: 'Vừa xong',
          level: useLevel,
        ),
      );
    }
    _isLoading = true;
    notifyListeners();

    analyticsService?.logAdvisorQuery(topic: useLevel.id);

    try {
      final academic = academicViewModel;
      if (academic != null) {
        // A stale catalog must not block the on-device answer.
        try {
          await academic.loadData().timeout(const Duration(seconds: 15));
        } catch (_) {}
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }
      if (_disposed || request != _requestVersion) return;
      final local = _replyFor(useLevel, question.toLowerCase());
      final ask = askGemini;
      final aiAttemptable =
          isAiEnabled && (ask != null || aiService != null);

      if (!aiAttemptable) {
        _messages.add(
          AdvisorMessage(
            id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
            sender: 'ai',
            text: local,
            timestamp: 'Vừa xong',
            level: useLevel,
            source: AdvisorSource.local,
          ),
        );
        return;
      }

      // A previous failure means Gemini is known-bad this session: answer
      // locally instead of paying another full timeout.
      if (_aiStatus == AiStatus.unavailable) {
        _failedQuestion = question;
        _failedLevel = useLevel;
        _messages.add(
          AdvisorMessage(
            id: _fallbackId(question),
            sender: 'ai',
            text: local,
            timestamp: 'Vừa xong',
            level: useLevel,
            source: AdvisorSource.aiUnavailable,
          ),
        );
        return;
      }

      if (_cachedApprovedTips.isEmpty && store != null) {
        try {
          _cachedApprovedTips = await store!
              .getApprovedExperienceNotes()
              .timeout(const Duration(seconds: 3));
        } catch (_) {}
      }

      String? answer;
      if (ask != null) {
        if (uid == null || uid != authService?.currentUserId || !isAiEnabled) {
          throw StateError('Phiên hỏi đáp đã thay đổi.');
        }
        analyticsService?.logAiRequest(feature: 'advisor');
        final courses = academic?.courses ?? [];
        final catalog = _buildSyllabusContext(courses, question);
        answer = await ask(
          uid,
          question,
          useLevel.id,
          catalog.substring(0, catalog.length.clamp(0, 10000)),
        );
      } else {
        final model = aiModelLabel;
        analyticsService?.logAiRequest(feature: 'advisor', model: model);
        final courses = academic?.courses ?? [];
        final catalog = _buildSyllabusContext(courses, question);
        answer = await _callFirebaseAi(
          question: question,
          level: useLevel,
          catalogContext: catalog,
        );
      }

      if (_disposed ||
          request != _requestVersion ||
          uid != authService?.currentUserId ||
          !isAiEnabled) {
        return;
      }
      analyticsService?.logAiResultAccepted(feature: 'advisor');
      _aiStatus = AiStatus.available;
      _aiFailure = null;
      _lastRawError = null;
      _messages.add(
        AdvisorMessage(
          id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
          sender: 'ai',
          text:
              '${answer.trim()}\n\n---\n\n**Đối chiếu trên thiết bị**\n\n$local',
          timestamp: 'Vừa xong',
          level: useLevel,
          source: AdvisorSource.hybrid,
        ),
      );
    } catch (e) {
      if (_disposed || request != _requestVersion) return;
      analyticsService?.logAiError(
        feature: 'advisor',
        errorType: e.runtimeType.toString(),
      );
      debugPrint('[Advisor] askQuestion failed: ${e.runtimeType}: $e');
      final failure = e is AdvisorRequestException
          ? e.message
          : describeAiFailure(e);
      _aiStatus = AiStatus.unavailable;
      _aiFailure = failure;
      _lastRawError = '${e.runtimeType}: $e';
      _errorMessage = failure;
      _failedQuestion = question;
      _failedLevel = useLevel;
      final fallback = _replyFor(useLevel, question.toLowerCase());
      _messages
        ..add(
          AdvisorMessage(
            id: _errorId(question),
            sender: 'ai',
            text:
                '$failure\n\n'
                'Không cần mạng: bạn vẫn dùng được câu trả lời trên thiết bị bên dưới.',
            timestamp: 'Vừa xong',
            level: useLevel,
            source: AdvisorSource.aiUnavailable,
            isError: true,
          ),
        )
        ..add(
          AdvisorMessage(
            id: _fallbackId(question),
            sender: 'ai',
            text: fallback,
            timestamp: 'Vừa xong',
            level: useLevel,
            source: AdvisorSource.local,
          ),
        );
    } finally {
      if (!_disposed && request == _requestVersion) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  // ── Local answer engine ──────────────────────────────────────────────────

  CourseModel? _findCourse(AcademicViewModel? academic, String? code) {
    if (academic == null) return null;
    final target = code?.trim().toUpperCase();
    if (target == null || target.isEmpty) return null;
    for (final course in academic.courses) {
      if (course.code.trim().toUpperCase() == target) return course;
    }
    return null;
  }

  String _localAnswer(
    LocalQuestionKind kind,
    AcademicViewModel? academic,
    CourseModel? course,
    int? semester,
  ) {
    if (academic == null) {
      return '**Chưa sẵn sàng dữ liệu học tập.** Đăng nhập và chọn chuyên ngành '
          'để mình trả lời trên thiết bị.';
    }
    if (kind.needsCourse && course == null) {
      return '**Chưa chọn môn học.** Chọn một môn trong danh sách rồi hỏi lại.';
    }
    switch (kind) {
      case LocalQuestionKind.courseOverview:
        return _courseSummary(academic, course!);
      case LocalQuestionKind.courseAssessments:
        return _courseAssessments(course!);
      case LocalQuestionKind.courseSlots:
        return _courseSlots(course!);
      case LocalQuestionKind.coursePrerequisites:
        return _coursePrerequisites(academic, course!);
      case LocalQuestionKind.courseGrade:
        return _courseGrade(academic, course!);
      case LocalQuestionKind.courseTips:
        return _courseTips(course!);
      case LocalQuestionKind.courseStudyPlan:
        return _courseStudyPlan(academic, course!);
      case LocalQuestionKind.semesterOverview:
        return _semesterOverview(
          academic,
          semester ?? academic.selectedSemester,
        );
      case LocalQuestionKind.semesterAssessments:
        return _semesterAssessments(
          academic,
          semester ?? academic.selectedSemester,
        );
      case LocalQuestionKind.blockedPrerequisites:
        return _blockedPrerequisites(academic);
      case LocalQuestionKind.retakes:
        return _retakes(academic);
      case LocalQuestionKind.eligibleCourses:
        return _eligibleCourses(academic);
      case LocalQuestionKind.gpaSummary:
        return _gpaSummary(academic);
      case LocalQuestionKind.completedCredits:
        return _completedCredits(academic);
    }
  }

  String _courseSummary(AcademicViewModel academic, CourseModel course) {
    final profile = academic.profile;
    final code = course.code.trim().toUpperCase();
    final record = profile.transcript
        .where((entry) => entry.courseCode.trim().toUpperCase() == code)
        .toList();
    final buffer = StringBuffer()
      ..writeln('### ${course.code} — ${course.name}')
      ..writeln(
        '- **Tín chỉ:** ${course.credits} · **Kỳ:** ${course.semester}'
        '${course.major.isEmpty ? '' : ' · **Ngành:** ${course.major}'}',
      );
    if (course.lecturer.trim().isNotEmpty) {
      buffer.writeln('- **Giảng viên:** ${course.lecturer.trim()}');
    }
    buffer.writeln('- **Tiên quyết:** ${_prerequisiteLine(academic, course)}');
    final slots = course.slots.isEmpty ? course.totalSlots : course.slots.length;
    buffer.writeln(
      '- **Slot đề cương:** $slots'
      '${course.completedSlots > 0 ? ' · đã học ${course.completedSlots} theo tiến độ của bạn' : ''}',
    );
    if (course.labs.isNotEmpty) {
      buffer.writeln('- **Đầu điểm:** ${_assessmentBrief(course)}');
    }
    if (course.learningOutcomes.isNotEmpty) {
      buffer.writeln(
        '- **Chuẩn đầu ra:** ${course.learningOutcomes.length} mục',
      );
    }
    if (course.courseMaterials.isNotEmpty) {
      buffer.writeln(
        '- **Tài liệu:** ${course.courseMaterials.length} đầu sách/giáo trình',
      );
    }
    if (record.isNotEmpty) {
      final latest = record.last;
      buffer.writeln(
        '- **Điểm đã nhập:** ${_formatGrade(latest.grade)} · '
        '${latest.passed ? 'đã qua' : 'chưa qua'}',
      );
    } else {
      buffer.writeln('- **Điểm đã nhập:** chưa có trong bảng điểm');
    }
    buffer
      ..writeln()
      ..write(
        '_Nguồn: đề cương FLM và hồ sơ học tập trên thiết bị. '
        'Hỏi thêm "bài kiểm tra", "nội dung slot", "tiên quyết" hoặc "điểm"._',
      );
    return buffer.toString();
  }

  String _courseAssessments(CourseModel course) {
    if (course.labs.isEmpty) {
      return '### Đầu điểm môn ${course.code}\n\n'
          'Đề cương chưa có đầu điểm nào. Nếu FLM đã cập nhật, cán bộ cần nhập '
          'lại đề cương cho môn này.';
    }
    final sorted = [...course.labs]
      ..sort((a, b) => (b.weight ?? 0).compareTo(a.weight ?? 0));
    final buffer = StringBuffer()
      ..writeln('### Đầu điểm môn ${course.code} (${course.name})')
      ..writeln();
    var totalWeight = 0.0;
    for (final lab in sorted) {
      final weight = lab.weight ?? 0;
      totalWeight += weight;
      final details = <String>[
        if (weight > 0) '**${_formatWeight(weight)}%**',
        if (lab.duration.trim().isNotEmpty) lab.duration.trim(),
        if (lab.category.trim().isNotEmpty && lab.category != lab.title)
          lab.category.trim(),
      ];
      buffer.writeln('- **${lab.title.trim()}**${details.isEmpty ? '' : ' — ${details.join(' · ')}'}');
      if (lab.gradingCriteria.trim().isNotEmpty) {
        buffer.writeln('  - Tiêu chí: ${lab.gradingCriteria.trim()}');
      }
      if (lab.completionCriteria.trim().isNotEmpty) {
        buffer.writeln('  - Điều kiện hoàn thành: ${lab.completionCriteria.trim()}');
      }
    }
    buffer.writeln();
    buffer.writeln(
      totalWeight > 0
          ? '**Tổng trọng số:** ${_formatWeight(totalWeight)}%'
          : 'Đề cương chưa ghi trọng số cho các đầu điểm.',
    );
    buffer.write(
      '\n\n_Đầu điểm có trọng số cao nhất nên được ưu tiên ôn trước. '
      'Điểm thành phần bạn nhập nằm ở chi tiết môn._',
    );
    return buffer.toString();
  }

  String _courseSlots(CourseModel course) {
    if (course.slots.isEmpty) {
      return '### Nội dung slot môn ${course.code}\n\n'
          'Đề cương chưa có nội dung từng slot. Bạn vẫn xem được số slot và '
          'đầu điểm trong chi tiết môn.';
    }
    final slots = course.slots.take(40).toList();
    final buffer = StringBuffer()
      ..writeln(
        '### Nội dung ${slots.length}${course.slots.length > slots.length ? '/${course.slots.length}' : ''} slot · ${course.code}',
      )
      ..writeln();
    for (final slot in slots) {
      final extras = <String>[
        if (slot.materials.trim().isNotEmpty) 'TL: ${_shorten(slot.materials)}',
        if (slot.tasks.trim().isNotEmpty) 'NV: ${_shorten(slot.tasks)}',
        if (slot.cqs.trim().isNotEmpty) 'CQ: ${_shorten(slot.cqs)}',
      ];
      buffer.writeln(
        '- **Slot ${slot.number}** — ${slot.displayTopic}'
        '${extras.isEmpty ? '' : ' (${extras.join('; ')})'}',
      );
    }
    if (course.slots.length > slots.length) {
      buffer.writeln(
        '\n_Còn ${course.slots.length - slots.length} slot nữa; xem đầy đủ ở tab Slot của môn._',
      );
    }
    return buffer.toString();
  }

  String _coursePrerequisites(AcademicViewModel academic, CourseModel course) {
    final noteOnly = course.prerequisites.isEmpty &&
        course.prerequisiteNote.isNotEmpty;
    final missing = academic.missingPrerequisites(course);
    final buffer = StringBuffer()
      ..writeln('### Tiên quyết môn ${course.code}')
      ..writeln();
    if (noteOnly) {
      buffer.writeln(
        'Đề cương ghi điều kiện bằng văn bản, cần đối chiếu thủ công:\n'
        '> ${course.prerequisiteNote}',
      );
    } else if (course.prerequisites.isEmpty) {
      buffer.writeln('Môn này **không yêu cầu** tiên quyết trong danh mục.');
    } else {
      buffer.writeln(
        'Danh mục yêu cầu: **${course.prerequisites.join(', ')}**.',
      );
      buffer.writeln(
        missing.isEmpty
            ? 'Bạn **đã đủ** tiên quyết theo bảng điểm đã nhập.'
            : 'Bạn **còn thiếu**: ${missing.join(', ')}.',
      );
    }
    buffer.write(
      '\n_Điều kiện được xét theo điểm môn tiên quyết từ 5.0 trở lên trong '
      'bảng điểm bạn tự nhập._',
    );
    return buffer.toString();
  }

  String _courseGrade(AcademicViewModel academic, CourseModel course) {
    final profile = academic.profile;
    final code = course.code.trim().toUpperCase();
    final records = profile.transcript
        .where((entry) => entry.courseCode.trim().toUpperCase() == code)
        .toList();
    final scores = academic.componentScoresFor(code);
    final buffer = StringBuffer()..writeln('### Điểm môn ${course.code}');
    if (records.isEmpty) {
      buffer.writeln('\nChưa có kết quả môn này trong bảng điểm.');
    } else {
      final latest = records.last;
      buffer
        ..writeln()
        ..writeln(
          '- **Bảng điểm:** ${_formatGrade(latest.grade)} · kỳ ${latest.semester} · '
          '${latest.passed ? 'đã qua' : 'chưa qua'} · ${latest.credits} tín chỉ',
        );
    }
    if (scores.isEmpty) {
      buffer.writeln('- **Điểm thành phần:** chưa nhập.');
    } else {
      buffer.writeln('- **Điểm thành phần đã lưu:**');
      for (final lab in course.labs) {
        final score = scores[lab.id];
        if (score == null) continue;
        buffer.writeln(
          '  - ${lab.title}: ${_formatGrade(score)}'
          '${lab.weight != null ? ' (${_formatWeight(lab.weight!)}%)' : ''}',
        );
      }
      final total = AcademicViewModel.weightedTotal(course, scores);
      buffer.writeln(
        total == null
            ? '  - Chưa đủ đầu điểm có trọng số để tính tổng.'
            : '  - **Tổng có trọng số:** ${_formatGrade(total)}',
      );
    }
    buffer.write(
      '\n_Nhập hoặc sửa điểm ở chi tiết môn hoặc tab Bảng điểm; '
      'app không tự lấy điểm từ hệ thống trường._',
    );
    return buffer.toString();
  }

  String _courseTips(CourseModel course) {
    final tips = _cachedApprovedTips
        .where(
          (tip) => tip.courseCode.trim().toUpperCase() ==
              course.code.trim().toUpperCase(),
        )
        .toList();
    if (tips.isEmpty) {
      return '### Bí kíp môn ${course.code}\n\n'
          'Chưa có bí kíp nào được duyệt cho môn này. Bạn có thể chia sẻ kinh '
          'nghiệm ở phần Cộng đồng để cán bộ duyệt.';
    }
    final buffer = StringBuffer()
      ..writeln('### Bí kíp môn ${course.code} (${tips.length})')
      ..writeln();
    for (final tip in tips.take(8)) {
      buffer.writeln('**${tip.displayTitle}**${tip.rating > 0 ? ' · ${tip.rating}★' : ''}');
      buffer.writeln('> ${tip.content.trim()}');
      if (tip.lecturerTip.trim().isNotEmpty) {
        buffer.writeln('- Giảng viên: ${tip.lecturerTip.trim()}');
      }
      if (tip.examTip.trim().isNotEmpty) {
        buffer.writeln('- Thi cử: ${tip.examTip.trim()}');
      }
      buffer.writeln();
    }
    buffer.write('_Chỉ hiển thị bí kíp đã được cán bộ duyệt._');
    return buffer.toString();
  }

  String _courseStudyPlan(AcademicViewModel academic, CourseModel course) {
    final buffer = StringBuffer()
      ..writeln('### Chiến lược ôn môn ${course.code}')
      ..writeln();
    final labs = [...course.labs]
      ..sort((a, b) => (b.weight ?? 0).compareTo(a.weight ?? 0));
    if (labs.isNotEmpty) {
      buffer.writeln('**Ưu tiên theo trọng số**');
      for (final lab in labs.take(3)) {
        buffer.writeln(
          '- ${lab.title} — ${lab.weight == null ? 'chưa rõ trọng số' : '${_formatWeight(lab.weight!)}%'}'
          '${lab.duration.trim().isEmpty ? '' : ' · ${lab.duration.trim()}'}',
        );
      }
      buffer.writeln();
    }
    final taskSlots = course.slots
        .where((slot) => slot.tasks.trim().isNotEmpty)
        .take(5)
        .toList();
    if (taskSlots.isNotEmpty) {
      buffer.writeln('**Slot có nhiệm vụ cần làm**');
      for (final slot in taskSlots) {
        buffer.writeln(
          '- Slot ${slot.number}: ${slot.displayTopic} → ${_shorten(slot.tasks)}',
        );
      }
      buffer.writeln();
    }
    final record = academic.profile.transcript
        .where(
          (entry) =>
              entry.courseCode.trim().toUpperCase() ==
              course.code.trim().toUpperCase(),
        )
        .toList();
    if (record.isNotEmpty && !record.last.passed) {
      buffer.writeln(
        '⚠️ Bạn đang **chưa qua** môn này. Ưu tiên đầu điểm có trọng số cao '
        'và liên hệ giảng viên để biết điều kiện học lại.\n',
      );
    }
    if (labs.isEmpty && taskSlots.isEmpty) {
      buffer.writeln(
        'Đề cương chưa có đủ đầu điểm/nhiệm vụ để gợi ý chi tiết. '
        'Xem nội dung slot trong chi tiết môn.\n',
      );
    }
    buffer.write(
      '_Gợi ý được tính trên thiết bị từ trọng số và nhiệm vụ trong đề cương; '
      'không phải cam kết điểm._',
    );
    return buffer.toString();
  }

  String _semesterOverview(AcademicViewModel academic, int? semester) {
    final courses = semester == null
        ? academic.semesterCourses
        : academic.majorCourses
              .where((course) => course.semester == semester)
              .toList();
    final label = semester ?? academic.selectedSemester;
    if (courses.isEmpty) {
      return '### Kỳ ${label ?? '(chưa chọn)'}\n\n'
          'Danh mục chưa có môn cho kỳ này. Kiểm tra chuyên ngành hoặc chọn kỳ khác.';
    }
    final credits = courses.fold<int>(
      0,
      (total, course) => total + course.credits,
    );
    final eligible = <String>[];
    final blocked = <String>[];
    for (final course in courses) {
      final missing = academic.missingPrerequisites(course);
      final noteOnly =
          course.prerequisites.isEmpty && course.prerequisiteNote.isNotEmpty;
      if (missing.isEmpty && !noteOnly) {
        eligible.add(course.code);
      } else if (noteOnly) {
        blocked.add('${course.code} (điều kiện ghi chú)');
      } else {
        blocked.add('${course.code} (thiếu ${missing.join(', ')})');
      }
    }
    final buffer = StringBuffer()
      ..writeln('### Kỳ $label')
      ..writeln()
      ..writeln(
        '- **Số môn:** ${courses.length} · **Tín chỉ:** $credits',
      )
      ..writeln(
        '- **Đủ tiên quyết:** ${eligible.isEmpty ? 'chưa có' : eligible.length}'
        '${eligible.isEmpty ? '' : ' (${eligible.join(', ')})'}',
      )
      ..writeln(
        '- **Còn vướng:** ${blocked.isEmpty ? 'không có' : blocked.length}'
        '${blocked.isEmpty ? '' : ' (${blocked.join('; ')})'}',
      )
      ..writeln()
      ..writeln('**Danh sách môn**');
    for (final course in courses) {
      buffer.writeln(
        '- ${course.code} — ${course.name} · ${course.credits} TC',
      );
    }
    buffer.write(
      '\n_Điều kiện tiên quyết dựa trên bảng điểm bạn đã nhập, không phải '
      'kết quả đăng ký chính thức._',
    );
    return buffer.toString();
  }

  String _semesterAssessments(AcademicViewModel academic, int? semester) {
    final courses = semester == null
        ? academic.semesterCourses
        : academic.majorCourses
              .where((course) => course.semester == semester)
              .toList();
    if (courses.isEmpty) {
      return '### Đầu điểm kỳ ${semester ?? '(chưa chọn)'}\n\n'
          'Danh mục chưa có môn cho kỳ này.';
    }
    final buffer = StringBuffer()
      ..writeln('### Đầu điểm kỳ ${semester ?? academic.selectedSemester}')
      ..writeln();
    for (final course in courses.take(15)) {
      final brief = _assessmentBrief(course);
      buffer.writeln(
        '- **${course.code}:** ${brief.isEmpty ? 'chưa có dữ liệu đầu điểm' : brief}',
      );
    }
    if (courses.length > 15) {
      buffer.writeln('\n_Còn ${courses.length - 15} môn nữa._');
    }
    buffer.write(
      '\n_Chọn một môn cụ thể để xem thời lượng và tiêu chí từng đầu điểm._',
    );
    return buffer.toString();
  }

  String _blockedPrerequisites(AcademicViewModel academic) {
    final rows = <String>[];
    for (final course in academic.courses) {
      final missing = academic.missingPrerequisites(course);
      final noteOnly =
          course.prerequisites.isEmpty && course.prerequisiteNote.isNotEmpty;
      if (missing.isEmpty && !noteOnly) continue;
      rows.add(
        noteOnly
            ? '- **${course.code}:** cần đối chiếu thủ công — ${course.prerequisiteNote}'
            : '- **${course.code}:** thiếu ${missing.join(', ')}',
      );
    }
    if (rows.isEmpty) {
      return '### Tiên quyết\n\n'
          'Không có môn nào thiếu dữ liệu tiên quyết theo bảng điểm hiện tại.';
    }
    return '### Môn còn vướng tiên quyết (${rows.length})\n\n'
        '${rows.join('\n')}\n\n'
        '_Điều kiện dựa trên điểm môn tiên quyết ≥ 5.0 trong bảng điểm bạn nhập._';
  }

  String _retakes(AcademicViewModel academic) {
    final retakes = academic.profile.transcript
        .where((entry) => !entry.passed)
        .toList();
    if (retakes.isEmpty) {
      return '### Môn cần học lại\n\n'
          'Chưa có môn nào bị đánh dấu chưa qua trong bảng điểm đã nhập.';
    }
    final buffer = StringBuffer()
      ..writeln('### Môn cần học lại (${retakes.length})')
      ..writeln();
    for (final entry in retakes) {
      buffer.writeln(
        '- **${entry.courseCode}:** ${_formatGrade(entry.grade)} · kỳ ${entry.semester} · ${entry.credits} TC',
      );
    }
    buffer.write(
      '\n_Xử lý học lại theo quy định và bảng điểm chính thức của trường._',
    );
    return buffer.toString();
  }

  String _eligibleCourses(AcademicViewModel academic) {
    final completed = academic.profile.completedCodes
        .map((code) => code.trim().toUpperCase())
        .toSet();
    final courses = academic.courses.where((course) {
      if (completed.contains(course.code.trim().toUpperCase())) return false;
      if (course.prerequisites.isEmpty && course.prerequisiteNote.isNotEmpty) {
        return false;
      }
      return academic.missingPrerequisites(course).isEmpty;
    }).toList();
    if (courses.isEmpty) {
      return '### Môn có thể đăng ký\n\n'
          'Chưa có môn nào vừa đủ tiên quyết vừa chưa hoàn thành.';
    }
    final buffer = StringBuffer()
      ..writeln('### Môn có thể đăng ký (${courses.length})')
      ..writeln();
    for (final course in courses.take(25)) {
      buffer.writeln(
        '- ${course.code} — ${course.name} · kỳ ${course.semester} · ${course.credits} TC',
      );
    }
    if (courses.length > 25) {
      buffer.writeln('\n_Còn ${courses.length - 25} môn nữa._');
    }
    buffer.write(
      '\n_Danh sách chỉ xét tiên quyết trong danh mục, không thay thế điều kiện '
      'đăng ký chính thức._',
    );
    return buffer.toString();
  }

  String _gpaSummary(AcademicViewModel academic) {
    final profile = academic.profile;
    if (profile.transcript.isEmpty) {
      return '### GPA\n\n'
          'Chưa có bảng điểm thật để tính GPA. Nhập điểm ở tab Bảng điểm '
          'trong Dữ liệu học tập.';
    }
    final bySemester = <int, List<double>>{};
    final creditsBySemester = <int, int>{};
    for (final entry in profile.transcript) {
      bySemester.putIfAbsent(entry.semester, () => []).add(
        entry.grade * entry.credits,
      );
      creditsBySemester[entry.semester] =
          (creditsBySemester[entry.semester] ?? 0) + entry.credits;
    }
    final semesterKeys = bySemester.keys.toList()..sort();
    final buffer = StringBuffer()
      ..writeln('### GPA')
      ..writeln();
    final cumulative = profile.cumulativeGpa;
    buffer.writeln(
      cumulative == null
          ? '- **Tích lũy:** chưa đủ dữ liệu'
          : '- **Tích lũy:** ${cumulative.toStringAsFixed(2)} / 10',
    );
    for (final semester in semesterKeys) {
      final credits = creditsBySemester[semester] ?? 0;
      if (credits == 0) continue;
      final total = bySemester[semester]!.fold<double>(0, (a, b) => a + b);
      buffer.writeln(
        '- Kỳ $semester: **${(total / credits).toStringAsFixed(2)}** · $credits TC',
      );
    }
    buffer.writeln();
    buffer.write(
      'Mục tiêu cá nhân: **${profile.targetGpa.toStringAsFixed(2)}** — chỉ để '
      'tự đối chiếu, không phải kết luận danh hiệu học tập.\n\n'
      '_GPA tính theo tín chỉ của các môn đã nhập, không gồm môn đang học._',
    );
    return buffer.toString();
  }

  String _completedCredits(AcademicViewModel academic) {
    final passed = academic.profile.transcript
        .where((entry) => entry.passed)
        .toList();
    if (passed.isEmpty) {
      return '### Tín chỉ đã qua\n\n'
          'Chưa có môn nào đạt trong bảng điểm đã nhập.';
    }
    final credits = passed.fold<int>(
      0,
      (total, entry) => total + entry.credits,
    );
    final buffer = StringBuffer()
      ..writeln('### Tín chỉ đã qua: $credits')
      ..writeln()
      ..writeln('${passed.length} môn đạt:');
    for (final entry in passed) {
      buffer.writeln(
        '- ${entry.courseCode} · ${entry.credits} TC · ${_formatGrade(entry.grade)}',
      );
    }
    return buffer.toString();
  }

  String _prerequisiteLine(AcademicViewModel academic, CourseModel course) {
    final noteOnly =
        course.prerequisites.isEmpty && course.prerequisiteNote.isNotEmpty;
    if (noteOnly) return 'ghi chú đề cương (đối chiếu thủ công)';
    if (course.prerequisites.isEmpty) return 'không yêu cầu';
    final missing = academic.missingPrerequisites(course);
    return missing.isEmpty
        ? 'đã đủ (${course.prerequisites.join(', ')})'
        : 'còn thiếu ${missing.join(', ')}';
  }

  String _assessmentBrief(CourseModel course) {
    if (course.labs.isEmpty) return '';
    return course.labs
        .map(
          (lab) =>
              '${lab.title}${lab.weight == null ? '' : ' ${_formatWeight(lab.weight!)}%'}',
        )
        .join(' · ');
  }

  static String _formatGrade(double grade) =>
      grade.toStringAsFixed(grade == grade.roundToDouble() ? 1 : 2);

  static String _formatWeight(double weight) =>
      weight == weight.roundToDouble()
      ? weight.toStringAsFixed(0)
      : weight.toStringAsFixed(1);

  static String _shorten(String value, [int max = 90]) {
    final singleLine = value.replaceAll(RegExp(r'\s+'), ' ').trim();
    return singleLine.length <= max
        ? singleLine
        : '${singleLine.substring(0, max)}…';
  }

  /// Keyword router for typed questions. Always returns on-device data.
  String _replyFor(AdvisorLevel level, String question) {
    final academic = academicViewModel;
    if (academic == null || academic.courses.isEmpty) {
      return '**Chưa có dữ liệu học tập.** Chọn chuyên ngành và nhập bảng điểm ở '
          'mục "Dữ liệu học tập" để mình trả lời trên thiết bị.';
    }
    final matches = academic.courses
        .where((course) => question.contains(course.code.toLowerCase()))
        .toList();
    if (matches.isNotEmpty) {
      final course = matches.first;
      if (_hasAny(question, const [
        'đầu điểm',
        'bài kiểm tra',
        'bài test',
        'đánh giá',
        'trọng số',
        'thi',
      ])) {
        return _courseAssessments(course);
      }
      if (_hasAny(question, const [
        'slot',
        'nội dung',
        'tài liệu',
        'nhiệm vụ',
      ])) {
        return _courseSlots(course);
      }
      if (_hasAny(question, const ['tiên quyết', 'điều kiện', 'prerequisite'])) {
        return _coursePrerequisites(academic, course);
      }
      if (_hasAny(question, const ['gpa', 'điểm', 'trung bình'])) {
        return _courseGrade(academic, course);
      }
      if (_hasAny(question, const ['bí kíp', 'kinh nghiệm', 'mẹo'])) {
        return _courseTips(course);
      }
      return _courseSummary(academic, course);
    }
    final askedCodes = RegExp(r'\b[a-z]{2,4}\d{3,4}\b')
        .allMatches(question)
        .map((match) => match.group(0)!.toUpperCase())
        .toSet();
    if (askedCodes.isNotEmpty) {
      return '### Chưa thấy môn ${askedCodes.join(', ')} trong danh mục\n\n'
          'Mã này không có trong danh mục môn của ngành bạn đang học, nên mình '
          'không đọc được đề cương để trả lời.\n\n'
          'Bấm **Hỏi nhanh trên thiết bị** để chọn đúng môn trong danh mục, '
          'hoặc kiểm tra lại mã môn (ví dụ PRM323, SWP391).';
    }
    if (_hasAny(question, const ['tiên quyết', 'điều kiện', 'prerequisite'])) {
      return _blockedPrerequisites(academic);
    }
    if (_hasAny(question, const [
      'học lại',
      'rớt',
      'chưa qua',
      'nợ môn',
      'retake',
    ])) {
      return _retakes(academic);
    }
    if (_hasAny(question, const ['gpa', 'điểm', 'trung bình'])) {
      return _gpaSummary(academic);
    }
    switch (level) {
      case AdvisorLevel.course:
        final semester = academic.selectedSemester;
        final courses = academic.semesterCourses;
        if (courses.isNotEmpty) {
          return _courseSummary(academic, courses.first);
        }
        return _semesterOverview(academic, semester);
      case AdvisorLevel.semester:
        if (_hasAny(question, const [
          'đầu điểm',
          'bài kiểm tra',
          'đánh giá',
        ])) {
          return _semesterAssessments(academic, academic.selectedSemester);
        }
        return _semesterOverview(academic, academic.selectedSemester);
      case AdvisorLevel.program:
        return _eligibleCourses(academic);
      case AdvisorLevel.score:
        return _gpaSummary(academic);
    }
  }

  static bool _hasAny(String question, List<String> keywords) =>
      keywords.any(question.contains);

  // ── Gemini context and failure mapping ───────────────────────────────────

  /// Builds course syllabus context (30 slots, assessments, LOs) without student PII.
  String _buildSyllabusContext(List<CourseModel> courses, String question) {
    if (courses.isEmpty) return 'Chưa có thông tin danh mục môn học.';
    final q = question.toLowerCase();

    final matched = courses
        .where(
          (c) =>
              q.contains(c.code.toLowerCase()) ||
              (c.id.isNotEmpty && q.contains(c.id.toLowerCase())),
        )
        .toList();

    final buffer = StringBuffer();

    buffer.writeln('CẤU TRÚC CHƯƠNG TRÌNH HỌC HIỆN TẠI (LUÔN ĐÚNG):');
    for (int s = 1; s <= 9; s++) {
      final sCourses = courses.where((c) => c.semester == s).toList();
      if (sCourses.isNotEmpty) {
        buffer.writeln(
          '- Kỳ $s: ${sCourses.map((c) => '${c.code} (${c.name})').join(', ')}',
        );
      }
    }
    buffer.writeln();

    if (matched.isNotEmpty) {
      buffer.writeln('ĐỀ CƯƠNG CHI TIẾT & BÍ KÍP TIỀN BỐI (RAG CONTEXT):');
      for (final course in matched.take(3)) {
        _appendCourseSyllabus(buffer, course, fullDetails: true);
      }
    } else {
      int? targetSem;
      for (int s = 1; s <= 9; s++) {
        if (q.contains('kỳ $s') ||
            q.contains('ky $s') ||
            q.contains('semester $s')) {
          targetSem = s;
          break;
        }
      }

      final relevant = targetSem != null
          ? courses.where((c) => c.semester == targetSem).toList()
          : courses;

      buffer.writeln('Danh mục môn học FPTU liên quan:');
      for (final course in relevant.take(10)) {
        _appendCourseSyllabus(buffer, course, fullDetails: false);
      }

      if (targetSem != null && relevant.isNotEmpty) {
        buffer.writeln(
          '\nĐề cương chi tiết môn tiêu biểu kỳ $targetSem (${relevant.first.code}):',
        );
        _appendCourseSyllabus(buffer, relevant.first, fullDetails: true);
      }
    }

    final raw = buffer.toString();
    return raw.length > 10000 ? raw.substring(0, 10000) : raw;
  }

  void _appendCourseSyllabus(
    StringBuffer buffer,
    CourseModel course, {
    required bool fullDetails,
  }) {
    final prereqText = course.prerequisites.isNotEmpty
        ? course.prerequisites.join(', ')
        : (course.prerequisiteNote.isNotEmpty
              ? 'theo ghi chú đề cương'
              : 'Không');
    buffer.writeln(
      '${course.code} — ${course.name}, ${course.credits} tín chỉ, '
      'kỳ ${course.semester}, tiên quyết: $prereqText'
      '${course.lecturer.isNotEmpty ? ', GV: ${course.lecturer}' : ''}',
    );

    final labs = course.labs;
    if (fullDetails) {
      buffer.writeln('Đánh giá & Điểm thành phần (${labs.length} đầu điểm):');
      for (final lab in labs) {
        buffer.writeln(
          '- ${lab.category.isNotEmpty ? '[${lab.category}] ' : ''}${lab.title}: Trọng số ${lab.weight?.toStringAsFixed(0) ?? '0'}%, thời gian: ${lab.duration}, tiêu chí: ${lab.gradingCriteria}',
        );
      }

      final slots = course.slots;
      buffer.writeln('Đề cương ${slots.length} slots học:');
      if (slots.isEmpty) {
        buffer.writeln('- Chưa cập nhật lịch học chi tiết từ FLM.');
      }
      for (final slot in slots) {
        buffer.write('- Slot ${slot.number}: ${slot.displayTopic}');
        if (slot.materials.isNotEmpty) buffer.write(' · TL: ${slot.materials}');
        if (slot.tasks.isNotEmpty) buffer.write(' · NV: ${slot.tasks}');
        if (slot.cqs.isNotEmpty) buffer.write(' · CQ: ${slot.cqs}');
        buffer.writeln();
      }

      final los = course.learningOutcomes;
      buffer.writeln('Chuẩn đầu ra:');
      if (los.isEmpty) buffer.writeln('- Chưa cập nhật chuẩn đầu ra từ FLM.');
      for (final lo in los) {
        buffer.writeln('- ${lo.name}: ${lo.description}');
      }

      final courseTips = _cachedApprovedTips
          .where((t) => t.courseCode.toUpperCase() == course.code.toUpperCase())
          .toList();
      if (courseTips.isNotEmpty) {
        buffer.writeln(
          'Kinh nghiệm & Bí kíp từ Tiền bối (Đã duyệt bởi Admin):',
        );
        for (final tip in courseTips.take(3)) {
          buffer.writeln(
            '- "${tip.content}"${tip.lecturerTip.isNotEmpty ? ' (GV: ${tip.lecturerTip})' : ''}${tip.examTip.isNotEmpty ? ' (Thi: ${tip.examTip})' : ''}',
          );
        }
      }
      buffer.writeln();
    } else {
      final assessmentsSummary = labs
          .map((l) => '${l.title} (${l.weight?.toStringAsFixed(0) ?? '0'}%)')
          .join('; ');
      buffer.writeln('  + Đánh giá: $assessmentsSummary');
    }
  }

  /// Direct client-side invocation through Firebase AI Logic (Gemini API).
  Future<String> _callFirebaseAi({
    required String question,
    required AdvisorLevel level,
    required String catalogContext,
  }) async {
    final modelName = aiModelLabel;
    final prompt =
        remoteConfigService?.aiAdvisorPrompt ??
        'Bạn là Cố vấn học tập AI (AI Tutor) cho StudyPilot. '
            'Tư vấn dựa trên đề cương từng môn (slot học, trọng số điểm PE/FE, chuẩn đầu ra) và kinh nghiệm từ tiền bối đã được kiểm duyệt. '
            'Quy tắc nghiêm ngặt:\n'
            '1. Tuân thủ nghiêm ngặt ngữ cảnh đề cương và dữ liệu được cung cấp.\n'
            '2. Zero-Hallucination: Tuyệt đối không tự bịa đặt thông tin; nếu không có trong dữ liệu, hãy nói rõ.\n'
            '3. Đưa ra lời khuyên thực tế về cách ôn luyện các kỳ thi khó (Practical Exam PE, Final Exam FE) và các slot học then chốt, cũng như giảng viên được khuyến nghị nếu có trong dữ liệu.\n'
            '4. Định dạng câu trả lời rõ ràng bằng Markdown (bullet points, in đậm từ khóa quan trọng).\n'
            '5. Tuân thủ bảo mật Zero-PII (không yêu cầu hay tiết lộ thông tin cá nhân).';

    final ai = aiService;
    if (ai == null) {
      throw StateError('AI service chưa được cấu hình.');
    }
    final text = await ai.generateText(
      model: modelName,
      systemPrompt: prompt,
      prompt:
          'CẤU TRÚC CHƯƠNG TRÌNH HỌC VÀ ĐỀ CƯƠNG FPTU:\n'
          '<CONTEXT>\n$catalogContext\n</CONTEXT>\n\n'
          'Cấp tư vấn: ${level.label} (${level.id})\n'
          'Câu hỏi sinh viên: $question\n\n'
          'Nhiệm vụ:\n'
          '1. Trả lời câu hỏi sinh viên dựa trên đề cương chi tiết (slot học, bài tập, đầu điểm) và kinh nghiệm tiền bối trong <CONTEXT>.\n'
          '2. Nếu ngữ cảnh không có thông tin, hãy nói rõ không có dữ liệu, không tự suy đoán quy chế hay lịch cá nhân.\n'
          '3. Định dạng markdown rõ ràng, súc tích và hữu ích.',
    );
    return text;
  }

}
