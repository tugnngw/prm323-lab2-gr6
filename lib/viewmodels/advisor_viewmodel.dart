import 'package:flutter/foundation.dart';

import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/remote_config_service.dart';

class AdvisorMessage {
  const AdvisorMessage({
    required this.id,
    required this.sender, // 'user' or 'ai'
    required this.text,
    required this.timestamp,
    this.level = 'course', // 'course', 'semester', 'program'
  });

  final String id;
  final String sender;
  final String text;
  final String timestamp;
  final String level;
}

/// AI Academic Advisor ViewModel (rule-based guidance, Lab 3).
///
/// No-mockdata policy: this view never fabricates the student's identity or
/// grades. The greeting uses the signed-in account (or a generic one), and the
/// GPA figures are clearly labelled *simulation inputs* — the sandbox, not a
/// claim about the user's real academic record.
class AdvisorViewModel extends ChangeNotifier {
  AdvisorViewModel({
    this.remoteConfigService,
    this.analyticsService,
    this.authService,
  }) {
    _initDefaults();
  }

  final RemoteConfigService? remoteConfigService;
  final AnalyticsService? analyticsService;
  final AuthService? authService;

  final List<AdvisorMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _lastQuestion;

  // Simulation state — hypothetical slider values, NOT stored/real grades.
  double _prmScore = 8.5;
  double _swpScore = 8.0;
  double _swrScore = 8.0;

  List<AdvisorMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isAiEnabled => remoteConfigService?.isAiAdvisorEnabled ?? true;

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

  void updateSimulation({
    double? prm,
    double? swp,
    double? swr,
  }) {
    if (prm != null) _prmScore = prm;
    if (swp != null) _swpScore = swp;
    if (swr != null) _swrScore = swr;
    notifyListeners();
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
            'Xin chào $name! Mình là AI Academic Advisor của bạn tại FPTU. '
            'Bạn muốn tư vấn về môn học kỳ 5, chiến lược phân bổ thời gian cho '
            'đồ án SWP391, hay mô phỏng GPA để đạt loại Giỏi?',
        timestamp: 'Vừa xong',
        level: 'program',
      ),
    );
  }

  /// Re-asks the previous question after a failure (retry branch).
  Future<void> retryLastQuestion() async {
    final q = _lastQuestion;
    if (q == null) return;
    _messages.removeWhere((m) => m.id == _errorId(q));
    await askQuestion(q, level: _lastLevel);
  }

  String _lastLevel = 'course';

  String _errorId(String question) =>
      'msg_err_${question.hashCode.toUnsigned(32)}';

  Future<void> askQuestion(String question, {String level = 'course'}) async {
    _lastQuestion = question;
    _lastLevel = level;
    _errorMessage = null;

    final userMsg = AdvisorMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      sender: 'user',
      text: question,
      timestamp: 'Vừa xong',
      level: level,
    );
    _messages.add(userMsg);
    _isLoading = true;
    notifyListeners();

    analyticsService?.logAdvisorQuery(topic: level);

    try {
      // Generate rule-based academic guidance from question keywords.
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final reply = _replyFor(question.toLowerCase());

      _messages.add(
        AdvisorMessage(
          id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
          sender: 'ai',
          text: reply,
          timestamp: 'Vừa xong',
          level: level,
        ),
      );
    } catch (e) {
      // Error branch: keep the user's question, post an error bubble + flag
      // for the Retry button. Never pretend a reply succeeded.
      debugPrint('[Advisor] askQuestion failed: $e');
      _errorMessage = 'Không nhận được câu trả lời. Vui lòng thử lại.';
      _messages.add(
        AdvisorMessage(
          id: _errorId(question),
          sender: 'ai',
          text: _errorMessage!,
          timestamp: 'Vừa xong',
          level: level,
        ),
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  String _replyFor(String q) {
    if (q.contains('swp') || q.contains('đồ án')) {
      return '💡 **Chiến lược SWP391 (5 tín chỉ - Trọng số cao nhất kỳ 5)**:\n'
          '• Môn này chiếm ~45% tổng tín chỉ kỳ 5.\n'
          '• Nên dồn ~50% thời gian học mỗi tuần cho sprint hiện tại.\n'
          '• Hoàn thành đúng hạn deliverables từng sprint là yếu tố giữ điểm ở mức cao.';
    }
    if (q.contains('prm') || q.contains('mobile') || q.contains('flutter')) {
      return '📱 **Chiến lược PRM323 (3 tín chỉ)**:\n'
          '• Các lab Firebase/MVVM (Lab 3) và Patrol test (Lab 4) chiếm phần lớn điểm quá trình.\n'
          '• Hoàn thành đủ yêu cầu mỗi lab trước deadline thường là điều kiện điểm ≥ 8.5.\n'
          '• Hãy kiểm tra checklist đề bài từng lab trước khi nộp.';
    }
    if (q.contains('gpa') || q.contains('giỏi') || q.contains('mục tiêu')) {
      return '🎯 **Dự báo mục tiêu GPA**:\n'
          '• Mốc Sinh viên Giỏi cần GPA tích lũy ≥ 8.0.\n'
          '• GPA tích lũy thật lấy từ bảng điểm FPT — app chưa đồng bộ bảng điểm nên không tự đoán số liệu của bạn.\n'
          '• Hãy dùng công cụ **Mô phỏng GPA** bên dưới với các kịch bản điểm số để xem xu hướng!';
    }
    return '📚 **Lời khuyên học tập FPTU**:\n'
        '• Các kỳ dự án (SWP391/PRM323) được nhà tuyển dụng đánh giá cao khi phỏng vấn thực tập.\n'
        '• Duy trì lịch học đều đặn và không nghỉ quá 20% số slot để tránh bị cấm thi.';
  }
}
