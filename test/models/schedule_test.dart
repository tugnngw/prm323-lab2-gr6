import 'package:flutter_test/flutter_test.dart';
import 'package:prm323_lab3/models/academic_profile.dart';
import 'package:prm323_lab3/models/schedule_rules.dart';
import 'package:prm323_lab3/models/slot_catalog.dart';
import 'package:prm323_lab3/viewmodels/academic_viewmodel.dart';

import '../helpers/fake_firestore_service.dart';
import '../helpers/mock_auth_service.dart';

TimetableEntry session({
  String id = '',
  String code = 'PRM323',
  int weekday = 2,
  int? slot = 1,
  String start = '07:30',
  String end = '09:00',
}) => TimetableEntry(
  id: id,
  courseCode: code,
  courseName: 'Course $code',
  weekday: weekday,
  slotNumber: slot,
  startTime: start,
  endTime: end,
);

void main() {
  group('slot catalog', () {
    test('slot selection maps to its start and end time', () {
      const catalog = SlotCatalog.sampleDefault;
      expect(catalog.byNumber(1)!.start, '07:30');
      expect(catalog.byNumber(1)!.end, '09:00');
      expect(catalog.contains(99), isFalse);
    });
    test('sample catalog is flagged unverified', () {
      expect(SlotCatalog.sampleDefault.verified, isFalse);
      expect(SlotCatalog.sampleDefault.sourceNote, isNotEmpty);
    });
  });

  group('validation', () {
    Map<String, String> validate({
      String code = 'PRM323',
      String name = 'Mobile',
      int? weekday = 2,
      int? slot = 1,
      String start = '07:30',
      String end = '09:00',
      String? from,
      String? to,
    }) => ScheduleRules.validate(
      courseCode: code,
      courseName: name,
      weekday: weekday,
      slotNumber: slot,
      startTime: start,
      endTime: end,
      catalog: SlotCatalog.sampleDefault,
      effectiveStart: from,
      effectiveEnd: to,
    );

    test('empty code or name is rejected', () {
      expect(validate(code: '  '), contains('courseCode'));
      expect(validate(name: ''), contains('courseName'));
    });
    test('end time must be after start time', () {
      expect(validate(start: '09:00', end: '09:00'), contains('endTime'));
      expect(validate(start: '10:00', end: '09:00'), contains('endTime'));
      expect(validate(), isEmpty);
    });
    test('malformed clock values are rejected', () {
      expect(validate(start: '7h30'), contains('startTime'));
      expect(validate(end: '24:00'), contains('endTime'));
    });
    test('slot outside the catalog is rejected', () {
      expect(validate(slot: 42), contains('slotNumber'));
    });
    test('weekday must be 1..7', () {
      expect(validate(weekday: null), contains('weekday'));
      expect(validate(weekday: 8), contains('weekday'));
    });
    test('academic end date cannot precede start date', () {
      expect(validate(from: '2026-09-01', to: '2026-08-01'),
          contains('effectiveEnd'));
      expect(validate(from: '2026-09-01', to: '2026-12-20'), isEmpty);
    });
  });

  group('conflicts', () {
    test('overlapping sessions on the same day are detected', () {
      final a = session(code: 'A', start: '07:30', end: '10:40');
      final b = session(code: 'B', start: '09:10', end: '10:40');
      expect(a.overlaps(b), isTrue);
      expect(ScheduleRules.conflictsWith(b, [a]), hasLength(1));
    });
    test('touching sessions and different days do not conflict', () {
      final a = session(code: 'A', start: '07:30', end: '09:00');
      final b = session(code: 'B', start: '09:00', end: '10:40');
      final other = session(code: 'C', weekday: 3);
      expect(ScheduleRules.conflictsWith(b, [a, other]), isEmpty);
    });
    test('the edited session never conflicts with itself', () {
      final a = session(id: 's1');
      expect(ScheduleRules.conflictsWith(a, [a], ignoreId: 's1'), isEmpty);
    });
    test('overlap inside one course is detected like across courses', () {
      final first = session(code: 'A', start: '07:30', end: '09:00');
      final second = session(code: 'A', start: '08:00', end: '09:30');
      expect(ScheduleRules.conflictsWith(second, [first]), hasLength(1));
    });
    test('same time in non-overlapping effective periods does not conflict',
        () {
      final term1 = session(id: 'a').copyWith(
        effectiveStart: '2026-01-05',
        effectiveEnd: '2026-04-12',
      );
      final term2 = session(id: 'b').copyWith(
        effectiveStart: '2026-05-04',
        effectiveEnd: '2026-08-16',
      );
      final openEnded = session(id: 'c', code: 'C');
      expect(term1.overlaps(term2), isFalse);
      expect(ScheduleRules.conflictsWith(term2, [term1]), isEmpty);
      // An open-ended session spans every term, so it still conflicts.
      expect(ScheduleRules.conflictsWith(openEnded, [term1]), hasLength(1));
    });
    test('duplicate sessions are detected but a different day is allowed',
        () {
      final a = session(code: 'A');
      expect(ScheduleRules.isDuplicate(session(code: 'a'), [a]), isTrue);
      expect(ScheduleRules.isDuplicate(session(code: 'A', weekday: 4), [a]),
          isFalse);
    });
  });

  group('serialization', () {
    test('session round-trips through Firestore map', () {
      final entry = session(
        id: 's1',
        slot: 2,
        start: '09:10',
        end: '10:40',
      ).copyWith(
        room: 'AL-R302',
        campus: 'Hòa Lạc',
        lecturer: 'GV A',
        section: 'SE1810',
        notes: 'mang laptop',
        semester: 5,
        effectiveStart: '2026-09-01',
        effectiveEnd: '2026-12-20',
      );
      final restored = TimetableEntry.fromMap(entry.toMap());
      expect(restored.id, 's1');
      expect(restored.startTime, '09:10');
      expect(restored.endTime, '10:40');
      expect(restored.room, 'AL-R302');
      expect(restored.semester, 5);
      expect(restored.effectiveEnd, '2026-12-20');
    });
    test('legacy startSlot/slotCount rows still deserialize', () {
      final legacy = TimetableEntry.fromMap({
        'courseCode': 'prm323',
        'weekday': 3,
        'startSlot': 2,
        'slotCount': 2,
      });
      expect(legacy.courseCode, 'PRM323');
      expect(legacy.startTime, '09:10');
      // startSlot 2 + slotCount 2 covers slots 2–3, so it ends with slot 3.
      expect(legacy.endTime, '12:20');
      expect(legacy.isLegacy, isTrue);
      expect(legacy.hasValidRange, isTrue);
    });
    test('malformed legacy data is read without throwing', () {
      final noTimes = TimetableEntry.fromMap({
        'courseCode': null,
        'weekday': '2',
        'startSlot': '2',
        'slotCount': '2',
        'room': 123,
      });
      expect(noTimes.courseCode, '');
      expect(noTimes.weekday, 2);
      expect(noTimes.startTime, '09:10');
      expect(noTimes.endTime, '12:20');
      expect(noTimes.room, '123');

      // Only a start time: falls into the legacy branch and takes the sample
      // end for slot 1 rather than throwing.
      final partial = TimetableEntry.fromMap({'startTime': '08:00'});
      expect(partial.courseCode, '');
      expect(partial.weekday, 1);
      expect(partial.endTime, '09:00');
      expect(partial.hasValidRange, isTrue);
      // Blank or impossible times are kept as-is and fail validation later.
      final broken = TimetableEntry.fromMap({
        'courseCode': 'X',
        'startTime': 'aa',
        'endTime': 'bb',
      });
      expect(broken.hasValidRange, isFalse);
      expect(broken.startTime, 'aa');

      // A corrupt row is skipped, the readable one still loads.
      final profile = AcademicProfile.fromMap({
        'timetable': [null, 'garbage', {'courseCode': 'OK', 'weekday': 3}],
      });
      expect(profile.timetable.single.courseCode, 'OK');
    });
    test('legacy profile list loads and keeps the newer schema intact', () {
      final profile = AcademicProfile.fromMap({
        'timetable': [
          {'courseCode': 'A', 'weekday': 1, 'startSlot': 1, 'slotCount': 1},
          {
            'id': 's2',
            'courseCode': 'B',
            'weekday': 2,
            'startTime': '13:00',
            'endTime': '15:00',
          },
        ],
      });
      expect(profile.timetable, hasLength(2));
      expect(profile.timetable.last.endTime, '15:00');
    });
  });

  group('schedule operations', () {
    Future<AcademicViewModel> vmWith(FakeFirestoreService store) async {
      final auth = MockAuthService(initialUserId: 'owner');
      final vm = AcademicViewModel(authService: auth, firestoreService: store);
      await vm.loadData();
      addTearDown(() {
        vm.dispose();
        auth.dispose();
      });
      return vm;
    }

    test('a course can own several weekly sessions', () async {
      final store = FakeFirestoreService();
      final vm = await vmWith(store);
      expect(await vm.addSession(session(code: 'PRM323', weekday: 2)), isTrue);
      expect(
        await vm.addSession(session(code: 'PRM323', weekday: 4, slot: 3)),
        isTrue,
      );
      expect(vm.sessionsFor('prm323'), hasLength(2));
      expect((store.userProfile!['timetable'] as List), hasLength(2));
    });
    test('editing one session keeps unrelated sessions', () async {
      final store = FakeFirestoreService();
      final vm = await vmWith(store);
      await vm.addSession(session(code: 'A', weekday: 2));
      await vm.addSession(session(code: 'B', weekday: 3));
      final edited = vm.timetable.first.copyWith(room: 'BE-201');
      expect(await vm.updateSession(edited), isTrue);
      expect(vm.timetable, hasLength(2));
      expect(vm.timetable.first.room, 'BE-201');
      expect(vm.timetable.last.courseCode, 'B');
    });
    test('deleting a session removes only that session', () async {
      final store = FakeFirestoreService();
      final vm = await vmWith(store);
      await vm.addSession(session(code: 'A', weekday: 2));
      await vm.addSession(session(code: 'A', weekday: 4));
      final target = vm.timetable.first.id;
      expect(await vm.deleteSession(target), isTrue);
      expect(vm.timetable, hasLength(1));
      expect(vm.timetable.single.id, isNot(target));
    });
    test('duplicating a session adds a copy with a new id', () async {
      final store = FakeFirestoreService();
      final vm = await vmWith(store);
      await vm.addSession(session(code: 'A'));
      final original = vm.timetable.single;
      expect(await vm.duplicateSession(original.id), isTrue);
      expect(vm.timetable, hasLength(2));
      expect(vm.timetable.map((e) => e.id).toSet(), hasLength(2));
    });
    test('invalid session is rejected before any write', () async {
      final store = FakeFirestoreService();
      final vm = await vmWith(store);
      expect(
        await vm.addSession(session(code: '', start: '10:00', end: '09:00')),
        isFalse,
      );
      expect(store.userProfile, isNull);
      expect(vm.lastError, isNotNull);
    });
    test('saved conflicts are reported across courses', () async {
      final store = FakeFirestoreService();
      final vm = await vmWith(store);
      await vm.addSession(session(code: 'A', start: '07:30', end: '10:40'));
      await vm.addSession(session(code: 'B', start: '09:10', end: '10:40'));
      expect(vm.allScheduleConflicts, hasLength(1));
      expect(
        vm.allScheduleConflicts.single.description,
        contains('A'),
      );
    });
    test('recurring effective range is persisted per session', () async {
      final store = FakeFirestoreService();
      final vm = await vmWith(store);
      expect(
        await vm.addSession(
          session(code: 'A').copyWith(
            effectiveStart: '2026-09-01',
            effectiveEnd: '2026-12-20',
          ),
        ),
        isTrue,
      );
      final saved =
          (store.userProfile!['timetable'] as List).single as Map;
      expect(saved['effectiveStart'], '2026-09-01');
      expect(saved['effectiveEnd'], '2026-12-20');
    });
    test('legacy schedule still yields conflicts in the viewmodel', () async {
      final store = FakeFirestoreService()
        ..userProfile = {
          'timetable': [
            {'courseCode': 'A', 'weekday': 1, 'startSlot': 2, 'slotCount': 2},
            {'courseCode': 'B', 'weekday': 1, 'startSlot': 3, 'slotCount': 1},
          ],
        };
      final vm = await vmWith(store);
      expect(vm.timetable, hasLength(2));
      expect(vm.allScheduleConflicts, hasLength(1));
    });
    test('legacy sessions lacking ids are editable and deletable', () async {
      final store = FakeFirestoreService()
        ..userProfile = {
          'timetable': [
            {'courseCode': 'A', 'weekday': 1, 'startSlot': 1, 'slotCount': 1},
            {'courseCode': 'B', 'weekday': 3, 'startSlot': 2, 'slotCount': 1},
          ],
        };
      final vm = await vmWith(store);
      expect(vm.timetable.every((e) => e.id.isNotEmpty), isTrue);

      final legacyA = vm.timetable.first;
      expect(await vm.updateSession(legacyA.copyWith(room: 'AL-101')), isTrue);
      expect(vm.timetable.first.room, 'AL-101');
      expect(vm.timetable, hasLength(2));

      expect(await vm.deleteSession(vm.timetable.last.id), isTrue);
      expect(vm.timetable.single.courseCode, 'A');
      // The migrated ids reached the saved document, not just memory.
      final saved = (store.userProfile!['timetable'] as List).single as Map;
      expect(saved['id'], isNotEmpty);
    });
    test('saving a session normalizes clock times to HH:mm', () async {
      final store = FakeFirestoreService();
      final vm = await vmWith(store);
      expect(
        await vm.addSession(session(code: 'A', start: '9:10', end: '10:40')),
        isTrue,
      );
      expect(vm.timetable.single.startTime, '09:10');
      final saved = (store.userProfile!['timetable'] as List).single as Map;
      expect(saved['startTime'], '09:10');
    });
    test('schedule write keeps transcript and unrelated profile fields', () async {
      final store = FakeFirestoreService()
        ..userProfile = {
          'major': 'SE',
          'targetGpa': 7.5,
          'transcript': [
            {
              'courseCode': 'PRE',
              'credits': 3,
              'grade': 8,
              'semester': 1,
              'passed': true,
            },
          ],
        };
      final vm = await vmWith(store);
      expect(await vm.addSession(session(code: 'A')), isTrue);
      expect(store.userProfile!['major'], 'SE');
      expect(store.userProfile!['targetGpa'], 7.5);
      expect(store.userProfile!['transcript'], hasLength(1));
      expect(vm.profile.transcript.single.courseCode, 'PRE');

      // Saving the transcript must not drop the timetable either.
      expect(
        await vm.save(transcript: 'A,3,8,1,true', semester: 2, targetGpa: 8),
        isTrue,
      );
      expect(store.userProfile!['timetable'], hasLength(1));
    });
    test('another user never sees the first user timetable', () async {
      final store = FakeFirestoreService();
      final owner = await vmWith(store);
      await owner.addSession(session(code: 'A'));

      final otherAuth = MockAuthService(initialUserId: 'other');
      final other = AcademicViewModel(
        authService: otherAuth,
        firestoreService: store,
      );
      await other.loadData();
      expect(other.timetable, isEmpty);
      other.dispose();
      otherAuth.dispose();
    });
    test('repeated writes keep exactly one row per session', () async {
      final store = FakeFirestoreService();
      final vm = await vmWith(store);
      await vm.addSession(session(code: 'A', weekday: 2));
      final id = vm.timetable.single.id;
      for (var i = 0; i < 3; i++) {
        expect(
          await vm.updateSession(
            vm.timetable.single.copyWith(room: 'R$i'),
          ),
          isTrue,
        );
      }
      expect(vm.timetable.single.id, id);
      expect(vm.timetable.single.room, 'R2');
      expect(store.userProfile!['timetable'], hasLength(1));
    });
  });
}
