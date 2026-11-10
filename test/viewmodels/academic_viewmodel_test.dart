import 'package:flutter_test/flutter_test.dart';
import 'package:prm323_lab3/models/academic_profile.dart';
import 'package:prm323_lab3/viewmodels/academic_viewmodel.dart';
import 'package:prm323_lab3/viewmodels/advisor_viewmodel.dart';
import 'package:prm323_lab3/viewmodels/roadmap_viewmodel.dart';

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
  test('missing academic data never invents grades, schedule or GPA', () {
    final p = AcademicProfile.fromMap(null);
    expect(p.transcript, isEmpty);
    expect(p.timetable, isEmpty);
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
  test('timetable checks real overlapping slot ranges and validates rows', () {
    final rows = AcademicViewModel.parseTimetable('A,1,2,2\nB,1,3,1\nC,2,3,1');
    expect(rows[0].overlaps(rows[1]), isTrue);
    expect(rows[0].overlaps(rows[2]), isFalse);
    expect(
      () => AcademicViewModel.parseTimetable('A,8,1,1'),
      throwsFormatException,
    );
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
      await vm.save(transcript: 'A,3,8,1,true', semester: 2, targetGpa: 8),
      isTrue,
    );
    expect(store.userProfile!['major'], 'SE');
    expect(store.userProfile!['passedCourses'], ['PRE']);
    expect(vm.profile.transcript.single.courseCode, 'A');
    expect(
      await vm.save(transcript: 'bad', semester: 2, targetGpa: 8),
      isFalse,
    );
    expect(vm.profile.transcript, hasLength(1));
    vm.dispose();
    auth.dispose();
  });
  test(
    'strategy uses remote course credits and user timetable for conflicts',
    () async {
      final auth = MockAuthService(initialUserId: 'owner');
      final store = FakeFirestoreService()
        ..courses.addAll([
          {'id': 'A', 'code': 'A', 'name': 'A', 'credits': 2, 'semester': 3},
          {'id': 'B', 'code': 'B', 'name': 'B', 'credits': 4, 'semester': 3},
        ])
        ..userProfile = {
          'currentSemester': 3,
          'timetable': [
            {'courseCode': 'A', 'weekday': 1, 'startSlot': 2, 'slotCount': 2},
            {'courseCode': 'B', 'weekday': 1, 'startSlot': 3, 'slotCount': 1},
          ],
        };
      final vm = AcademicViewModel(authService: auth, firestoreService: store);
      await vm.loadData();
      vm.setPlannedGrade('A', 9);
      vm.setPlannedGrade('B', 6);
      expect(vm.plannedCredits, 6);
      expect(vm.plannedGpa, 7);
      expect(vm.conflicts, hasLength(1));
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
          'id': 'ABC',
          'code': 'ABC',
          'name': 'Remote name',
          'credits': 7,
          'semester': 2,
          'prerequisites': ['PRE'],
        });
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
      expect(vm.messages.last.text, contains('7 tín chỉ'));
      expect(vm.messages.last.text, contains('PRE'));
      await vm.askQuestion('GPA', level: AdvisorLevel.score);
      expect(vm.messages.last.text, contains('Chưa có bảng điểm thật'));
      vm.dispose();
      academic.dispose();
      auth.dispose();
    },
  );
}
