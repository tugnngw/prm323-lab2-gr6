import 'dart:async';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_final_gr6/utils/ai_failure_messages.dart';
import 'package:prm393_final_gr6/viewmodels/advisor_viewmodel.dart';
import 'package:prm393_final_gr6/viewmodels/academic_viewmodel.dart';

import '../helpers/fake_firestore_service.dart';
import '../helpers/mock_auth_service.dart';

void main() {
  test('Gemini failures are reported with their concrete cause', () {
    expect(
      describeAiFailure(UnsupportedUserLocation()),
      contains('unsupported-user-location'),
    );
    expect(
      describeAiFailure(
        FirebaseException(
          plugin: 'firebase_app_check',
          code: 'unauthenticated',
        ),
      ),
      contains('unauthenticated'),
    );
    expect(
      describeAiFailure(TimeoutException('Gemini timed out')),
      contains('timeout'),
    );
    expect(
      describeAiFailure(
        ServiceApiNotEnabled('projects/demo'),
      ),
      contains('AI Logic chưa được bật'),
    );
    expect(
      describeAiFailure(
        FirebaseException(
          plugin: 'firebase_app_check',
          code: 'unknown',
          message:
              '-14: Integrity API error (-14): The Play Store needs to be updated.',
        ),
      ),
      allOf(contains('-14'), contains('Play Store')),
    );
    expect(
      describeAiFailure(
        FirebaseException(
          plugin: 'firebase_app_check',
          code: 'unknown',
          message:
              'Error returned from API. code: 403 body: App attestation failed.',
        ),
      ),
      allOf(contains('debug token'), contains('Manage debug tokens')),
    );
  });

  test('AI failure short-circuits later questions to local answers', () async {
    final auth = MockAuthService(initialUserId: 'test-owner');
    final academic = AcademicViewModel(
      authService: auth,
      firestoreService: FakeFirestoreService(),
    );
    var attempts = 0;
    final vm = AdvisorViewModel(
      authService: auth,
      academicViewModel: academic,
      askGemini: (_, _, _, _) async {
        attempts++;
        throw FirebaseException(
          plugin: 'firebase_app_check',
          code: 'unknown',
          message: '-14: Integrity API error',
        );
      },
    )..grantConsent();
    addTearDown(auth.dispose);
    addTearDown(academic.dispose);
    addTearDown(vm.dispose);

    await vm.askQuestion('PRM323');
    expect(vm.aiStatus, AiStatus.unavailable);
    await vm.askQuestion('GPA của tôi?', level: AdvisorLevel.score);
    expect(attempts, 1);
    expect(vm.messages.last.source, AdvisorSource.aiUnavailable);
  });

  test('Local prompt catalog answers course facts without consent', () async {
    final auth = MockAuthService(initialUserId: 'test-owner');
    final store = FakeFirestoreService()
      ..courses.add({
        'id': 'SE__PRM323',
        'code': 'PRM323',
        'name': 'Mobile',
        'credits': 3,
        'semester': 5,
        'major': 'SE',
        'labs': [
          {'id': 'lab', 'title': 'Lab 1', 'weight': 30},
          {'id': 'exam', 'title': 'Final', 'weight': 70},
        ],
      })
      ..userProfile = {'major': 'SE'};
    final academic = AcademicViewModel(
      authService: auth,
      firestoreService: store,
    );
    await academic.loadData();
    final vm = AdvisorViewModel(
      authService: auth,
      academicViewModel: academic,
    );
    addTearDown(auth.dispose);
    addTearDown(academic.dispose);
    addTearDown(vm.dispose);

    await vm.askLocalPrompt(
      LocalQuestionKind.courseAssessments,
      courseCode: 'PRM323',
    );
    expect(vm.hasConsent, isFalse);
    expect(vm.messages.last.source, AdvisorSource.local);
    expect(vm.messages.last.text, contains('Lab 1'));
    expect(vm.messages.last.text, contains('30%'));
  });

  test(
    'retry keeps one question and replaces its error with the answer',
    () async {
      final auth = MockAuthService(initialUserId: 'test-owner');
      final academic = AcademicViewModel(
        authService: auth,
        firestoreService: FakeFirestoreService(),
      );
      var attempts = 0;
      final vm = AdvisorViewModel(
        authService: auth,
        academicViewModel: academic,
        askGemini: (_, _, _, _) async {
          if (++attempts == 1) throw StateError('Unavailable');
          return 'Câu trả lời sau khi thử lại';
        },
      )..grantConsent();
      addTearDown(auth.dispose);
      addTearDown(academic.dispose);
      addTearDown(vm.dispose);

      await vm.askQuestion('PRM323');
      expect(vm.errorMessage, isNotNull);
      expect(
        vm.messages[vm.messages.length - 2].text,
        contains('Không cần mạng'),
      );
      expect(vm.messages.last.source, AdvisorSource.local);
      expect(vm.aiStatus, AiStatus.unavailable);
      await vm.retryLastQuestion();
      expect(
        vm.messages.where((message) => message.sender == 'user'),
        hasLength(1),
      );
      expect(vm.errorMessage, isNull);
      expect(vm.messages.last.text, contains('Câu trả lời sau khi thử lại'));
      await vm.retryLastQuestion();
      expect(attempts, 2);
    },
  );

  test(
    'Gemini receives catalog facts after consent while grades stay local',
    () async {
      final auth = MockAuthService(initialUserId: 'test-owner');
      final store = FakeFirestoreService()
        ..courses.add({
          'id': 'SE__PRM323',
          'code': 'PRM323',
          'name': 'Mobile',
          'credits': 3,
          'semester': 5,
          'major': 'SE',
          'currentGrade': 9.875,
        })
        ..userProfile = {'major': 'SE'};
      final academic = AcademicViewModel(
        authService: auth,
        firestoreService: store,
      );
      var calls = 0;
      final vm = AdvisorViewModel(
        authService: auth,
        academicViewModel: academic,
        askGemini: (uid, question, level, catalog) async {
          calls++;
          expect(uid, 'test-owner');
          expect(question, 'PRM323');
          expect(level, 'course');
          expect(catalog, contains('PRM323 — Mobile, 3 tín chỉ'));
          expect(catalog, isNot(contains('9.875')));
          return 'Kết quả Gemini thử nghiệm';
        },
      );
      addTearDown(auth.dispose);
      addTearDown(academic.dispose);
      addTearDown(vm.dispose);
      await vm.askQuestion('PRM323');
      expect(calls, 0);
      vm.grantConsent();
      await vm.askQuestion('PRM323');
      expect(calls, 1);
      expect(vm.messages.last.text, contains('Kết quả Gemini thử nghiệm'));
    },
  );

  group('AdvisorViewModel & GPA Strategy Simulator Tests', () {
    late AdvisorViewModel viewModel;

    setUp(() async {
      final auth = MockAuthService(initialUserId: 'test-owner');
      final store = FakeFirestoreService()
        ..courses.addAll([
          {
            'id': 'SWP391',
            'code': 'SWP391',
            'name': 'Test project',
            'credits': 5,
            'semester': 5,
            'major': 'SE',
          },
          {
            'id': 'PRM323',
            'code': 'PRM323',
            'name': 'Test mobile',
            'credits': 3,
            'semester': 5,
            'major': 'SE',
          },
        ])
        ..userProfile = {'major': 'SE'};
      final academic = AcademicViewModel(
        authService: auth,
        firestoreService: store,
      );
      await academic.loadData();
      viewModel = AdvisorViewModel(academicViewModel: academic);
      addTearDown(auth.dispose);
      addTearDown(academic.dispose);
      addTearDown(viewModel.dispose);
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
      viewModel.grantConsent();
      await viewModel.askQuestion('Chiến lược học môn SWP391 thế nào?');

      expect(viewModel.messages.length, greaterThanOrEqualTo(2));
      final lastMsg = viewModel.messages.last;
      expect(lastMsg.sender, equals('ai'));
      expect(lastMsg.text, contains('SWP391'));
      // 5 credits — highest weight in Semester 5; strategy copy mentions it.
      expect(lastMsg.text, contains('**Tín chỉ:** 5'));
    });

    test('Exposes the four rubric §6.4 consultation levels', () {
      expect(
        AdvisorLevel.values.map((l) => l.id),
        containsAll(<String>['course', 'semester', 'program', 'score']),
      );
      expect(AdvisorLevel.fromId('score'), AdvisorLevel.score);
      // Unknown/missing slug falls back to course rather than throwing.
      expect(AdvisorLevel.fromId('nope'), AdvisorLevel.course);
      expect(AdvisorLevel.fromId(null), AdvisorLevel.course);
    });

    test('Each level produces a distinct answer', () async {
      viewModel.grantConsent();
      final answers = <String>{};
      for (final level in AdvisorLevel.values) {
        await viewModel.askQuestion('Tư vấn cho tôi', level: level);
        answers.add(viewModel.messages.last.text);
        expect(viewModel.messages.last.level, level);
      }
      expect(answers.length, AdvisorLevel.values.length);
    });

    test(
      'Without consent no question is sent and no bubble is added',
      () async {
        final before = viewModel.messages.length;
        await viewModel.askQuestion('Chiến lược SWP391?');
        expect(viewModel.messages.length, before);
        expect(viewModel.hasConsent, isFalse);
        expect(viewModel.isLoading, isFalse);
      },
    );

    test('grantConsent unlocks asking and is idempotent', () async {
      viewModel.grantConsent();
      viewModel.grantConsent();
      expect(viewModel.hasConsent, isTrue);
      await viewModel.askQuestion('Chiến lược SWP391?');
      expect(viewModel.messages.last.sender, 'ai');
    });

    test('selectLevel drives the default level of the next question', () async {
      viewModel.grantConsent();
      viewModel.selectLevel(AdvisorLevel.score);
      await viewModel.askQuestion('GPA của tôi?');
      expect(viewModel.messages.last.level, AdvisorLevel.score);
      expect(viewModel.selectedLevel, AdvisorLevel.score);
    });
  });
}
