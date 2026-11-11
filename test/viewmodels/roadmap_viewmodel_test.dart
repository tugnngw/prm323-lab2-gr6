import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_final_gr6/models/course_model.dart';
import 'package:prm393_final_gr6/viewmodels/roadmap_viewmodel.dart';

import '../helpers/mock_auth_service.dart';
import '../helpers/mock_firestore_service.dart';

class _DeniedFirestore extends MockFirestoreService {
  @override
  Future<void> saveCourseProgress(
    String userId,
    String courseDocId,
    Map<String, dynamic> data,
  ) async {
    throw FirebaseException(
      plugin: 'cloud_firestore',
      code: 'permission-denied',
    );
  }
}

void main() {
  group('RoadmapViewModel Tests', () {
    late RoadmapViewModel viewModel;

    setUp(() async {
      final auth = MockAuthService();
      final firestore = MockFirestoreService();
      viewModel = RoadmapViewModel(
        authService: auth,
        firestoreService: firestore,
      );
      await viewModel.loadData();
      addTearDown(auth.dispose);
      addTearDown(viewModel.dispose);
    });

    test('Loads default semester 5 courses on initialization', () async {
      expect(viewModel.allCourses.isNotEmpty, isTrue);
      expect(viewModel.allCourses.any((c) => c.code == 'PRM323'), isTrue);
      expect(viewModel.allCourses.any((c) => c.code == 'SWP391'), isTrue);
    });

    test('Correctly evaluates prerequisite eligibility for Student P02', () {
      // P02 passed: PRO192, CSD201, MAD101, OSG202, NWC203c, SSG104
      const prm = CourseModel(
        id: 'PRM323',
        code: 'PRM323',
        name: 'Mobile Programming',
        credits: 3,
        semester: 5,
        major: 'SE',
        totalSlots: 30,
        completedSlots: 12,
        prerequisites: ['PRO192', 'CSD201'],
      );

      const swp = CourseModel(
        id: 'SWP391',
        code: 'SWP391',
        name: 'Software Project',
        credits: 5,
        semester: 5,
        major: 'SE',
        totalSlots: 30,
        completedSlots: 10,
        prerequisites: ['CSD201', 'SWE201c'],
      );

      // PRM323: P02 has passed both PRO192 and CSD201 -> Eligible
      expect(viewModel.isEligibleForCourse(prm), isTrue);
      expect(viewModel.getMissingPrerequisites(prm), isEmpty);

      // SWP391: P02 has passed CSD201 but NOT SWE201c -> Missing SWE201c
      expect(viewModel.isEligibleForCourse(swp), isFalse);
      expect(viewModel.getMissingPrerequisites(swp), contains('SWE201c'));
    });

    test('Calculates course slot progress correctly', () {
      const course = CourseModel(
        id: 'c1',
        code: 'TEST101',
        name: 'Test Course',
        credits: 3,
        semester: 5,
        major: 'SE',
        totalSlots: 30,
        completedSlots: 15,
      );

      expect(course.progress, closeTo(0.5, 0.001));
    });

    test('Prerequisite matching ignores case for FLM suffix codes', () {
      final passed = RoadmapViewModel.parsePassedCourses({
        'transcript': [
          {
            'courseCode': 'dms301m',
            'credits': 3,
            'grade': 8,
            'semester': 1,
            'passed': true,
          },
        ],
      });
      expect(passed, contains('DMS301M'));
    });

    test(
      'failed progress write reverts and names the Firestore error code',
      () async {
        final auth = MockAuthService();
        final firestore = _DeniedFirestore();
        final vm = RoadmapViewModel(
          authService: auth,
          firestoreService: firestore,
        );
        await vm.loadData();
        addTearDown(auth.dispose);
        addTearDown(vm.dispose);

        final course = vm.allCourses.first;
        final ok = await vm.setSlotCompleted(course, 1, completed: true);

        expect(ok, isFalse);
        expect(vm.completedSlotsFor(course), isEmpty);
        expect(vm.lastError, contains('permission-denied'));
      },
    );
  });
}
