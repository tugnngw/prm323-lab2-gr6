import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_final_gr6/models/course_model.dart';
import 'package:prm393_final_gr6/viewmodels/advisor_viewmodel.dart';
import 'package:prm393_final_gr6/viewmodels/roadmap_viewmodel.dart';

import '../helpers/fake_firestore_service.dart';
import '../helpers/mock_analytics_service.dart';
import '../helpers/mock_auth_service.dart';

/// Regression tests for audit findings S-06 (events fired from build/getters
/// inflate DebugView counts) and S-07 (`is FirebaseAnalyticsService` type
/// checks silently drop events for interface implementations).
///
/// All catalog data is seeded through [FakeFirestoreService] — the ViewModel
/// has no built-in fallback lists anymore (no mockdata in lib/).
void main() {
  group('Analytics fires through the interface (S-07)', () {
    late MockAnalyticsService analytics;
    late FakeFirestoreService firestore;
    late RoadmapViewModel vm;

    setUp(() async {
      analytics = MockAnalyticsService();
      firestore = FakeFirestoreService()
        ..userProfile = {
          'id': 'user_1',
          'major': 'SE',
          'passedCourses': ['PRO192', 'CSD201', 'MAD101'],
        }
        ..courses.add({
          'id': 'PRM323',
          'code': 'PRM323',
          'name': 'Lập trình Di động với Flutter',
          'credits': 3,
          'semester': 5,
          'major': 'SE',
          'prerequisites': ['CSD201', 'PRO192'],
          'totalSlots': 30,
          'completedSlots': 12,
          'currentGrade': 8.5,
        });

      // Signed-in identity through the test fake (auth fakes live in test/).
      vm = RoadmapViewModel(
        authService: MockAuthService(initialUserId: 'user_1'),
        firestoreService: firestore,
        analyticsService: analytics,
      );
      // loadData() is async; one zero-delay pump lets the fake reads settle.
      await Future<void>.delayed(Duration.zero);
    });

    CourseModel course() => vm.findCourseById('PRM323')!;

    test('catalog loads from Firestore only (PRM323 has prerequisites)', () {
      expect(course().prerequisites, isNotEmpty);
      expect(vm.passedCourses, contains('CSD201'));
    });

    test('isEligibleForCourse is pure — no event per call/rebuild', () {
      for (var i = 0; i < 5; i++) {
        vm.isEligibleForCourse(course());
      }
      expect(
        analytics.loggedEvents.where((e) => e['name'] == 'prerequisite_check'),
        isEmpty,
      );
    });

    test('checkEligibilityForCourse logs exactly one event per call', () {
      vm.checkEligibilityForCourse(course());
      final events = analytics.loggedEvents
          .where((e) => e['name'] == 'prerequisite_check')
          .toList();
      expect(events, hasLength(1));
      expect(events.single['parameters']['course_id'], 'PRM323');
    });

    test('findCourseById is pure; logCourseOpened logs once', () {
      vm.findCourseById('PRM323');
      vm.findCourseById('PRM323');
      expect(
        analytics.loggedEvents.where((e) => e['name'] == 'course_view'),
        isEmpty,
      );

      vm.logCourseOpened('PRM323');
      final events = analytics.loggedEvents
          .where((e) => e['name'] == 'course_view')
          .toList();
      expect(events, hasLength(1));
      expect(events.single['parameters']['code'], 'PRM323');
    });

    test('logCourseOpened with unknown id logs nothing', () {
      vm.logCourseOpened('does-not-exist');
      expect(
        analytics.loggedEvents.where((e) => e['name'] == 'course_view'),
        isEmpty,
      );
    });

    test('search_course logs once per settled query, not per keystroke',
        () async {
      vm.setSearchQuery('m');
      vm.setSearchQuery('mo');
      vm.setSearchQuery('mob');
      // Before the debounce settles, nothing is logged.
      expect(
        analytics.loggedEvents.where((e) => e['name'] == 'search_course'),
        isEmpty,
      );

      await Future<void>.delayed(const Duration(milliseconds: 700));
      final events = analytics.loggedEvents
          .where((e) => e['name'] == 'search_course')
          .toList();
      expect(events, hasLength(1));
      expect(events.single['parameters']['query_length'], 3);
      vm.dispose();
    });

    test('empty search never logs', () async {
      vm.setSearchQuery('   ');
      await Future<void>.delayed(const Duration(milliseconds: 700));
      expect(
        analytics.loggedEvents.where((e) => e['name'] == 'search_course'),
        isEmpty,
      );
      vm.dispose();
    });

    test('signed-out with no backend falls to empty state, never mock data',
        () async {
      final vmNoAuth = RoadmapViewModel(analyticsService: analytics);
      await Future<void>.delayed(Duration.zero);
      expect(vmNoAuth.allCourses, isEmpty);
      vmNoAuth.dispose();
    });
  });

  group('Strategy events (rubric §6.4 xem/tạo strategy)', () {
    late MockAnalyticsService analytics;
    late AdvisorViewModel vm;

    setUp(() {
      analytics = MockAnalyticsService();
      vm = AdvisorViewModel(analyticsService: analytics);
    });

    test('opening the simulator logs strategy_view exactly once per tap', () {
      vm.logStrategyOpened();
      vm.logStrategyOpened();
      final events =
          analytics.loggedEvents.where((e) => e['name'] == 'strategy_view');
      expect(events.length, equals(2)); // 2 deliberate opens = 2 events
      expect(events.first['parameters']!['source'], equals('advisor'));
    });

    test('preset applies scores AND logs strategy_preset_applied once', () {
      vm.applyPreset(preset: 'gioi_8_5', prm: 8.5, swp: 8.5, swr: 8.5);
      final e = analytics.loggedEvents
          .singleWhere((ev) => ev['name'] == 'strategy_preset_applied');
      expect(e['parameters']!['preset'], equals('gioi_8_5'));
      // Scores updated but never carried in the event (PII rule).
      expect(vm.predictedSemesterGpa, greaterThanOrEqualTo(8.0));
      expect(e['parameters']!.containsKey('prm'), isFalse);
      expect(e['parameters']!.values.any((v) => v is double), isFalse);
    });

    test('slider-style updateSimulation logs nothing (per-pixel rule)', () {
      vm.updateSimulation(prm: 7.2);
      vm.updateSimulation(prm: 7.3);
      vm.updateSimulation(prm: 7.4);
      expect(
        analytics.loggedEvents
            .where((e) => (e['name'] as String).startsWith('strategy')),
        isEmpty,
      );
    });
  });
}
