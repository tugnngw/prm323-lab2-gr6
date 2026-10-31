/// Interface for push messaging (Lab 3 T12 — FCM device-to-cloud).
///
/// Covers the three app states required by the lab:
///  * **foreground** — [onForegroundMessage] (app open: banner + Notification
///    Center entry persisted via FirestoreService.saveNotification);
///  * **background** — [onNotificationTap] (user taps a tray notification);
///  * **terminated** — [takeInitialMessage] (app cold-started from a tap;
///    one-shot, consumes the message).
///
/// Production code composes [FirebaseMessagingService] only; test doubles live
/// under `test/` (no mockdata inside `lib/`).
abstract class MessagingService {
  /// Android 13+ runtime notification permission. False when denied/unavailable.
  Future<bool> requestPermission();

  /// Device registration token, or null when messaging is unavailable.
  /// Callers must treat null as "not registered" — never store a fabricated token.
  Future<String?> getToken();

  /// Message that cold-started the app (terminated state). One-shot.
  Future<Map<String, dynamic>?> takeInitialMessage();

  /// Messages arriving while the app is in the foreground.
  Stream<Map<String, dynamic>> get onForegroundMessage;

  /// User tapped a notification delivered while backgrounded.
  Stream<Map<String, dynamic>> get onNotificationTap;

  /// Token rotated by FCM (e.g. after reinstall or cloud reset).
  Stream<String> get onTokenRefresh;
}
