import 'dart:async';

import 'package:prm393_final_gr6/services/messaging_service.dart';

/// Test double for [MessagingService] — lives under test/ only.
/// Tests drive the three push states by calling the emit* methods.
class FakeMessagingService implements MessagingService {
  final _foreground = StreamController<Map<String, dynamic>>.broadcast();
  final _tap = StreamController<Map<String, dynamic>>.broadcast();
  final _token = StreamController<String>.broadcast();

  bool permissionGranted = true;
  String? token = 'fake-device-token-abc123';
  Map<String, dynamic>? initialMessage;

  @override
  Future<bool> requestPermission() async => permissionGranted;

  @override
  Future<String?> getToken() async => token;

  @override
  Future<Map<String, dynamic>?> takeInitialMessage() async => initialMessage;

  @override
  Stream<Map<String, dynamic>> get onForegroundMessage => _foreground.stream;

  @override
  Stream<Map<String, dynamic>> get onNotificationTap => _tap.stream;

  @override
  Stream<String> get onTokenRefresh => _token.stream;

  void emitForeground(Map<String, dynamic> payload) =>
      _foreground.add(payload);

  void emitTap(Map<String, dynamic> payload) => _tap.add(payload);

  Future<void> dispose() async {
    await _foreground.close();
    await _tap.close();
    await _token.close();
  }
}
