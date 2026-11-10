import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/remote_config_service.dart';
import '../services/report_media_storage_service.dart';
import '../models/app_state.dart';
import 'academic_viewmodel.dart';

/// Consultation level for an advisor question — the four levels required by
/// rubric §6.4 (môn học / kỳ học / chương trình / điểm số).
enum AdvisorLevel {
  course('course', 'Môn học'),
  semester('semester', 'Kỳ học'),
  program('program', 'Chương trình'),
  score('score', 'Điểm số');

  const AdvisorLevel(this.id, this.label);

  /// Stable slug used in analytics parameters and message metadata.
  final String id;

  /// Vietnamese label shown in the level selector.
  final String label;

  static AdvisorLevel fromId(String? id) =>
      values.firstWhere((l) => l.id == id, orElse: () => AdvisorLevel.course);
}

class AdvisorMessage {
  const AdvisorMessage({
    required this.id,
    required this.sender, // 'user' or 'ai'
    required this.text,
    required this.timestamp,
    this.level = AdvisorLevel.course,
  });

  final String id;
  final String sender;
  final String text;
  final String timestamp;
  final AdvisorLevel level;
}

/// Combines Gemini guidance from the shared catalog with private calculations
/// on the device.
class AdvisorViewModel extends ChangeNotifier {
  AdvisorViewModel({
    this.remoteConfigService,
    this.academicViewModel,
    this.analyticsService,
    this.authService,
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
      _lastQuestion = null;
      _errorMessage = null;
      _isLoading = false;
      _selectedLevel = AdvisorLevel.course;
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
  String? _lastQuestion;
  AdvisorLevel _lastLevel = AdvisorLevel.course;
  AdvisorLevel _selectedLevel = AdvisorLevel.course;

  /// Share consent (rubric §6.4). [askQuestion] fails closed until the user
  /// has confirmed what is sent; the screen shows the dialog before the first
  /// question and calls [grantConsent] on accept.
  bool _consentGranted = false;

  // Simulation state — hypothetical slider values, NOT stored/real grades.
  double _prmScore = 8.5;
  double _swpScore = 8.0;
  double _swrScore = 8.0;

  List<AdvisorMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isAiEnabled => remoteConfigService?.isAiAdvisorEnabled ?? true;
  bool get hasConsent => _consentGranted;
  bool get usesGemini => askGemini != null;

  /// Currently selected consultation level (drives the UI selector).
  AdvisorLevel get selectedLevel => _selectedLevel;

  /// Last advisor failure; the chat shows it with a Retry action.
  String? get errorMessage => _errorMessage;

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
  /// Advisor's GPA entry point — not from build().
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
            'Xin chào $name! Mình là Cố vấn học tập của bạn tại FPTU. '
            'Chọn cấp tư vấn bên dưới (môn học / kỳ học / chương trình / điểm số) '
            'rồi đặt câu hỏi hoặc dùng gợi ý nhanh. '
            '${usesGemini ? 'Gemini tham khảo danh mục môn. Điểm và lịch của bạn được phân tích riêng trên thiết bị.' : 'Bản này tư vấn theo dữ liệu học tập trên thiết bị.'}',
        timestamp: 'Vừa xong',
        level: AdvisorLevel.program,
      ),
    );
  }

  /// Re-asks the previous question after a failure (retry branch).
  Future<void> retryLastQuestion() async {
    final q = _lastQuestion;
    if (q == null || _errorMessage == null) return;
    await _askQuestion(q, level: _lastLevel, retry: true);
  }

  String _errorId(String question) =>
      'msg_err_${question.hashCode.toUnsigned(32)}';

  Future<void> askQuestion(String question, {AdvisorLevel? level}) =>
      _askQuestion(question, level: level);

  Future<void> _askQuestion(
    String question, {
    AdvisorLevel? level,
    bool retry = false,
  }) async {
    if (_disposed || _isLoading || !isAiEnabled) return;
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
    _lastQuestion = question;
    _lastLevel = useLevel;
    _selectedLevel = useLevel;
    _errorMessage = null;

    if (retry) {
      _messages.removeWhere((message) => message.id == _errorId(question));
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
        await academic.loadData().timeout(const Duration(seconds: 15));
        if (academic.state.state == ViewState.error) {
          throw StateError('Academic source unavailable');
        }
      } else {
        await Future<void>.delayed(const Duration(milliseconds: 600));
      }
      if (_disposed || request != _requestVersion) return;
      final local = _replyFor(useLevel, question.toLowerCase());
      final ask = askGemini;
      String reply = local;
      if (ask != null) {
        if (uid == null || uid != authService?.currentUserId || !isAiEnabled) {
          throw StateError('Phiên hỏi đáp đã thay đổi.');
        }
        final courses = academic?.courses ?? [];
        final matched = courses.where(
          (course) =>
              question.toLowerCase().contains(course.code.toLowerCase()),
        );
        final relevant = matched.isNotEmpty ? matched : courses;
        final catalog = relevant
            .take(25)
            .map(
              (course) =>
                  '${course.code} — ${course.name}, ${course.credits} tín chỉ, '
                  'kỳ ${course.semester}, tiên quyết: ${course.prerequisites.join(', ')}',
            )
            .join('\n');
        final answer = await ask(
          uid,
          question,
          useLevel.id,
          catalog.substring(0, catalog.length.clamp(0, 6000)),
        );
        if (_disposed ||
            request != _requestVersion ||
            uid != authService?.currentUserId ||
            !isAiEnabled) {
          return;
        }
        reply = '$answer\n\nĐối chiếu trên thiết bị\n$local';
      }

      _messages.add(
        AdvisorMessage(
          id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
          sender: 'ai',
          text: reply,
          timestamp: 'Vừa xong',
          level: useLevel,
        ),
      );
    } catch (e) {
      if (_disposed || request != _requestVersion) return;
      // Error branch: keep the user's question, post an error bubble + flag
      // for the Retry button. Never pretend a reply succeeded.
      debugPrint('[Advisor] askQuestion failed: ${e.runtimeType}');
      _errorMessage = e is AdvisorRequestException
          ? e.message
          : 'Không nhận được câu trả lời. Kiểm tra kết nối và thử lại.';
      _messages.add(
        AdvisorMessage(
          id: _errorId(question),
          sender: 'ai',
          text: _errorMessage!,
          timestamp: 'Vừa xong',
          level: useLevel,
        ),
      );
    } finally {
      if (!_disposed && request == _requestVersion) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Deterministic, source-grounded guidance. No academic claims are invented.
  String _replyFor(AdvisorLevel level, String question) {
    final academic = academicViewModel;
    if (academic == null || academic.courses.isEmpty) {
      return '${level.label}: Chưa có dữ liệu học tập để tư vấn. Nhập bảng điểm/lịch học và tải lại danh mục.';
    }
    final profile = academic.profile;
    final source =
        '\nNguồn: danh mục môn Firebase và hồ sơ học tập riêng trên thiết bị.';
    switch (level) {
      case AdvisorLevel.course:
        final matches = academic.courses
            .where((c) => question.contains(c.code.toLowerCase()))
            .toList();
        if (matches.isEmpty) {
          return 'Môn học: Chọn mã môn trong danh mục: ${academic.courses.map((c) => c.code).join(', ')}.$source';
        }
        return matches
                .map((course) {
                  final missing = academic.missingPrerequisites(course);
                  final records = profile.transcript.where(
                    (e) => e.courseCode == course.code,
                  );
                  final schedule = profile.timetable.where(
                    (e) =>
                        e.courseCode.toUpperCase() ==
                        course.code.toUpperCase(),
                  );
                  return '${course.code} — ${course.name}: ${course.credits} tín chỉ.\n'
                      '${missing.isEmpty ? 'Các tiên quyết đã được xác nhận hoặc không yêu cầu.' : 'Chưa xác nhận tiên quyết: ${missing.join(', ')}.'}\n'
                      '${records.isEmpty ? 'Chưa có kết quả môn này trong bảng điểm.' : 'Điểm hiện hành: ${records.last.grade}; ${records.last.passed ? 'đã qua' : 'chưa qua'} theo dữ liệu đã nhập.'}\n'
                      '${schedule.isEmpty ? 'Chưa có lịch học cho môn này.' : 'Có ${schedule.length} buổi trong lịch đã nhập.'}';
                })
                .join('\n\n') +
            source;
      case AdvisorLevel.semester:
        final courses = academic.semesterCourses;
        final credits = courses.fold<int>(0, (sum, c) => sum + c.credits);
        return 'Kỳ học ${academic.selectedSemester ?? 'chưa chọn'}: ${courses.length} môn, $credits tín chỉ trong danh mục.\n'
            '${courses.map((c) => '${c.code} (${c.credits} TC)').join(', ')}.\n'
            '${profile.timetable.isEmpty ? 'Nhập thời khóa biểu để kiểm tra slot trống và trùng lịch.' : 'Có ${profile.timetable.length} buổi học trong lịch của bạn.'}$source';
      case AdvisorLevel.program:
        final eligible = academic.courses.where(
          (c) =>
              academic.missingPrerequisites(c).isEmpty &&
              !profile.completedCodes.contains(c.code),
        );
        final retakes = academic.courses.where(academic.isRetake);
        return 'Chương trình: ${profile.completedCodes.length} mã môn đã được xác nhận qua.\n'
            'Môn chưa qua có dữ liệu học lại: ${retakes.isEmpty ? 'chưa có' : retakes.map((c) => c.code).join(', ')}.\n'
            'Môn chưa hoàn thành và không thiếu tiên quyết: ${eligible.isEmpty ? 'chưa có' : eligible.map((c) => c.code).join(', ')}.\n'
            'Chọn môn trong Chiến lược để đối chiếu lịch; không tự suy đoán quy định học lại.$source';
      case AdvisorLevel.score:
        final gpa = profile.cumulativeGpa;
        return 'Điểm số: ${gpa == null ? 'Chưa có bảng điểm thật để tính GPA.' : 'GPA từ kết quả hiện hành đã nhập: ${gpa.toStringAsFixed(2)}.'}\n'
            'Mục tiêu cá nhân: ${profile.targetGpa.toStringAsFixed(2)}.\n'
            'GPA kỳ mô phỏng: ${academic.plannedGpa?.toStringAsFixed(2) ?? 'chưa đặt điểm dự kiến'}. '
            'Kịch bản không thay đổi bảng điểm và không kết luận danh hiệu học tập.$source';
    }
  }
}
