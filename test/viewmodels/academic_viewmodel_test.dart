import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_final_gr6/models/academic_profile.dart';
import 'package:prm393_final_gr6/models/course_model.dart';
import 'package:prm393_final_gr6/viewmodels/academic_viewmodel.dart';
import 'package:prm393_final_gr6/viewmodels/advisor_viewmodel.dart';
import 'package:prm393_final_gr6/viewmodels/roadmap_viewmodel.dart';

import '../helpers/fake_firestore_service.dart';
import '../helpers/mock_auth_service.dart';

void main() {
  test('current transcript overrides legacy passed prerequisites', () {
    final passed = RoadmapViewModel.parsePassedCourses({
      'passedCourses': ['OLD', 'KEEP'],
      'transcript': [
        {
          'courseCode': 'OLD',
          'credits': 3,
          'grade': 4,
          'semester': 1,
          'passed': false,
        },
        {
          'courseCode': 'NEW',
          'credits': 2,
          'grade': 8,
          'semester': 2,
          'passed': true,
        },
      ],
    });
    expect(passed, {'KEEP', 'NEW'});
  });
  test('missing academic data never invents grades or GPA', () {
    final p = AcademicProfile.fromMap(null);
    expect(p.transcript, isEmpty);
    expect(p.cumulativeGpa, isNull);
  });
  test(
    'GPA uses current imported credit weights and explicit completion status',
    () {
      final profile = AcademicProfile.fromMap({
        'passedCourses': ['OLD'],
        'transcript': [
          {
            'courseCode': 'A',
            'credits': 3,
            'grade': 9,
            'semester': 1,
            'passed': true,
          },
          {
            'courseCode': 'B',
            'credits': 1,
            'grade': 5,
            'semester': 1,
            'passed': false,
          },
          {
            'courseCode': 'OLD',
            'credits': 1,
            'grade': 4,
            'semester': 2,
            'passed': false,
          },
        ],
      });
      expect(profile.cumulativeGpa, closeTo(7.2, 0.001));
      expect(profile.completedCodes, {'A'});
    },
  );
  test('invalid and duplicate transcript rows are rejected before write', () {
    for (final input in [
      'A,3,NaN,1,true',
      'A,3,11,1,true',
      'A,0,8,1,true',
      'A,3,8,1,maybe',
      'A,3,8,1,true\nA,3,9,2,true',
    ]) {
      expect(
        () => AcademicViewModel.parseTranscript(input),
        throwsFormatException,
      );
    }
    expect(AcademicViewModel.parseTranscript(''), isEmpty);
    expect(AcademicViewModel.parseTranscript('ABC,3,8,1,true').single.grade, 8);
  });
  test('save merges private academic data without overwriting unrelated profile fields', () async {
    final auth = MockAuthService(initialUserId: 'owner');
    final store = FakeFirestoreService()
      ..userProfile = {
        'major': 'SE',
        'passedCourses': ['PRE'],
      };
    final vm = AcademicViewModel(authService: auth, firestoreService: store);
    await vm.loadData();
    expect(
      await vm.save(transcript: 'A,3,8,1,true', targetGpa: 8),
      isTrue,
    );
    expect(store.userProfile!['major'], 'SE');
    expect(store.userProfile!['passedCourses'], ['PRE']);
    expect(vm.profile.transcript.single.courseCode, 'A');
    expect(
      await vm.save(transcript: 'bad', targetGpa: 8),
      isFalse,
    );
    expect(vm.profile.transcript, hasLength(1));
    vm.dispose();
    auth.dispose();
  });
  test(
    'strategy uses remote course credits for planned GPA',
    () async {
      final auth = MockAuthService(initialUserId: 'owner');
      final store = FakeFirestoreService()
        ..courses.addAll([
          {
            'id': 'A',
            'code': 'A',
            'name': 'A',
            'credits': 2,
            'semester': 3,
            'major': 'SE',
          },
          {
            'id': 'B',
            'code': 'B',
            'name': 'B',
            'credits': 4,
            'semester': 3,
            'major': 'SE',
          },
        ])
        ..userProfile = {'major': 'SE', 'currentSemester': 3};
      final vm = AcademicViewModel(authService: auth, firestoreService: store);
      await vm.loadData();
      vm.setPlannedGrade('A', 9);
      vm.setPlannedGrade('B', 6);
      expect(vm.plannedCredits, 6);
      expect(vm.plannedGpa, 7);
      vm.dispose();
      auth.dispose();
    },
  );
  test(
    'advisor answers from private records and reports missing data honestly',
    () async {
      final auth = MockAuthService(initialUserId: 'owner');
      final store = FakeFirestoreService()
        ..courses.add({
          'id': 'SE__ABC',
          'code': 'ABC',
          'name': 'Remote name',
          'credits': 7,
          'semester': 2,
          'major': 'SE',
          'prerequisites': ['PRE'],
        })
        ..userProfile = {'major': 'SE'};
      final academic = AcademicViewModel(
        authService: auth,
        firestoreService: store,
      );
      await academic.loadData();
      final vm = AdvisorViewModel(
        academicViewModel: academic,
        authService: auth,
      )..grantConsent();
      await vm.askQuestion('ABC');
      expect(vm.messages.last.text, contains('**Tín chỉ:** 7'));
      expect(vm.messages.last.text, contains('PRE'));
      await vm.askQuestion('GPA', level: AdvisorLevel.score);
      expect(vm.messages.last.text, contains('Chưa có bảng điểm thật'));
      vm.dispose();
      academic.dispose();
      auth.dispose();
    },
  );

  const componentCourse = CourseModel(
    id: 'PRM323',
    code: 'PRM323',
    name: 'Mobile Programming',
    credits: 3,
    semester: 5,
    major: 'SE',
    labs: [
      CourseLab(id: 'lab', title: 'Lab', weight: 30),
      CourseLab(id: 'exam', title: 'Final exam', weight: 70),
    ],
  );

  test('weighted component total requires scores for every weighted lab', () {
    expect(
      AcademicViewModel.weightedTotal(componentCourse, {'lab': 8, 'exam': 6}),
      closeTo(6.6, 0.001),
    );
    expect(componentCourse.labs[0].weight, 30);
    expect(AcademicViewModel.totalWeight(componentCourse), 100);
    expect(AcademicViewModel.weightedTotal(componentCourse, {'lab': 8}), isNull);
    expect(AcademicViewModel.weightedTotal(componentCourse, {}), isNull);
  });

  test('saving component scores persists them and can write the total grade',
      () async {
    final auth = MockAuthService(initialUserId: 'owner');
    final store = FakeFirestoreService()
      ..userProfile = {'currentSemester': 5};
    final vm = AcademicViewModel(authService: auth, firestoreService: store);
    await vm.loadData();

    expect(
      await vm.saveComponentScores(
        course: componentCourse,
        scores: {'lab': 8, 'exam': 6},
      ),
      isTrue,
    );
    expect(
      store.userProfile!['componentScores'],
      {
        'PRM323': {'lab': 8.0, 'exam': 6.0},
      },
    );
    expect(vm.componentScoresFor('prm323'), {'lab': 8.0, 'exam': 6.0});
    expect(vm.profile.transcript, isEmpty);

    expect(
      await vm.saveComponentScores(
        course: componentCourse,
        scores: {'lab': 8, 'exam': 6},
        applyToTranscript: true,
      ),
      isTrue,
    );
    final entry = vm.profile.transcript.single;
    expect(entry.courseCode, 'PRM323');
    expect(entry.credits, 3);
    expect(entry.grade, closeTo(6.6, 0.001));
    expect(entry.semester, 5);
    expect(entry.passed, isTrue);
    expect(
      (store.userProfile!['transcript'] as List).single,
      containsPair('passed', true),
    );

    expect(
      await vm.saveComponentScores(
        course: componentCourse,
        scores: {'lab': 8, 'exam': 4},
        applyToTranscript: true,
      ),
      isTrue,
    );
    expect(vm.profile.transcript.single.grade, closeTo(5.2, 0.001));
    expect(vm.profile.transcript.single.passed, isTrue);

    expect(
      await vm.saveComponentScores(
        course: componentCourse,
        scores: {'lab': 2, 'exam': 3},
        applyToTranscript: true,
      ),
      isTrue,
    );
    expect(vm.profile.transcript.single.passed, isFalse);

    expect(
      await vm.saveComponentScores(
        course: componentCourse,
        scores: {'lab': 12},
      ),
      isFalse,
    );
    expect(vm.lastError, contains('0–10'));

    vm.dispose();
    auth.dispose();
  });
}
