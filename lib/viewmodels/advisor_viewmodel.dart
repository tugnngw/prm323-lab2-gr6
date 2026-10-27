import 'package:flutter/foundation.dart';

import '../services/analytics_service.dart';
import '../services/firebase_analytics_service.dart';
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

class AdvisorViewModel extends ChangeNotifier {
  AdvisorViewModel({
    this.remoteConfigService,
    this.analyticsService,
  }) {
    _initDefaults();
  }

  final RemoteConfigService? remoteConfigService;
  final AnalyticsService? analyticsService;

  final List<AdvisorMessage> _messages = [];
  bool _isLoading = false;

  // Simulation State for Semester 5
  double _prmScore = 8.5; // PRM323: 3 credits
  double _swpScore = 8.0; // SWP391: 5 credits
  double _swrScore = 8.0; // SWR302: 3 credits

  // Base academic history of student P02 (Nguyễn Minh Đức)
  final double _priorCumulativeGpa = 7.95;
  final int _priorTotalCredits = 65;

  List<AdvisorMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  bool get isAiEnabled => remoteConfigService?.isAiAdvisorEnabled ?? true;

  double get prmScore => _prmScore;
  double get swpScore => _swpScore;
  double get swrScore => _swrScore;

  /// Calculates predicted term GPA for Semester 5 (total 11 credits)
  double get predictedSemesterGpa {
    const totalCredits = 3 + 5 + 3; // 11
    final weighted = (_prmScore * 3) + (_swpScore * 5) + (_swrScore * 3);
    return weighted / totalCredits;
  }

  /// Calculates new cumulative GPA after Semester 5
  double get predictedCumulativeGpa {
    final priorPoints = _priorCumulativeGpa * _priorTotalCredits;
    final termPoints = (_prmScore * 3) + (_swpScore * 5) + (_swrScore * 3);
    const newTotalCredits = 65 + 11;
    return (priorPoints + termPoints) / newTotalCredits;
  }

  bool get reachesHonorsTarget => predictedCumulativeGpa >= 8.0;

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
    _messages.add(
      const AdvisorMessage(
        id: 'msg_welcome',
        sender: 'ai',
        text:
            'Xin chào Đức! Mình là AI Academic Advisor của bạn tại FPTU. Bạn muốn tư vấn về môn học kỳ 5, chiến lược phân bổ thời gian cho đồ án SWP391, hay mô phỏng GPA để đạt loại Giỏi?',
        timestamp: 'Vừa xong',
        level: 'program',
      ),
    );
  }

  Future<void> askQuestion(String question, {String level = 'course'}) async {
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

    final analytics = analyticsService;
    if (analytics is FirebaseAnalyticsService) {
      analytics.logAdvisorQuery(topic: level);
    }

    // Generate intelligent academic guidance based on question keywords
    await Future<void>.delayed(const Duration(milliseconds: 600));

    String reply;
    final q = question.toLowerCase();

    if (q.contains('swp') || q.contains('đồ án')) {
      reply =
          '💡 **Chiến lược SWP391 (5 tín chỉ - Trọng số cao nhất kỳ 5)**:\n'
          '• Môn này chiếm 45% tổng số tín chỉ kỳ 5 của bạn.\n'
          '• Cần dồn 50% thời gian học tập trong tuần vào Sprint 2.\n'
          '• Đảm bảo hoàn thành đúng hạn các sprint deliverables để giữ điểm từ 8.0 trở lên.';
    } else if (q.contains('prm') || q.contains('mobile') || q.contains('flutter')) {
      reply =
          '📱 **Chiến lược PRM323 (3 tín chỉ)**:\n'
          '• Bạn đã đạt 9.0 (Lab 1) và 8.5 (Lab 2). Rất xuất sắc!\n'
          '• Lab 3 (Firebase + MVVM) và Lab 4 (Patrol Test) quyết định 30% điểm.\n'
          '• Nếu duy trì điểm lab ≥ 8.5, điểm tổng kết môn chắc chắn đạt loại Giỏi (≥ 8.5).';
    } else if (q.contains('gpa') || q.contains('giỏi') || q.contains('mục tiêu')) {
      reply =
          '🎯 **Dự báo mục tiêu GPA kỳ 5**:\n'
          '• GPA tích lũy hiện tại của bạn: **7.95** (Cận kề mốc Giỏi 8.0).\n'
          '• Để GPA tích lũy đạt ≥ 8.0 sau kỳ 5, GPA học kỳ 5 cần đạt tối thiểu **8.10**.\n'
          '• Hãy dùng công cụ **Mô phỏng GPA** bên dưới để thử các kịch bản điểm số!';
    } else {
      reply =
          '📚 **Lời khuyên học tập FPTU**:\n'
          '• Kỳ 5 là kỳ bản lề trước kỳ OJT (Kỳ 6). Kết quả môn SWP391 và PRM323 sẽ được các doanh nghiệp đánh giá rất cao khi phỏng vấn thực tập.\n'
          '• Hãy duy trì lịch học đều đặn và không nghỉ quá 20% số slot để tránh bị cấm thi.';
    }

    _messages.add(
      AdvisorMessage(
        id: 'msg_ai_${DateTime.now().millisecondsSinceEpoch}',
        sender: 'ai',
        text: reply,
        timestamp: 'Vừa xong',
        level: level,
      ),
    );

    _isLoading = false;
    notifyListeners();
  }
}
