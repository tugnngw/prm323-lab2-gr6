import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:prm323_lab3/main.dart';
import 'package:prm323_lab3/services/mock_auth_service.dart';
import 'package:prm323_lab3/services/mock_firestore_service.dart';

void main() {
  testWidgets('Authenticated user sees AppShell with bottom navigation', (WidgetTester tester) async {
    final mockAuth = MockAuthService(initialUserId: 'user_123', initialEmail: 'ducnmse180000@fpt.edu.vn');
    final mockFirestore = MockFirestoreService();

    await tester.pumpWidget(
      FptuSecondBrainApp(
        authService: mockAuth,
        firestoreService: mockFirestore,
      ),
    );
    // Advance time past the 300ms delay in HomeViewModel.loadData()
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    // Verify app title in app bar
    expect(find.text('FPTU Second Brain'), findsOneWidget);

    // Verify 4 bottom navigation destinations
    expect(find.text('Trang chủ'), findsOneWidget);
    expect(find.text('Lộ trình'), findsOneWidget);
    expect(find.text('Việc cần làm'), findsOneWidget);
    expect(find.text('Ghi chú'), findsOneWidget);
  });

  testWidgets('Unauthenticated user sees SignInScreen with Google sign-in button', (WidgetTester tester) async {
    final mockAuth = MockAuthService(initialUserId: null, initialEmail: null);
    final mockFirestore = MockFirestoreService();

    await tester.pumpWidget(
      FptuSecondBrainApp(
        authService: mockAuth,
        firestoreService: mockFirestore,
      ),
    );
    await tester.pumpAndSettle();

    // Verify SignInScreen components
    expect(find.text('FPTU Second Brain'), findsOneWidget);
    expect(find.text('Đăng nhập với Google (@fpt.edu.vn)'), findsOneWidget);
    expect(find.byIcon(Icons.login_rounded), findsOneWidget);
  });
}
