import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:prm323_lab3/main.dart';
import 'package:prm323_lab3/screens/note_editor_screen.dart';
import 'helpers/mock_auth_service.dart';
import 'helpers/mock_firestore_service.dart';
import 'package:prm323_lab3/viewmodels/notes_viewmodel.dart';

import 'helpers/fake_firestore_service.dart';

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

  testWidgets('Successful note save shows success snackbar', (WidgetTester tester) async {
    final mockAuth = MockAuthService(initialUserId: 'user_widget_123');
    final fakeFirestore = FakeFirestoreService();
    final notesVm = NotesViewModel(
      authService: mockAuth,
      firestoreService: fakeFirestore,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider<NotesViewModel>.value(
                    value: notesVm,
                    child: const NoteEditorScreen(),
                  ),
                ),
              ),
              child: const Text('Open Editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Editor'));
    await tester.pumpAndSettle();

    expect(find.text('Soạn ghi chú mới'), findsOneWidget);

    // Enter title in first TextField
    await tester.enterText(find.byType(TextField).first, 'Kiến trúc BLoC');
    await tester.pumpAndSettle();

    // Tap save button (check icon in AppBar)
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Verify success snackbar shown on screen
    expect(find.text('Đã lưu ghi chú vào Vault thành công!'), findsOneWidget);

    // Verify editor is closed (popped)
    expect(find.text('Soạn ghi chú mới'), findsNothing);

    // Verify note is persisted to Firestore with authenticated UID
    expect(fakeFirestore.notes.any((n) => n['title'] == 'Kiến trúc BLoC'), isTrue);
    expect(fakeFirestore.notes.first['userId'], equals('user_widget_123'));
  });

  testWidgets('Failed note save does not show success and displays error snackbar', (WidgetTester tester) async {
    final mockAuth = MockAuthService(initialUserId: 'user_widget_123');
    final fakeFirestore = FakeFirestoreService()..shouldFailNoteSave = true;
    final notesVm = NotesViewModel(
      authService: mockAuth,
      firestoreService: fakeFirestore,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChangeNotifierProvider<NotesViewModel>.value(
                    value: notesVm,
                    child: const NoteEditorScreen(),
                  ),
                ),
              ),
              child: const Text('Open Editor'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open Editor'));
    await tester.pumpAndSettle();

    expect(find.text('Soạn ghi chú mới'), findsOneWidget);

    // Enter title in first TextField
    await tester.enterText(find.byType(TextField).first, 'Kiến trúc Failure');
    await tester.pumpAndSettle();

    // Tap save button (check icon in AppBar)
    await tester.tap(find.byIcon(Icons.check));
    await tester.pumpAndSettle();

    // Verify success snackbar NOT shown, error snackbar shown instead
    expect(find.text('Đã lưu ghi chú vào Vault thành công!'), findsNothing);
    expect(find.text('Không thể lưu ghi chú. Kiểm tra kết nối và thử lại.'), findsOneWidget);

    // Verify screen remains in view (did not pop / did not close editor)
    expect(find.text('Soạn ghi chú mới'), findsOneWidget);
  });
}
