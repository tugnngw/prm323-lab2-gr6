import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:prm323_lab3/screens/schedule_screen.dart';
import 'package:prm323_lab3/screens/session_editor_screen.dart';
import 'package:prm323_lab3/viewmodels/academic_viewmodel.dart';
import 'package:prm323_lab3/widgets/app_button.dart';

import '../helpers/fake_firestore_service.dart';
import '../helpers/mock_auth_service.dart';

void main() {
  Future<AcademicViewModel> pumpWith(
    WidgetTester tester,
    Widget screen, {
    Map<String, dynamic>? profile,
  }) async {
    final auth = MockAuthService(initialUserId: 'owner');
    final store = FakeFirestoreService()..userProfile = profile;
    final vm = AcademicViewModel(authService: auth, firestoreService: store);
    await vm.loadData();
    await tester.pumpWidget(
      ChangeNotifierProvider<AcademicViewModel>.value(
        value: vm,
        child: MaterialApp(home: screen),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(() {
      vm.dispose();
      auth.dispose();
    });
    return vm;
  }

  testWidgets('weekly view shows saved sessions and the empty state', (
    tester,
  ) async {
    await pumpWith(tester, const ScheduleScreen());
    expect(find.textContaining('Chưa có buổi học nào'), findsOneWidget);

    await pumpWith(
      tester,
      const ScheduleScreen(),
      profile: {
        'timetable': [
          {
            'id': 's1',
            'courseCode': 'PRM323',
            'courseName': 'Lập trình di động',
            'weekday': 2,
            'startTime': '07:30',
            'endTime': '09:00',
            'room': 'AL-R302',
          },
        ],
      },
    );
    expect(find.textContaining('PRM323'), findsOneWidget);
    expect(find.textContaining('Phòng AL-R302'), findsOneWidget);
  });

  testWidgets('editor rejects an empty required field before saving', (
    tester,
  ) async {
    final vm = await pumpWith(tester, const SessionEditorScreen());
    await tester.scrollUntilVisible(
      find.byType(AppButton),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('1. Thông tin môn học'),
      -300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Nhập mã môn, ví dụ PRM323.'), findsOneWidget);
    expect(find.text('Nhập tên môn học.'), findsOneWidget);
    expect(vm.timetable, isEmpty);
  });

  testWidgets('unverified slot warning is visible in the editor', (
    tester,
  ) async {
    final vm = await pumpWith(tester, const SessionEditorScreen());
    expect(find.textContaining('giá trị mẫu'), findsOneWidget);
    expect(vm.slotCatalog.verified, isFalse);
  });

  testWidgets('editing a session prefills it and keeps saving to one row', (
    tester,
  ) async {
    final vm = await pumpWith(
      tester,
      const ScheduleScreen(),
      profile: {
        'timetable': [
          {
            'id': 's1',
            'courseCode': 'A',
            'courseName': 'Alpha',
            'weekday': 1,
            'startTime': '07:30',
            'endTime': '09:00',
          },
          {
            'id': 's2',
            'courseCode': 'B',
            'courseName': 'Beta',
            'weekday': 3,
            'startTime': '13:00',
            'endTime': '15:00',
          },
        ],
      },
    );
    await tester.tap(find.textContaining('A · Alpha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sửa buổi học'));
    await tester.pumpAndSettle();

    expect(find.text('Sửa buổi học'), findsOneWidget);
    expect(find.text('Alpha'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byType(AppButton),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(vm.timetable, hasLength(2));
    expect(vm.timetable.first.id, 's1');
    expect(vm.timetable.last.courseCode, 'B');
  });

  testWidgets('week navigation moves forward, back and returns to now', (
    tester,
  ) async {
    await pumpWith(
      tester,
      const ScheduleScreen(),
      profile: {
        'timetable': [
          {
            'id': 's1',
            'courseCode': 'A',
            'courseName': 'Alpha',
            'weekday': 1,
            'startTime': '07:30',
            'endTime': '09:00',
          },
        ],
      },
    );
    final firstLabel = tester
        .widget<Text>(find.textContaining('Tuần '))
        .data!;
    await tester.tap(find.byTooltip('Tuần sau'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.textContaining('Tuần ')).data,
        isNot(firstLabel));
    await tester.tap(find.byTooltip('Tuần trước'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.textContaining('Tuần ')).data, firstLabel);
    await tester.tap(find.text('Về tuần này'));
    await tester.pumpAndSettle();
    expect(tester.widget<Text>(find.textContaining('Tuần ')).data, firstLabel);
  });

  testWidgets('deleting a session confirms first and leaves the others', (
    tester,
  ) async {
    final vm = await pumpWith(
      tester,
      const ScheduleScreen(),
      profile: {
        'timetable': [
          {
            'id': 's1',
            'courseCode': 'A',
            'courseName': 'Alpha',
            'weekday': 1,
            'startTime': '07:30',
            'endTime': '09:00',
          },
          {
            'id': 's2',
            'courseCode': 'B',
            'courseName': 'Beta',
            'weekday': 3,
            'startTime': '13:00',
            'endTime': '15:00',
          },
        ],
      },
    );
    await tester.tap(find.textContaining('A · Alpha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xóa buổi học'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Các buổi khác của môn này'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Xóa'));
    await tester.pumpAndSettle();

    expect(vm.timetable.single.courseCode, 'B');
    expect(find.textContaining('A · Alpha'), findsNothing);
  });

  testWidgets('duplicate opens a prefilled editor and saves a new id', (
    tester,
  ) async {
    final vm = await pumpWith(
      tester,
      const ScheduleScreen(),
      profile: {
        'timetable': [
          {
            'id': 's1',
            'courseCode': 'A',
            'courseName': 'Alpha',
            'weekday': 2,
            'startTime': '07:30',
            'endTime': '09:00',
            'room': 'AL-101',
          },
        ],
      },
    );
    await tester.tap(find.textContaining('A · Alpha'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nhân bản & sửa'));
    await tester.pumpAndSettle();

    // Prefilled copy, then the user picks another weekday before saving.
    expect(find.text('Thêm buổi học'), findsWidgets);
    await tester.tap(find.text('Thứ *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Thứ 5').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byType(AppButton),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byType(AppButton));
    await tester.pumpAndSettle();

    expect(vm.timetable, hasLength(2));
    expect(vm.timetable.map((e) => e.id).toSet(), hasLength(2));
    expect(vm.timetable.first.id, 's1');
    expect(vm.timetable.first.room, 'AL-101');
    // 'Thứ 5' is ISO weekday 4.
    expect(vm.timetable.last.weekday, 4);
  });

  testWidgets('selecting a slot fills its start and end time', (tester) async {
    final vm = await pumpWith(tester, const SessionEditorScreen());
    final slot = vm.slotCatalog.byNumber(2)!;
    await tester.tap(find.text('Slot'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('${slot.label} (${slot.range})').last);
    await tester.pumpAndSettle();
    expect(find.text(slot.start), findsOneWidget);
    expect(find.text(slot.end), findsOneWidget);
  });
}
