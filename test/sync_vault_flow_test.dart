import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_final_gr6/main.dart';

import 'helpers/fake_firestore_service.dart';
import 'helpers/mock_auth_service.dart';

void main() {
  Future<void> openVault(
    WidgetTester tester,
    FakeFirestoreService store,
  ) async {
    store.userProfile ??= {'major': 'SE'};
    final auth = MockAuthService(initialUserId: 'owner-a');
    await tester.pumpWidget(
      StudyPilotApp(authService: auth, firestoreService: store),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Đồng bộ Vault'));
    await tester.pumpAndSettle();
    addTearDown(auth.dispose);
  }

  testWidgets('manual sync asks D-01 confirmation and cancel changes nothing', (
    tester,
  ) async {
    await openVault(tester, FakeFirestoreService());
    expect(find.text('Sync Vault & Cài đặt'), findsOneWidget);

    await tester.tap(find.text('Kích hoạt đồng bộ Vault ngay'));
    await tester.pumpAndSettle();
    expect(find.text('Đồng bộ Vault?'), findsOneWidget);

    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(find.text('Đồng bộ Vault?'), findsNothing);
    expect(find.textContaining('Đã tải lại dữ liệu'), findsNothing);
    expect(find.text('Sync Vault & Cài đặt'), findsOneWidget);
  });

  testWidgets('confirmed sync reloads stores and reports success', (
    tester,
  ) async {
    await openVault(tester, FakeFirestoreService());

    await tester.tap(find.text('Kích hoạt đồng bộ Vault ngay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Đã tải lại dữ liệu Cloud Firestore'),
      findsOneWidget,
    );
  });

  testWidgets('sync failure opens SyncError and Thử lại recovers', (
    tester,
  ) async {
    final store = FakeFirestoreService()..shouldFailTaskLoad = true;
    await openVault(tester, store);

    await tester.tap(find.text('Kích hoạt đồng bộ Vault ngay'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Xác nhận'));
    await tester.pumpAndSettle();

    expect(find.text('Không thể đồng bộ dữ liệu'), findsOneWidget);
    expect(find.textContaining('Tasks:'), findsOneWidget);
    expect(
      find.textContaining('Dữ liệu cục bộ được giữ nguyên'),
      findsOneWidget,
    );

    store.shouldFailTaskLoad = false;
    await tester.tap(find.text('Thử lại'));
    await tester.pumpAndSettle();

    expect(find.text('Không thể đồng bộ dữ liệu'), findsNothing);
    expect(
      find.textContaining('Đã tải lại dữ liệu Cloud Firestore'),
      findsOneWidget,
    );
  });

  testWidgets('system back from a sub-tab returns to the Home tab', (
    tester,
  ) async {
    final auth = MockAuthService(initialUserId: 'owner-a');
    await tester.pumpWidget(
      StudyPilotApp(
        authService: auth,
        firestoreService: FakeFirestoreService()
          ..userProfile = {'major': 'SE'},
      ),
    );
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    addTearDown(auth.dispose);

    await tester.tap(find.text('Việc cần làm'));
    await tester.pumpAndSettle();
    expect(find.text('Thêm việc'), findsOneWidget);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.textContaining('Chào '), findsOneWidget);
    expect(find.text('Thêm việc'), findsNothing);
  });
}