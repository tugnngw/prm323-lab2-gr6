import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_final_gr6/viewmodels/auth_viewmodel.dart';
import 'package:prm393_final_gr6/viewmodels/notifications_viewmodel.dart';

import '../helpers/fake_firestore_service.dart';
import '../helpers/fake_messaging_service.dart';
import '../helpers/mock_analytics_service.dart';
import '../helpers/mock_auth_service.dart';

void main() {
  group('NotificationsViewModel (Lab 3 T12)', () {
    test('signed-out without backend shows empty state, never seed data',
        () async {
      final vm = NotificationsViewModel(authService: MockAuthService());
      await vm.loadData();
      expect(vm.notifications, isEmpty);
      expect(vm.state.state.toString(), contains('empty'));
    });

    test('loads real notifications from Firestore in order', () async {
      final firestore = FakeFirestoreService()
        ..notifications.addAll([
          {
            'id': 'n1',
            'title': 'Deadline Lab 3',
            'body': 'Còn 2 ngày',
            'type': 'task_due',
            'read': false,
          },
          {
            'id': 'n2',
            'title': 'Đồng bộ hoàn tất',
            'body': 'Vault up to date',
            'type': 'sync',
            'read': true,
          },
        ]);
      final vm = NotificationsViewModel(
        authService: MockAuthService(initialUserId: 'u_1'),
        firestoreService: firestore,
      );
      await vm.loadData();

      expect(vm.notifications.length, 2);
      expect(vm.unreadCount, 1);
      expect(vm.notifications.first.title, 'Deadline Lab 3');
    });

    test('foreground push persists to Firestore and appears in the list',
        () async {
      final firestore = FakeFirestoreService();
      final messaging = FakeMessagingService();
      final analytics = MockAnalyticsService();
      final vm = NotificationsViewModel(
        authService: MockAuthService(initialUserId: 'u_1'),
        firestoreService: firestore,
        messagingService: messaging,
        analyticsService: analytics,
      );
      await vm.loadData();

      messaging.emitForeground({
        'title': 'Nhắc lịch học',
        'body': 'PRM323 bắt đầu lúc 13:30',
        'data': {'type': 'system'},
      });
      await Future<void>.delayed(Duration.zero);

      expect(vm.notifications.length, 1);
      expect(vm.notifications.first.title, 'Nhắc lịch học');
      expect(firestore.notifications.length, 1);
      expect(firestore.notifications.first['type'], 'system');
      expect(
        analytics.loggedEvents
            .any((e) => e['name'] == 'notification_received'),
        isTrue,
      );
      await messaging.dispose();
    });

    test('foreground push exposes a banner and persists its route', () async {
      final firestore = FakeFirestoreService();
      final messaging = FakeMessagingService();
      final vm = NotificationsViewModel(
        authService: MockAuthService(initialUserId: 'u_1'),
        firestoreService: firestore,
        messagingService: messaging,
      );
      await vm.loadData();

      messaging.emitForeground({
        'title': 'Gợi ý học tập',
        'body': 'Mở tư vấn',
        'notificationId': 'push_route_1',
        'data': {'type': 'advisor', 'route': '/advisor'},
      });
      await Future<void>.delayed(Duration.zero);

      expect(vm.banner?.title, 'Gợi ý học tập');
      expect(firestore.notifications.single['route'], '/advisor');
      expect(vm.notifications.single.route, '/advisor');

      vm.dismissBanner();
      expect(vm.banner, isNull);
      await messaging.dispose();
    });

    test('duplicate foreground push reuses deterministic notification id', () async {
      final firestore = FakeFirestoreService();
      final messaging = FakeMessagingService();
      final vm = NotificationsViewModel(
        authService: MockAuthService(initialUserId: 'u_1'),
        firestoreService: firestore,
        messagingService: messaging,
      );
      await vm.loadData();

      final payload = {
        'title': 'Nhắc lịch học',
        'body': 'PRM323 bắt đầu lúc 13:30',
        'notificationId': 'message_1',
        'data': {'type': 'system'},
      };
      messaging.emitForeground(payload);
      await Future<void>.delayed(Duration.zero);
      messaging.emitForeground(payload);
      await Future<void>.delayed(Duration.zero);

      expect(vm.notifications, hasLength(1));
      expect(firestore.notifications, hasLength(1));
      expect(firestore.notifications.single['id'], 'message_1');
      await messaging.dispose();
    });

    test('tapped push marks read by id and records the route', () async {
      final firestore = FakeFirestoreService()
        ..notifications.add({
          'id': 'doc_9',
          'title': 'X',
          'body': 'Y',
          'type': 'advisor',
          'read': false,
        });
      final messaging = FakeMessagingService();
      final vm = NotificationsViewModel(
        authService: MockAuthService(initialUserId: 'u_1'),
        firestoreService: firestore,
        messagingService: messaging,
      );
      await vm.loadData();

      messaging.emitTap({
        'title': 'X',
        'body': 'Y',
        'notificationId': 'doc_9',
        'data': {'route': '/advisor', 'type': 'advisor'},
      });
      await Future<void>.delayed(Duration.zero);

      expect(vm.lastTappedRoute, '/advisor');
      expect(firestore.notifications.first['read'], isTrue);
      vm.consumeTappedRoute();
      expect(vm.lastTappedRoute, isNull);
      await messaging.dispose();
    });

    test('cold-start initial message routes after login', () async {
      final messaging = FakeMessagingService()
        ..initialMessage = {
          'title': 'Chào mừng',
          'body': 'open sim',
          'data': {'route': '/strategy-sim', 'type': 'system'},
        };
      final vm = NotificationsViewModel(
        authService: MockAuthService(initialUserId: 'u_1'),
        firestoreService: FakeFirestoreService(),
        messagingService: messaging,
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(vm.lastTappedRoute, '/strategy-sim');
      await messaging.dispose();
    });

    test('markAsRead skips remote write for optimistic local_ ids', () async {
      final firestore = FakeFirestoreService();
      final vm = NotificationsViewModel(
        authService: MockAuthService(initialUserId: 'u_1'),
        firestoreService: firestore,
      );
      await vm.markAsRead('local_123'); // must not throw / must not write
      expect(firestore.notifications, isEmpty);
    });
  });

  group('AuthViewModel FCM token registration (T12)', () {
    test('registers a real token on login and stores under users/{uid}/tokens',
        () async {
      final auth = MockAuthService();
      final firestore = FakeFirestoreService();
      final messaging = FakeMessagingService();
      final vm = AuthViewModel(
        authService: auth,
        firestoreService: firestore,
        messagingService: messaging,
      );

      await vm.signInWithGoogle();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(firestore.registeredTokens,
          contains('${auth.currentUserId}:fake-device-token-abc123'));
      await messaging.dispose();
    });

    test('denied permission registers nothing (no fake token rows)', () async {
      final messaging = FakeMessagingService()..permissionGranted = false;
      final firestore = FakeFirestoreService();
      final vm = AuthViewModel(
        authService: MockAuthService(),
        firestoreService: firestore,
        messagingService: messaging,
      );

      await vm.signInWithGoogle();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(firestore.registeredTokens, isEmpty);
      await messaging.dispose();
    });

    test('null token registers nothing', () async {
      final messaging = FakeMessagingService()..token = null;
      final firestore = FakeFirestoreService();
      final vm = AuthViewModel(
        authService: MockAuthService(),
        firestoreService: firestore,
        messagingService: messaging,
      );

      await vm.signInWithGoogle();
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(firestore.registeredTokens, isEmpty);
      await messaging.dispose();
    });
  });
}
