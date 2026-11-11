import 'dart:async';

import '../models/announcement_model.dart';
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
  StreamSubscription<List<Map<String, dynamic>>>? _announcementSub;
  int _loadVersion = 0;
  String? _loadedUid;

  /// Staff/admin broadcasts live in a shared collection; the student's read
  /// state is a list of ids on their own profile.
  List<AnnouncementModel> _announcements = [];
  Set<String> _readAnnouncementIds = {};
  List<AnnouncementModel> get announcements =>
      List.unmodifiable(_announcements);
  int get unreadAnnouncementCount => _announcements
      .where((a) => !_readAnnouncementIds.contains(a.id))
      .length;
  bool isAnnouncementRead(String id) => _readAnnouncementIds.contains(id);

  /// Prefix used when an announcement is routed through [markAsRead].
  static const announcementIdPrefix = 'announcement_';

  /// Set when the user taps a notification while the app runs — the shell
  /// reads and clears it to navigate to the notification's destination route.
  String? lastTappedRoute;
  String? lastTappedArgument;

  /// Most recent foreground push, shown as an in-app banner (T12 requires a
  /// foreground banner alongside the center). Cleared by [dismissBanner].
  NotificationModel? _banner;
  NotificationModel? get banner => _banner;

  List<NotificationModel> _items = [];
  List<NotificationModel> get notifications => List.unmodifiable(_items);
  int get unreadCount =>
      _items.where((n) => n.isUnread).length + unreadAnnouncementCount;

  String? get currentUserId {
    final uid = authService?.currentUserId;
    return (uid == null || uid.isEmpty) ? null : uid;
  }

  @override
  Future<void> loadData() async {
    if (isDisposed) return;
    final version = ++_loadVersion;
    final uid = currentUserId;
    _loadedUid = uid;
    setState(const AsyncViewState.loading());

    try {
      final firestore = firestoreService;
      if (firestore == null || uid == null) {
        _items = [];
        _announcements = [];
        _readAnnouncementIds = {};
        _announcementSub?.cancel();
        _announcementSub = null;
        setState(const AsyncViewState.empty());
        return;
      }
      final docs = await firestore.getNotifications(uid);
      if (isDisposed || version != _loadVersion || uid != currentUserId) return;
      _items = docs.map(NotificationModel.fromMap).toList();

      // Announcements + read markers are secondary: a failure here must not
      // hide the student's personal notifications.
      try {
        final profile = await firestore.getUserProfile(uid);
        _readAnnouncementIds =
            (profile?['readAnnouncementIds'] as List? ?? const [])
                .map((e) => e.toString())
                .where((e) => e.isNotEmpty)
                .toSet();
        final rows = await firestore.getAnnouncements();
        if (isDisposed || version != _loadVersion || uid != currentUserId) {
          return;
        }
        _setAnnouncements(rows);
      } catch (_) {
        // Keep whatever we already had instead of clearing the bell.
      }
      _subscribeAnnouncements(uid, version);

      if (_items.isEmpty && _announcements.isEmpty) {
        setState(const AsyncViewState.empty());
      } else {
        setState(AsyncViewState.data(_items));
      }
    } catch (e) {
      if (isDisposed || version != _loadVersion || uid != currentUserId) return;
      setState(AsyncViewState.error('Không thể tải thông báo: $e'));
    }
  }

  void _setAnnouncements(List<Map<String, dynamic>> rows) {
    final items = rows.map(AnnouncementModel.fromMap).toList()
      ..sort((a, b) {
        final aTime = a.publishedAt;
        final bTime = b.publishedAt;
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        return bTime.compareTo(aTime);
      });
    _announcements = items;
  }

  /// Keeps the bell in sync when staff publish while the app is open.
  void _subscribeAnnouncements(String uid, int version) {
    _announcementSub?.cancel();
    _announcementSub = null;
    final firestore = firestoreService;
    if (firestore == null) return;
    try {
      _announcementSub = firestore.watchAnnouncements().listen((rows) {
        if (isDisposed || version != _loadVersion || uid != currentUserId) {
          return;
        }
        _setAnnouncements(rows);
        setState(
          _items.isEmpty && _announcements.isEmpty
              ? const AsyncViewState.empty()
              : AsyncViewState.data(_items),
        );
      }, onError: (_) {});
    } catch (_) {}
  }

  void _bindPushStreams() {
    // Firebase Auth restores its session asynchronously — reload once the
    // signed-in state settles so the center is not stuck on the pre-restore
    // empty read.
    _authSub = authService?.authStateChanges.listen((_) {
      if (currentUserId == _loadedUid) return;
      _banner = null;
      lastTappedRoute = null;
      lastTappedArgument = null;
      loadData();
    });

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
    unawaited(
      Future(() async {
        final initial = await messaging.takeInitialMessage();
        if (initial != null) await _handleTappedPush(initial);
      }),
    );
  }

  Future<void> _handleIncomingPush(Map<String, dynamic> payload) async {
    final uid = currentUserId;
    if (uid == null) return; // No identity: nothing to persist against.
    final item = NotificationModel.fromPush(payload);

    try {
      final firestore = firestoreService;
      if (firestore == null) return;
      await firestore.saveNotification(uid, {
        'title': item.title,
        'body': item.body,
        'type': item.type,
        'read': false,
        if (item.route != null) 'route': item.route,
        if (item.routeArgument != null) 'routeArgument': item.routeArgument,
      }, notificationId: item.id);
      if (isDisposed || uid != currentUserId) return;
      _items.removeWhere((existing) => existing.id == item.id);
      _items.insert(0, item);
      _banner = item;
      setState(AsyncViewState.data(_items));
    } catch (e) {
      if (isDisposed || uid != currentUserId) return;
      setLastError('Không thể lưu thông báo mới: $e');
    }

    unawaited(
      analyticsService?.logNotificationReceived(
        type: item.type,
        action: 'foreground',
      ),
    );
  }

  Future<void> _handleTappedPush(Map<String, dynamic> payload) async {
    final uid = currentUserId;
    if (uid == null) return;
    final item = NotificationModel.fromPush(payload).copyWith(read: true);
    try {
      // A notification-only push may first reach Dart when tapped. Upsert it
      // before marking read instead of failing on a nonexistent document.
      await firestoreService?.saveNotification(
        uid,
        item.toMap(),
        notificationId: item.id,
      );
      if (isDisposed || uid != currentUserId) return;
      _items.removeWhere((n) => n.id == item.id);
      _items.insert(0, item);
      lastTappedRoute = item.destinationRoute;
      lastTappedArgument = item.destinationArgument;
      setState(AsyncViewState.data(_items));
    } catch (e) {
      if (isDisposed || uid != currentUserId) return;
      setLastError('Không lưu được thông báo vừa mở.');
      lastTappedRoute = item.destinationRoute;
      lastTappedArgument = item.destinationArgument;
      notifyListeners();
    }
    unawaited(
      analyticsService?.logNotificationReceived(type: item.type, action: 'tap'),
    );
  }

  /// Marks a notification read locally and remotely. A null/unknown id is a
  /// no-op for Firestore but still clears matching local entries by id.
  /// Optimistic entries (`local_…`, created before Firestore assigned a doc id)
  /// skip the remote write — the doc does not exist under that id yet.
  Future<void> markAsRead(String? notificationId) async {
    if (notificationId == null || notificationId.isEmpty) return;
    if (notificationId.startsWith(announcementIdPrefix)) {
      await markAnnouncementRead(
        notificationId.substring(announcementIdPrefix.length),
      );
      return;
    }
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

  /// Marks a broadcast read for this student. Read ids are stored on the user
  /// profile because the announcement document itself is shared.
  Future<void> markAnnouncementRead(String announcementId) async {
    if (announcementId.isEmpty ||
        _readAnnouncementIds.contains(announcementId)) {
      return;
    }
    final uid = currentUserId;
    final previous = Set<String>.from(_readAnnouncementIds);
    _readAnnouncementIds = {..._readAnnouncementIds, announcementId};
    notifyListeners();
    if (uid == null || firestoreService == null) return;
    try {
      await firestoreService!.saveAcademicProfile(uid, {
        'readAnnouncementIds': _readAnnouncementIds.toList(),
      });
    } catch (e) {
      if (isDisposed || uid != currentUserId) return;
      _readAnnouncementIds = previous;
      notifyListeners();
      setLastError('Không thể đánh dấu đã đọc thông báo.');
    }
  }

  void consumeTappedRoute() {
    lastTappedRoute = null;
    lastTappedArgument = null;
  }

  void dismissBanner() {
    if (_banner == null) return;
    _banner = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _foregroundSub?.cancel();
    _tapSub?.cancel();
    _authSub?.cancel();
    _announcementSub?.cancel();
    super.dispose();
  }
}
