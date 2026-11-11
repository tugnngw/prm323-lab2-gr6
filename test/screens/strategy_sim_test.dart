import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:prm393_final_gr6/screens/strategy_sim_screen.dart';
import 'package:prm393_final_gr6/viewmodels/academic_viewmodel.dart';

import '../helpers/fake_firestore_service.dart';
import '../helpers/mock_auth_service.dart';

void main() {
  Future<AcademicViewModel> pumpScreen(
    WidgetTester tester,
    FakeFirestoreService store,
  ) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final auth = MockAuthService(initialUserId: 'owner-a');
    final vm = AcademicViewModel(authService: auth, firestoreService: store);
    await vm.loadData();
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: const MaterialApp(home: StrategySimScreen()),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(auth.dispose);
    addTearDown(vm.dispose);
    return vm;
  }

  FakeFirestoreService seededStore() => FakeFirestoreService()
    ..courses.addAll([
      {
        'id': 'SE__ABC',
        'code': 'ABC',
        'name': 'Alpha',
        'credits': 3,
        'semester': 3,
        'major': 'SE',
      },
      {
        'id': 'SE__DEF',
        'code': 'DEF',
        'name': 'Delta',
        'credits': 2,
        'semester': 3,
        'major': 'SE',
      },
      {
        'id': 'SE__GHI',
        'code': 'GHI',
        'name': 'Gamma',
        'credits': 3,
        'semester': 4,
        'major': 'SE',
      },
    ])
    ..userProfile = {
      'major': 'SE',
      'currentSemester': 3,
      'transcript': [
        {
          'courseCode': 'ABC',
          'credits': 3,
          'grade': 8,
          'semester': 3,
          'passed': true,
        },
        {
          'courseCode': 'OLD',
          'credits': 4,
          'grade': 6,
          'semester': 2,
          'passed': true,
        },
      ],
    };

  testWidgets('semester mode reuses transcript grades and only asks for missing '
      'ones', (tester) async {
    final vm = await pumpScreen(tester, seededStore());

    expect(find.text('GPA kỳ 3'), findsOneWidget);
    // ABC already has a real grade: shown read-only, not as an input.
    expect(find.text('Điểm trong bảng điểm · 3 tín chỉ'), findsOneWidget);
    expect(find.text('8.0'), findsOneWidget);
    // DEF has no grade yet, so the screen offers an entry action.
    expect(find.text('Nhập điểm dự kiến'), findsOneWidget);
    // The old timetable-conflict section is gone.
    expect(find.textContaining('Đối chiếu thời khóa biểu'), findsNothing);

    await tester.tap(find.text('Nhập điểm dự kiến'));
    await tester.pumpAndSettle();
    expect(vm.plannedGrade('DEF'), 5);
    // (8.0 × 3 + 5.0 × 2) / 5 credits = 6.8
    expect(find.text('6.80'), findsOneWidget);
  });

  testWidgets('cumulative mode counts transcripts from every semester plus '
      'hypothetical grades', (tester) async {
    final vm = await pumpScreen(tester, seededStore());
    await tester.tap(find.text('Nhập điểm dự kiến'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('GPA tích lũy'));
    await tester.pumpAndSettle();

    // (8×3 + 6×4 + 5×2) / 9 credits = 6.44, including the kỳ 2 course.
    expect(find.text('6.44'), findsOneWidget);
    expect(find.textContaining('9 tín chỉ được tính'), findsOneWidget);
    expect(find.text('Điểm đã có trong bảng điểm'), findsOneWidget);
    expect(find.textContaining('OLD'), findsOneWidget);
    expect(vm.plannedGrade('DEF'), 5);
  });
}
