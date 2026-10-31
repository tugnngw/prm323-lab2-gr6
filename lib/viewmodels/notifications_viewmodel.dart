import 'dart:async';

import '../models/app_state.dart';
import '../models/notification_model.dart';
import '../services/analytics_service.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/messaging_service.dart';
import 'base_viewmodel.dart';

/// Notification Center ViewModel (Lab 3 T12).
///
/// Responsibilities:
///  * Loads `users/{uid}/notifications` from Firestore (no seed data — an
///    account with no notifications shows the real empty state).
///  * Subscribes to the three push states (foreground / tap / cold-start) and
///    persists every delivered push into Firestore so the center is the
///    single source of truth across devices.
///  * Routes a tapped notification via [lastTappedRoute] (data.route).
class NotificationsViewModel extends BaseViewModel<List<NotificationModel>> {
  NotificationsViewModel({
    this.authService,
    this.firestoreService,
    this.messagingService,
    this.analyticsService,
  }) {
    _bindPushStreams();
    loadData();
  }

  final AuthService? authService;
  final FirestoreService? firestoreService;
  final MessagingService? messagingService;
  final AnalyticsService? analyticsService;

  StreamSubscription<Map<String, dynamic>>? _foregroundSub;
  StreamSubscription<Map<String, dynamic>>? _tapSub;
  StreamSubscription<bool>? _authSub;

  /// Set when the user taps a notification while the app runs — the shell
  /// reads and clears it to navigate to the notification's destination route.
  String? lastTappedRoute;

  List<NotificationModel> _items = [];
  List<NotificationModel> get notifications => List.unmodifiable(_items);
  int get unreadCount => _items.where((n) => n.isUnread).length;

  String? get currentUserId {
    final uid = authService?.currentUserId;
    return (uid == null || uid.isEmpty) ? null : uid;
  }

  @override
  Future<void> loadData() async {
    setState(const AsyncViewState.loading());

    try {
      final firestore = firestoreService;
      final uid = currentUserId;
      if (firestore == null || uid == null) {
        _items = [];
        setState(const AsyncViewState.empty());
        return;
      }
      final docs = await firestore.getNotifications(uid);
      _items = docs.map(NotificationModel.fromMap).toList();

      if (_items.isEmpty) {
        setState(const AsyncViewState.empty());
      } else {
        setState(AsyncViewState.data(_items));
      }
    } catch (e) {
      setState(AsyncViewState.error('Không thể tải thông báo: $e'));
    }
  }

  void _bindPushStreams() {
    // Firebase Auth restores its session asynchronously — reload once the
    // signed-in state settles so the center is not stuck on the pre-restore
    // empty read.
    _authSub = authService?.authStateChanges.listen((_) => loadData());

    final messaging = messagingService;
    if (messaging == null) return;

    // State 1: foreground — show banner + persist.
    _foregroundSub = messaging.onForegroundMessage.listen((payload) {
      unawaited(_handleIncomingPush(payload));
    });

    // State 2: background tap — mark read + route.
    _tapSub = messaging.onNotificationTap.listen((payload) {
      unawaited(_handleTappedPush(payload));
    });

    // State 3: terminated cold start — route after first frame.
    unawaited(Future(() async {
      final initial = await messaging.takeInitialMessage();
      if (initial != null) await _handleTappedPush(initial);
    }));
  }

  Future<void> _handleIncomingPush(Map<String, dynamic> payload) async {
    final uid = currentUserId;
    if (uid == null) return; // No identity: nothing to persist against.
    final item = NotificationModel.fromPush(payload);

    try {
      await firestoreService?.saveNotification(uid, {
        'title': item.title,
        'body': item.body,
        'type': item.type,
        'read': false,
      });
      _items.insert(0, item);
      setState(AsyncViewState.data(_items));
    } catch (e) {
      setLastError('Không thể lưu thông báo mới: $e');
    }

    unawaited(analyticsService
        ?.logNotificationReceived(type: item.type, action: 'foreground'));
  }

  Future<void> _handleTappedPush(Map<String, dynamic> payload) async {
    final data = payload['data'];
    final route = data is Map
        ? data['route'] as String?
        : payload['route'] as String?;
    if (route != null && route.isNotEmpty) lastTappedRoute = route;

    final notificationId = payload['notificationId'] as String? ??
        (data is Map ? data['notificationId'] as String? : null);
    await markAsRead(notificationId);

    unawaited(analyticsService?.logNotificationReceived(
        type: (data is Map ? data['type'] as String? : null) ?? 'system',
        action: 'tap'));
  }

  /// Marks a notification read locally and remotely. A null/unknown id is a
  /// no-op for Firestore but still clears matching local entries by id.
  /// Optimistic entries (`local_…`, created before Firestore assigned a doc id)
  /// skip the remote write — the doc does not exist under that id yet.
  Future<void> markAsRead(String? notificationId) async {
    if (notificationId == null || notificationId.isEmpty) return;
    final idx = _items.indexWhere((n) => n.id == notificationId);
    if (idx != -1) {
      _items[idx] = _items[idx].copyWith(read: true);
      setState(AsyncViewState.data(_items));
    }
    final uid = currentUserId;
    if (firestoreService != null &&
        uid != null &&
        !notificationId.startsWith('local_')) {
      try {
        await firestoreService!.markNotificationRead(uid, notificationId);
      } catch (e) {
        setLastError('Không thể đánh dấu đã đọc: $e');
      }
    }
  }

  void consumeTappedRoute() => lastTappedRoute = null;

  @override
  void dispose() {
    _foregroundSub?.cancel();
    _tapSub?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
