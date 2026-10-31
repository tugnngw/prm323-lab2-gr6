import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'messaging_service.dart';

/// Top-level background/terminated handler. Must be a top-level (or static)
/// function per firebase_messaging; runs in a separate isolate when a push
/// wakes the app, so it only records the payload for the Notification Center.
/// Persistence happens on next foreground start via [FirebaseMessagingService]
/// handlers — this isolate has no service injection.
@pragma('vm:entry-point')
Future<void> fcmBackgroundHandler(RemoteMessage message) async {
  debugPrint('[FCM] Background message received: ${message.messageId}');
}

/// Normalizes a [RemoteMessage] into the plain-map contract of
/// [MessagingService] so callers never depend on firebase types.
Map<String, dynamic> _payloadOf(RemoteMessage message) => {
      'title': message.notification?.title ?? '',
      'body': message.notification?.body ?? '',
      'data': message.data,
      if (message.data['notificationId'] != null)
        'notificationId': message.data['notificationId'],
    };

/// Firebase Cloud Messaging implementation of [MessagingService].
///
/// Fail-loud policy: when Firebase is unavailable the constructor throws —
/// callers (main.dart) wire this behind the existing Firebase-init guard, and
/// tests inject a fake instead (no mock fallbacks inside the message path).
class FirebaseMessagingService implements MessagingService {
  FirebaseMessagingService({FirebaseMessaging? messaging})
      : _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _messaging;

  final _foregroundController = StreamController<Map<String, dynamic>>.broadcast();
  final _tapController = StreamController<Map<String, dynamic>>.broadcast();
  final _tokenController = StreamController<String>.broadcast();

  @override
  Future<bool> requestPermission() async {
    try {
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      return settings.authorizationStatus == AuthorizationStatus.authorized;
    } catch (e) {
      debugPrint('[FCM] requestPermission failed: $e');
      return false;
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      // v17 marks getToken/onTokenRefresh deprecated in favor of the
      // register-API flow; they remain the documented read path for storing a
      // device token in Firestore and still return the real token.
      // ignore: deprecated_member_use
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('[FCM] getToken failed: $e');
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> takeInitialMessage() async {
    try {
      final message = await _messaging.getInitialMessage();
      return message == null ? null : _payloadOf(message);
    } catch (e) {
      debugPrint('[FCM] getInitialMessage failed: $e');
      return null;
    }
  }

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage =>
      _foregroundController.stream;

  @override
  Stream<Map<String, dynamic>> get onNotificationTap => _tapController.stream;

  @override
  Stream<String> get onTokenRefresh => _tokenController.stream;

  /// Subscribes the raw FCM streams into the normalized contract streams.
  /// Called once from main() after Firebase init.
  void attach() {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('[FCM] Foreground message: ${message.messageId}');
      _foregroundController.add(_payloadOf(message));
    });
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('[FCM] Notification tapped (background): ${message.messageId}');
      _tapController.add(_payloadOf(message));
    });
    // ignore: deprecated_member_use
    _messaging.onTokenRefresh.listen((token) {
      debugPrint('[FCM] Token refreshed');
      _tokenController.add(token);
    });
  }

  Future<void> dispose() async {
    await _foregroundController.close();
    await _tapController.close();
    await _tokenController.close();
  }
}
