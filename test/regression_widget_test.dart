import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:prm393_final_gr6/main.dart';
import 'package:prm393_final_gr6/screens/tasks_screen.dart';
import 'package:prm393_final_gr6/services/remote_config_service.dart';
import 'package:prm393_final_gr6/viewmodels/tasks_viewmodel.dart';

import 'helpers/fake_firestore_service.dart';
import 'helpers/fake_storage_service.dart';
import 'helpers/mock_auth_service.dart';

void main() {
  Future<TasksViewModel> taskScreen(
    WidgetTester tester,
    FakeFirestoreService store,
  ) async {
    final auth = MockAuthService(initialUserId: 'owner-a');
    final vm = TasksViewModel(authService: auth, firestoreService: store);
    await tester.pumpWidget(
      ChangeNotifierProvider.value(
        value: vm,
        child: const MaterialApp(home: TasksScreen()),
      ),
    );
    await tester.pumpAndSettle();
    addTearDown(auth.dispose);
    addTearDown(vm.dispose);
    return vm;
  }

  FakeFirestoreService seededStore() => FakeFirestoreService()
    ..userProfile = {'major': 'SE'}
    ..tasks.add({
      'id': 't1',
      'title': 'Regression task',
      'courseCode': 'PRM323',
      'dueDate': '04/11/2026',
      'isCompleted': false,
    });

  testWidgets(
    'task Undo is usable briefly and the toast dismisses itself by five seconds',
    (tester) async {
      final store = seededStore();
      final vm = await taskScreen(tester, store);
      await tester.tap(find.text('Đánh dấu đã xong'));
      await tester.pumpAndSettle();
      expect(vm.allTasks.single.isCompleted, isTrue);
      expect(store.tasks.single['isCompleted'], isTrue);
      // The action survives a few seconds, then the timer removes it.
      await tester.pump(const Duration(seconds: 3));
      expect(find.text('Hoàn tác'), findsOneWidget);
      await tester.tap(find.text('Hoàn tác'));
      await tester.pumpAndSettle();
      expect(vm.allTasks.single.isCompleted, isFalse);
      expect(store.tasks.single['isCompleted'], isFalse);

      // An untouched toast must hide itself at five seconds, not stay forever.
      await tester.tap(find.text('Đánh dấu đã xong'));
      await tester.pumpAndSettle();
      expect(find.text('Hoàn tác'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 4000));
      expect(find.text('Hoàn tác'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
      expect(find.text('Hoàn tác'), findsNothing);
      expect(vm.allTasks.single.isCompleted, isTrue);
    },
  );

  testWidgets(
    'failed task toggle restores row and displays an error instead of Undo',
    (tester) async {
      final store = seededStore()..shouldFailTaskUpdate = true;
      final vm = await taskScreen(tester, store);
      await tester.tap(find.text('Đánh dấu đã xong'));
      await tester.pumpAndSettle();
      expect(vm.allTasks.single.isCompleted, isFalse);
      expect(
        find.textContaining('Không thể cập nhật việc cần làm'),
        findsOneWidget,
      );
      expect(find.text('Hoàn tác'), findsNothing);
    },
  );

  testWidgets(
    'remote configuration notification reevaluates the running auth gate',
    (tester) async {
      final flags = <String, dynamic>{'maintenance_mode': false};
      final rc = RemoteConfigService(overrides: flags);
      final auth = MockAuthService(initialUserId: 'owner-a');
      await tester.pumpWidget(
        StudyPilotApp(
          authService: auth,
          firestoreService: FakeFirestoreService()
            ..userProfile = {'major': 'SE'},
          remoteConfigService: rc,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Trang chủ'), findsOneWidget);
      flags['maintenance_mode'] = true;
      rc.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.byType(MaintenanceScreen), findsOneWidget);
      flags['maintenance_mode'] = false;
      rc.notifyListeners();
      await tester.pumpAndSettle();
      expect(find.text('Trang chủ'), findsOneWidget);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    },
  );

  testWidgets(
    'export rejects failed source reload before consent or Storage upload',
    (tester) async {
      final auth = MockAuthService(initialUserId: 'owner-a');
      final store = FakeFirestoreService()..userProfile = {'major': 'SE'};
      final storage = FakeStorageService();
      await tester.pumpWidget(
        StudyPilotApp(
          authService: auth,
          firestoreService: store,
          storageService: storage,
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Đồng bộ Vault'));
      await tester.pumpAndSettle();
      store.shouldFailTaskLoad = true;
      final export = find.text('Xuất & Tải PDF lên Cloud Storage');
      await tester.scrollUntilVisible(
        export,
        500,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(export);
      await tester.pumpAndSettle();
      expect(
        find.textContaining('Không tải được dữ liệu để xuất'),
        findsOneWidget,
      );
      expect(find.text('Chia sẻ báo cáo học tập?'), findsNothing);
      expect(storage.uploads, isEmpty);
      expect(store.reports, isEmpty);
      await tester.pumpWidget(const SizedBox());
      auth.dispose();
    },
  );
  testWidgets('PDF consent reports each source count in the correct category', (
    tester,
  ) async {
    final auth = MockAuthService(initialUserId: 'owner-a');
    final store = seededStore()
      ..courses.addAll([
        {
          'id': 'A',
          'code': 'A',
          'name': 'A',
          'credits': 3,
          'semester': 5,
          'major': 'SE',
        },
        {
          'id': 'B',
          'code': 'B',
          'name': 'B',
          'credits': 2,
          'semester': 5,
          'major': 'SE',
        },
      ]);
    final storage = FakeStorageService();
    await tester.pumpWidget(
      StudyPilotApp(
        authService: auth,
        firestoreService: store,
        storageService: storage,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Đồng bộ Vault'));
    await tester.pumpAndSettle();
    final export = find.text('Xuất & Tải PDF lên Cloud Storage');
    await tester.scrollUntilVisible(
      export,
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(export);
    // Upload remains busy while consent is open, so the spinner never settles.
    for (
      var attempt = 0;
      attempt < 30 && find.text('Chia sẻ báo cáo học tập?').evaluate().isEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.textContaining('2 môn học, 1 việc cần làm, 0 ghi chú'),
      findsOneWidget,
    );
    expect(storage.uploads, isEmpty);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(storage.uploads, isEmpty);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });
  testWidgets('local PDF consent can cancel without any cloud write', (
    tester,
  ) async {
    final auth = MockAuthService(initialUserId: 'owner-a');
    final store = seededStore();
    final storage = FakeStorageService()..shouldFailUpload = true;
    await tester.pumpWidget(
      StudyPilotApp(
        authService: auth,
        firestoreService: store,
        storageService: storage,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Đồng bộ Vault'));
    await tester.pumpAndSettle();
    final local = find.text('Tạo PDF trên thiết bị');
    await tester.scrollUntilVisible(
      local,
      500,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(local);
    for (
      var attempt = 0;
      attempt < 30 && find.text('Tạo PDF trên thiết bị?').evaluate().isEmpty;
      attempt++
    ) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Tạo PDF trên thiết bị?'), findsOneWidget);
    expect(
      find.textContaining('không upload Firebase Storage'),
      findsOneWidget,
    );
    expect(find.text('Đồng ý xuất & tải'), findsNothing);
    await tester.tap(find.text('Hủy'));
    await tester.pumpAndSettle();
    expect(storage.uploads, isEmpty);
    expect(store.reports, isEmpty);
    expect(find.text('Mở / Chia sẻ file'), findsNothing);
    await tester.pumpWidget(const SizedBox());
    auth.dispose();
  });
}
