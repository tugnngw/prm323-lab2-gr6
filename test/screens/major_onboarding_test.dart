import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:prm393_final_gr6/screens/major_onboarding_screen.dart';
import 'package:prm393_final_gr6/viewmodels/academic_viewmodel.dart';
import 'package:prm393_final_gr6/viewmodels/auth_viewmodel.dart';
import 'package:prm393_final_gr6/viewmodels/roadmap_viewmodel.dart';

import '../helpers/fake_firestore_service.dart';
import '../helpers/mock_auth_service.dart';

void main() {
  testWidgets('First run requires a major and loads only that curriculum', (
    tester,
  ) async {
    final auth = MockAuthService(initialUserId: 'new_student');
    final firestore = FakeFirestoreService()
      ..userProfile = {'id': 'new_student'}
      ..majors.addAll([
        {
          'code': 'SE',
          'name': 'Kỹ thuật phần mềm',
          'totalSemesters': 9,
        },
        {
          'code': 'MKT',
          'name': 'Digital Marketing',
          'totalSemesters': 9,
        },
      ])
      ..courses.addAll([
        {
          'id': 'SE__PRM323',
          'code': 'PRM323',
          'name': 'Lập trình Di động',
          'credits': 3,
          'semester': 5,
          'major': 'SE',
        },
        {
          'id': 'MKT__MKT101',
          'code': 'MKT101',
          'name': 'Marketing căn bản',
          'credits': 3,
          'semester': 1,
          'major': 'MKT',
        },
      ]);
    final academic = AcademicViewModel(
      authService: auth,
      firestoreService: firestore,
    );
    final roadmap = RoadmapViewModel(
      authService: auth,
      firestoreService: firestore,
    );
    final authVm = AuthViewModel(authService: auth);
    await academic.loadData();
    await roadmap.loadData();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthViewModel>.value(value: authVm),
          ChangeNotifierProvider<AcademicViewModel>.value(value: academic),
          ChangeNotifierProvider<RoadmapViewModel>.value(value: roadmap),
        ],
        child: const MaterialApp(home: MajorOnboardingScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chọn chuyên ngành'), findsOneWidget);
    expect(find.text('Kỹ thuật phần mềm'), findsOneWidget);
    expect(find.text('Digital Marketing'), findsOneWidget);
    expect(academic.courses, isEmpty);

    await tester.tap(find.text('Kỹ thuật phần mềm'));
    await tester.pumpAndSettle();

    expect(firestore.userProfile!['major'], 'SE');
    expect(academic.profile.major, 'SE');
    expect(academic.courses.map((c) => c.code), ['PRM323']);
    expect(roadmap.selectedMajor, 'SE');
    expect(roadmap.allCourses.map((c) => c.code), ['PRM323']);

    authVm.dispose();
    academic.dispose();
    roadmap.dispose();
    auth.dispose();
  });
}
