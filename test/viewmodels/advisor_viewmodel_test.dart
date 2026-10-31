import 'package:flutter_test/flutter_test.dart';
import 'package:prm323_lab3/viewmodels/advisor_viewmodel.dart';

void main() {
  group('AdvisorViewModel & GPA Strategy Simulator Tests', () {
    late AdvisorViewModel viewModel;

    setUp(() {
      viewModel = AdvisorViewModel();
    });

    test('Initializes with default Semester 5 assumptions', () {
      expect(viewModel.prmScore, equals(8.5));
      expect(viewModel.swpScore, equals(8.0));
      expect(viewModel.swrScore, equals(8.0));
      expect(viewModel.messages.isNotEmpty, isTrue);
    });

    test('Calculates simulated semester GPA accurately', () {
      // Semester 5 credits: PRM (3), SWP (5), SWR (3) -> total 11
      // Weighted points: 8.5*3 + 8.0*5 + 8.0*3 = 25.5 + 40.0 + 24.0 = 89.5
      // Semester GPA = 89.5 / 11 = 8.136...
      expect(viewModel.predictedSemesterGpa, closeTo(8.136, 0.01));
    });

    test('Evaluates Honors target (>= 8.0) from simulated term GPA', () {
      // Production contract (commit 89405be): the sandbox compares the
      // simulated TERM GPA against the honors threshold directly — a real
      // cumulative GPA comes from the transcript, which this build does not
      // fabricate (see AdvisorViewModel.reachesHonorsTarget).
      // Below threshold: PRM 8.0, SWP 7.5, SWR 7.5
      viewModel.updateSimulation(prm: 8.0, swp: 7.5, swr: 7.5);
      // Weighted: 8.0*3 + 7.5*5 + 7.5*3 = 24.0 + 37.5 + 22.5 = 84.0
      // Term GPA: 84.0 / 11 = 7.636... (< 8.0)
      expect(viewModel.predictedSemesterGpa, lessThan(8.0));
      expect(viewModel.reachesHonorsTarget, isFalse);

      // Improve scores: PRM = 9.0, SWP = 8.5, SWR = 8.5
      viewModel.updateSimulation(prm: 9.0, swp: 8.5, swr: 8.5);

      // Weighted: 9.0*3 + 8.5*5 + 8.5*3 = 27.0 + 42.5 + 25.5 = 95.0
      // Term GPA: 95.0 / 11 = 8.636 (>= 8.0)
      expect(viewModel.predictedSemesterGpa, greaterThanOrEqualTo(8.0));
      expect(viewModel.reachesHonorsTarget, isTrue);
    });

    test('Generates specialized advice for SWP391 keyword queries', () async {
      await viewModel.askQuestion('Chiến lược học môn SWP391 thế nào?');

      expect(viewModel.messages.length, greaterThanOrEqualTo(2));
      final lastMsg = viewModel.messages.last;
      expect(lastMsg.sender, equals('ai'));
      expect(lastMsg.text, contains('SWP391'));
      // 5 credits — highest weight in Semester 5; strategy copy mentions it.
      expect(lastMsg.text, contains('tín chỉ'));
    });
  });
}
