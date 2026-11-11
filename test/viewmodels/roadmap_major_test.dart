import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_final_gr6/viewmodels/roadmap_viewmodel.dart';

import '../helpers/fake_firestore_service.dart';
import '../helpers/mock_auth_service.dart';

void main() {
  group('Dynamic Roadmap & Major Selection Tests', () {
    late FakeFirestoreService firestore;
    late MockAuthService auth;
    late RoadmapViewModel viewModel;

    setUp(() async {
      auth = MockAuthService(initialUserId: 'test_student_1');
      firestore = FakeFirestoreService()
        ..userProfile = {
          'id': 'test_student_1',
          'major': 'SE',
          'passedCourses': ['PRO192', 'CSD201'],
        }
        ..courses.addAll([
          {
            'id': 'PRM323',
            'code': 'PRM323',
            'name': 'Lập trình Di động',
            'credits': 3,
            'semester': 5,
            'major': 'SE',
            'prerequisites': ['PRO192', 'CSD201'],
          },
          {
            'id': 'SWP391',
            'code': 'SWP391',
            'name': 'Dự án Phần mềm',
            'credits': 5,
            'semester': 5,
            'major': 'SE',
            'prerequisites': ['SWT301'],
          },
          {
            'id': 'SWT301',
            'code': 'SWT301',
            'name': 'Kiểm thử Phần mềm',
            'credits': 3,
            'semester': 4,
            'major': 'SE',
            'prerequisites': ['PRO192'],
          },
          {
            'id': 'PRJ301',
            'code': 'PRJ301',
            'name': 'Java Web Application',
            'credits': 3,
            'semester': 4,
            'major': 'SE',
            'prerequisites': ['PRO192'],
          },
          {
            'id': 'EXE101',
            'code': 'EXE101',
            'name': 'Khởi nghiệp 1',
            'credits': 3,
            'semester': 7,
            'major': 'SE',
          },
          {
            'id': 'SEP490',
            'code': 'SEP490',
            'name': 'Đồ án Tốt nghiệp SE',
            'credits': 10,
            'semester': 9,
            'major': 'SE',
          },
          {
            'id': 'SEC301',
            'code': 'SEC301',
            'name': 'An toàn mạng IA',
            'credits': 3,
            'semester': 5,
            'major': 'IA',
          },
        ]);

      viewModel = RoadmapViewModel(
        authService: auth,
        firestoreService: firestore,
      );
      await viewModel.loadData();
    });

    tearDown(() {
      auth.dispose();
      viewModel.dispose();
    });

    test('Initializes with SE major and 9 total semesters', () {
      expect(viewModel.selectedMajor, equals('SE'));
      expect(viewModel.totalSemesters, equals(9));
      expect(viewModel.availableSemesters, equals([1, 2, 3, 4, 5, 6, 7, 8, 9]));
      expect(viewModel.selectedSemester, equals(5));
    });

    test('Filters courses for selected semester and excludes other majors', () {
      // Semester 5 SE courses: PRM323, SWP391 (SEC301 is IA -> filtered out)
      final sem5 = viewModel.filteredCourses;
      expect(sem5.length, equals(2));
      expect(sem5.any((c) => c.code == 'PRM323'), isTrue);
      expect(sem5.any((c) => c.code == 'SWP391'), isTrue);
      expect(sem5.any((c) => c.code == 'SEC301'), isFalse);
    });

    test('Selecting semester 4 dynamically updates filtered courses', () {
      viewModel.selectSemester(4);
      final sem4 = viewModel.filteredCourses;
      expect(sem4.length, equals(2));
      expect(sem4.any((c) => c.code == 'SWT301'), isTrue);
      expect(sem4.any((c) => c.code == 'PRJ301'), isTrue);
    });

    test('Selecting semester 9 shows capstone project', () {
      viewModel.selectSemester(9);
      final sem9 = viewModel.filteredCourses;
      expect(sem9.length, equals(1));
      expect(sem9.first.code, equals('SEP490'));
    });

    test('Switching major to IA adjusts filter, displays IA courses, and persists to user profile', () async {
      await viewModel.selectMajor('IA');
      expect(viewModel.selectedMajor, equals('IA'));
      expect(firestore.userProfile?['major'], equals('IA'));

      viewModel.selectSemester(5);
      final sem5IA = viewModel.filteredCourses;
      expect(sem5IA.any((c) => c.code == 'SEC301'), isTrue);
    });

    test('Selecting major or semester with 0 courses returns empty list without errors', () async {
      await viewModel.selectMajor('AI');
      expect(viewModel.selectedMajor, equals('AI'));
      viewModel.selectSemester(1);
      expect(viewModel.filteredCourses, isEmpty);
    });

    test('findCourseById resolves document id and falls back to course code', () {
      expect(viewModel.findCourseById('PRM323')?.code, equals('PRM323'));
      expect(viewModel.findCourseById('prm323')?.code, equals('PRM323'));
      expect(viewModel.findCourseById('MISSING'), isNull);
    });

    test('Prerequisite check filter isolates courses with prerequisites', () {
      viewModel.selectSemester(5);
      viewModel.togglePrerequisiteFilter();
      expect(viewModel.filterPrerequisitesOnly, isTrue);
      for (final c in viewModel.filteredCourses) {
        expect(c.prerequisites, isNotEmpty);
      }
    });
  });
}
