import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:prm393_final_gr6/models/notification_model.dart';

void main() {
  group('NotificationModel.fromMap receivedAt', () {
    // Regression: the center stores `FieldValue.serverTimestamp()`, so reads
    // return a Firestore Timestamp. A plain `as String?` cast crashed the whole
    // Notification Center with
    //   type 'Timestamp' is not a subtype of type 'String?' in type cast
    test('parses a Firestore Timestamp instead of throwing', () {
      final model = NotificationModel.fromMap({
        'id': 'n1',
        'title': 'Deadline',
        'read': false,
        'receivedAt': Timestamp.fromDate(DateTime(2026, 11, 3, 9, 5)),
      });

      expect(model.receivedAt, '03/11/2026 09:05');
      expect(model.title, 'Deadline');
    });

    test('parses a DateTime value', () {
      final model = NotificationModel.fromMap(
          {'receivedAt': DateTime(2026, 1, 2, 3, 4)});
      expect(model.receivedAt, '02/01/2026 03:04');
    });

    test('parses an ISO-8601 string from an FCM payload', () {
      final model = NotificationModel.fromMap({'receivedAt': '2026-11-03T09:05:00'});
      expect(model.receivedAt, '03/11/2026 09:05');
    });

    test('keeps a legacy display string and tolerates a missing field', () {
      expect(NotificationModel.fromMap({'receivedAt': 'Vừa xong'}).receivedAt,
          'Vừa xong');
      expect(NotificationModel.fromMap(const {}).receivedAt, '');
    });
  });

  group('NotificationModel route', () {
    test('fromMap carries route', () {
      final model = NotificationModel.fromMap({'route': '/advisor'});
      expect(model.route, '/advisor');
    });

    test('toMap only emits route when set', () {
      expect(const NotificationModel(id: 'a', title: 't', body: 'b').toMap(),
          isNot(contains('route')));
      expect(
        const NotificationModel(id: 'a', title: 't', body: 'b', route: '/x')
            .toMap()['route'],
        '/x',
      );
    });

    test('copyWith(read:) preserves route', () {
      const model = NotificationModel(
          id: 'a', title: 't', body: 'b', route: '/sync-vault');
      expect(model.copyWith(read: true).route, '/sync-vault');
    });

    test('fromPush carries route from the data payload', () {
      final model = NotificationModel.fromPush({
        'title': 'Sync xong',
        'data': {'route': '/sync-vault', 'type': 'sync'},
      });
      expect(model.route, '/sync-vault');
      expect(model.type, 'sync');
    });
  });
}
