import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_final_gr6/models/notification_model.dart';
import 'package:prm393_final_gr6/viewmodels/notifications_viewmodel.dart';

import '../helpers/fake_firestore_service.dart';
import '../helpers/fake_messaging_service.dart';
import '../helpers/mock_auth_service.dart';

void main() {
  test('course and note push arguments survive persistence and copyWith', () {
    final item = NotificationModel.fromPush({
      'notificationId': 'push-a',
      'data': {
        'route': '/course-detail',
        'courseId': 'PRM323',
        'title': 'Course update',
      },
    });
    final restored = NotificationModel.fromMap(item.toMap())
        .copyWith(read: true);
    expect(restored.destinationRoute, '/course-detail');
    expect(restored.destinationArgument, 'PRM323');
    expect(restored.title, 'Course update');
    const query = NotificationModel(
      id: 'n',
      title: '',
      body: '',
      route: '/note-editor?noteId=note-a',
    );
    expect(query.destinationRoute, '/note-editor');
    expect(query.destinationArgument, 'note-a');
  });
  test(
    'unknown/external routes and missing course IDs safely open the center',
    () {
      for (final route in [
        '/not-a-route',
        'https://example.com',
        '/course-detail',
      ]) {
        final item = NotificationModel(
          id: 'n',
          title: '',
          body: '',
          route: route,
        );
        expect(item.destinationRoute, '/notifications');
      }
    },
  );
  test('tap upserts previously unseen notification and notifies the route consumer', () async {
    final auth = MockAuthService(initialUserId: 'owner');
    final store = FakeFirestoreService();
    final transport = FakeMessagingService();
    final vm = NotificationsViewModel(
      authService: auth,
      firestoreService: store,
      messagingService: transport,
    );
    await vm.loadData();
    var notifications = 0;
    vm.addListener(() => notifications++);
    transport.emitTap({
      'notificationId': 'new-push',
      'title': 'Course',
      'data': {'route': '/course-detail', 'courseId': 'PRM323'},
    });
    await Future<void>.delayed(Duration.zero);
    expect(store.notifications.single['read'], isTrue);
    expect(vm.lastTappedRoute, '/course-detail');
    expect(vm.lastTappedArgument, 'PRM323');
    expect(notifications, greaterThan(0));
    vm.consumeTappedRoute();
    expect(vm.lastTappedRoute, isNull);
    expect(vm.lastTappedArgument, isNull);
    vm.dispose();
    await transport.dispose();
    auth.dispose();
  });
}
