import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:prm393_final_gr6/screens/academic_profile_screen.dart';
import 'package:prm393_final_gr6/viewmodels/academic_viewmodel.dart';
import 'package:prm393_final_gr6/viewmodels/roadmap_viewmodel.dart';

import '../helpers/fake_firestore_service.dart';
import '../helpers/mock_auth_service.dart';

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _openTab(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

void main() {
  group('AcademicProfileScreen form entry', () {
    late FakeFirestoreService firestore;
    late MockAuthService auth;
    late AcademicViewModel academicVm;
    late RoadmapViewModel roadmapVm;

    setUp(() async {
      auth = MockAuthService(initialUserId: 'user_grades');
      firestore = FakeFirestoreService()
        ..userProfile = {
          'id': 'user_grades',
          'major': 'SE',
          'targetGpa': 8,
          'currentSemester': 5,
          'transcript': [
            {
              'courseCode': 'PRO192',
              'credits': 3,
              'grade': 7.5,
              'semester': 1,
              'passed': true,
            },
          ],
        }
        ..majors.add({
          'code': 'SE',
          'name': 'Kỹ thuật phần mềm',
          'totalSemesters': 9,
        })
        ..courses.add({
          'id': 'SE__PRM323',
          'code': 'PRM323',
          'name': 'Lập trình Di động Flutter',
          'credits': 3,
          'semester': 5,
          'major': 'SE',
        });
      academicVm = AcademicViewModel(
        authService: auth,
        firestoreService: firestore,
      );
      roadmapVm = RoadmapViewModel(
        authService: auth,
        firestoreService: firestore,
      );
      await academicVm.loadData();
      await roadmapVm.loadData();
    });

    tearDown(() {
      auth.dispose();
      academicVm.dispose();
      roadmapVm.dispose();
    });

    Widget createWidgetUnderTest() {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AcademicViewModel>.value(value: academicVm),
          ChangeNotifierProvider<RoadmapViewModel>.value(value: roadmapVm),
        ],
        child: const MaterialApp(home: AcademicProfileScreen()),
      );
    }

    testWidgets('Renders major and grade form without timetable', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Chuyên ngành'), findsOneWidget);
      expect(find.text('Kỹ thuật phần mềm'), findsOneWidget);
      expect(
        find.textContaining('SE · 9 kỳ học'),
        findsOneWidget,
      );

      await _openTab(tester, 'Bảng điểm');
      expect(find.text('Bảng điểm (tùy chọn)'), findsOneWidget);
      await _scrollTo(tester, find.text('GPA tích lũy (tự tính): 7.50 / 10'));
      expect(find.text('GPA tích lũy (tự tính): 7.50 / 10'), findsOneWidget);
      expect(find.text('Thời khóa biểu (tùy chọn)'), findsNothing);
      expect(find.text('Thêm buổi học'), findsNothing);
    });

    testWidgets('Adding a course autofills credits and saves passed status', (
      tester,
    ) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      await _openTab(tester, 'Bảng điểm');

      await _scrollTo(tester, find.text('Thêm môn vào bảng điểm'));
      await tester.tap(find.text('Thêm môn vào bảng điểm'));
      await tester.pumpAndSettle();

      final codeField = find.widgetWithText(TextField, 'Mã môn').last;
      await _scrollTo(tester, codeField);
      await tester.enterText(codeField, 'PRM323');
      await tester.pumpAndSettle();

      final creditsField = find.widgetWithText(TextField, 'Tín chỉ').last;
      final credits = tester.widget<TextField>(creditsField).controller!.text;
      expect(credits, '3');

      await tester.enterText(
        find.widgetWithText(TextField, 'Điểm (0–10)').last,
        '8.5',
      );
      await tester.pumpAndSettle();

      await _scrollTo(tester, find.text('Lưu dữ liệu học tập riêng tư'));
      await tester.tap(find.text('Lưu dữ liệu học tập riêng tư'));
      await tester.pumpAndSettle();

      final transcript =
          (firestore.userProfile!['transcript'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
      final saved = transcript.firstWhere(
        (row) => row['courseCode'] == 'PRM323',
      );
      expect(saved['credits'], 3);
      expect(saved['grade'], 8.5);
      expect(saved['semester'], 5);
      expect(saved['passed'], true);
      expect(find.text('Đã lưu dữ liệu học tập của bạn.'), findsOneWidget);
    });

    testWidgets('Rejects invalid grade before saving', (tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();
      await _openTab(tester, 'Bảng điểm');

      await _scrollTo(tester, find.text('Thêm môn vào bảng điểm'));
      await tester.tap(find.text('Thêm môn vào bảng điểm'));
      await tester.pumpAndSettle();

      await _scrollTo(tester, find.widgetWithText(TextField, 'Mã môn').last);
      await tester.enterText(
        find.widgetWithText(TextField, 'Mã môn').last,
        'PRM323',
      );
      await tester.enterText(
        find.widgetWithText(TextField, 'Điểm (0–10)').last,
        '12',
      );
      await tester.pumpAndSettle();

      await _scrollTo(tester, find.text('Lưu dữ liệu học tập riêng tư'));
      await tester.tap(find.text('Lưu dữ liệu học tập riêng tư'));
      await tester.pumpAndSettle();

      expect(
        find.text('Môn PRM323: điểm phải nằm trong khoảng 0–10.'),
        findsOneWidget,
      );
      final transcript =
          (firestore.userProfile!['transcript'] as List<dynamic>)
              .cast<Map<String, dynamic>>();
      expect(transcript.any((row) => row['courseCode'] == 'PRM323'), isFalse);
    });
  });
}
