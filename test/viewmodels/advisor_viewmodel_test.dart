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

    test('Calculates semester and cumulative GPA accurately', () {
      // Semester 5 credits: PRM (3), SWP (5), SWR (3) -> total 11
      // Weighted points: 8.5*3 + 8.0*5 + 8.0*3 = 25.5 + 40.0 + 24.0 = 89.5
      // Semester GPA = 89.5 / 11 = 8.136...
      expect(viewModel.predictedSemesterGpa, closeTo(8.136, 0.01));

      // Prior points: 7.95 * 65 = 516.75
      // New cumulative points = 516.75 + 89.5 = 606.25
      // New total credits = 65 + 11 = 76
      // Cumulative GPA = 606.25 / 76 = 7.9769...
      expect(viewModel.predictedCumulativeGpa, closeTo(7.977, 0.01));
      expect(viewModel.reachesHonorsTarget, isFalse); // < 8.0
    });

    test('Evaluates Honors target (>= 8.0) when scores improve', () {
      // Improve scores: PRM = 9.0, SWP = 8.5, SWR = 8.5
      viewModel.updateSimulation(prm: 9.0, swp: 8.5, swr: 8.5);

      // Weighted: 9.0*3 + 8.5*5 + 8.5*3 = 27 + 42.5 + 25.5 = 95.0
      // Term GPA: 95.0 / 11 = 8.636
      // Cumulative: (516.75 + 95.0) / 76 = 611.75 / 76 = 8.0493 (>= 8.0!)
      expect(viewModel.predictedCumulativeGpa, greaterThanOrEqualTo(8.0));
      expect(viewModel.reachesHonorsTarget, isTrue);
    });

    test('Generates specialized advice for SWP391 keyword queries', () async {
      await viewModel.askQuestion('Chiến lược học môn SWP391 thế nào?');

      expect(viewModel.messages.length, greaterThanOrEqualTo(2));
      final lastMsg = viewModel.messages.last;
      expect(lastMsg.sender, equals('ai'));
      expect(lastMsg.text, contains('SWP391'));
      expect(lastMsg.text, contains('Sprint 2'));
    });
  });
}
