import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:study_pilot_core/study_pilot_core.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase/firebase_options.dart';
import 'models/app_state.dart';
import 'screens/advisor_screen.dart';
import 'screens/announcements_screen.dart';
import 'screens/study_plan_screen.dart';
import 'screens/academic_profile_screen.dart';
import 'viewmodels/academic_viewmodel.dart';
import 'screens/course_detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/major_onboarding_screen.dart';
import 'screens/my_tips_screen.dart';
import 'screens/note_editor_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/roadmap_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/strategy_sim_screen.dart';
import 'screens/sync_vault_screen.dart';
import 'screens/tasks_screen.dart';
import 'services/analytics_service.dart';
import 'services/ai_service.dart';
import 'services/app_check_service.dart';
import 'services/auth_service.dart';
import 'services/crashlytics_service.dart';
import 'services/firebase_analytics_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/firebase_firestore_service.dart';
import 'services/firebase_messaging_service.dart';
import 'services/firebase_storage_service.dart';
import 'services/firestore_service.dart';
import 'services/local_notification_service.dart';
import 'services/messaging_service.dart';
import 'services/remote_config_service.dart';
import 'services/report_export_service.dart';
import 'services/report_media_storage_service.dart';
import 'services/storage_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_spacing.dart';
import 'theme/app_theme.dart';
import 'viewmodels/advisor_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/notes_viewmodel.dart';
import 'viewmodels/notifications_viewmodel.dart';
import 'viewmodels/roadmap_viewmodel.dart';
import 'viewmodels/tasks_viewmodel.dart';
import 'widgets/app_components.dart';
import 'widgets/app_navigation.dart';
import 'widgets/app_states.dart';
import 'widgets/reminder_sync.dart';

/// Captured Firebase initialization failure (T04: fail loud, never mock silently).
/// Null means Firebase initialized OK. Tests may inject services directly.
Object? _firebaseInitError;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Suite — a failure here is a hard configuration error.
  // We keep running (so the error screen can render) but the app refuses to
  // serve mock data as if it were the real backend (guide v5 §1.4).
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[Firebase] Initialized successfully.');

    // App Check is required by Firestore/AI Logic in production, but a failed
    // activation must degrade (requests rejected + visible error) instead of
    // blocking the whole app from starting.
    try {
      await AppCheckService.activate();
    } catch (e) {
      debugPrint('[AppCheck] Activation failed, continuing: $e');
    }

    // Crashlytics & Remote Config each fall back to their in-app defaults.
    final crashlytics = CrashlyticsService();
    final remoteConfig = RemoteConfigService();
    try {
      await crashlytics.initialize();
    } catch (e) {
      debugPrint('[Crashlytics] Initialization failed, continuing: $e');
    }
    try {
      await remoteConfig.initialize();
    } catch (e) {
      debugPrint('[RemoteConfig] Initialization failed, using defaults: $e');
    }
    _sharedCrashlytics = crashlytics;
    _sharedRemoteConfig = remoteConfig;

    // FCM: background/terminated handler must be attached before init of any
    // messaging stream (Lab 3 T12).
    FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);

    // Local reminders (class start −15 min, task deadlines). A failure here
    // must not block the app: initialize() swallows platform errors.
    _sharedLocalNotifications = await LocalNotificationService.initialize();
  } catch (e) {
    _firebaseInitError = e;
    debugPrint(
      '[Firebase] Initialization FAILED — showing blocking error screen: $e',
    );
  }

  runApp(
    StudyPilotApp(
      initError: _firebaseInitError,
      crashlyticsService: _sharedCrashlytics,
      remoteConfigService: _sharedRemoteConfig,
      localNotificationService: _sharedLocalNotifications,
    ),
  );
}

CrashlyticsService? _sharedCrashlytics;
RemoteConfigService? _sharedRemoteConfig;
LocalNotificationService? _sharedLocalNotifications;

class StudyPilotApp extends StatelessWidget {
  const StudyPilotApp({
    super.key,
    this.authService,
    this.firestoreService,
    this.storageService,
    this.analyticsService,
    this.aiService,
    this.messagingService,
    this.crashlyticsService,
    this.remoteConfigService,
    this.localNotificationService,
    this.initError,
  });

  final AuthService? authService;
  final FirestoreService? firestoreService;
  final StorageService? storageService;
  final AnalyticsService? analyticsService;
  final AiService? aiService;

  /// Push transport (Lab 3 T12). Real composition builds
  /// [FirebaseMessagingService]; widget tests inject a fake under test/.
  final MessagingService? messagingService;
  final CrashlyticsService? crashlyticsService;
  final RemoteConfigService? remoteConfigService;

  /// OS-level study reminders. Null in widget tests and on unsupported
  /// platforms, where reminders are simply disabled.
  final LocalNotificationService? localNotificationService;

  /// Non-null when Firebase initialization failed in [main]. The app then shows
  /// a blocking error screen instead of silently serving mock data (T04).
  /// Injected services (widget tests) bypass the real Firebase wiring.
  final Object? initError;

  bool get _usesRealComposition => authService == null;

  static const _legacyMedia = bool.fromEnvironment('LAB3_LEGACY_MEDIA');
  static const _mediaUrl = String.fromEnvironment('REPORT_MEDIA_URL');

  bool get _showLegacyMedia =>
      !_usesRealComposition || _legacyMedia || _mediaUrl.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    if (initError != null && _usesRealComposition) {
      return FirebaseConfigErrorApp(initError: initError!);
    }
    return _buildProvisionedApp();
  }

  Widget _buildProvisionedApp() => MultiProvider(
    providers: [
      // ── Core Service Layer ──
      // Firebase is guaranteed available here: main() either initialized it
      // or routed to FirebaseConfigErrorApp. No silent mock fallback.
      Provider<AuthService>(
        create: (_) => authService ?? FirebaseAuthService(),
      ),
      Provider<FirestoreService>(
        create: (_) => firestoreService ?? FirebaseFirestoreService(),
      ),
      Provider<StorageService>(
        create: (_) => storageService ?? FirebaseStorageService(),
      ),
      // Shared query layer for the course-tips / announcements features.
      // Built once here (composition root) so widgets never touch the SDK.
      Provider<FinalFirestore?>(
        create: (_) => _usesRealComposition && Firebase.apps.isNotEmpty
            ? FinalFirestore(FirebaseFirestore.instance)
            : null,
      ),
      Provider<ReportMediaStorageService?>(
        create: (_) {
          return _usesRealComposition && _mediaUrl.isNotEmpty
              ? ReportMediaStorageService(Uri.parse(_mediaUrl))
              : null;
        },
      ),
      Provider<AnalyticsService>(
        create: (_) => analyticsService ?? FirebaseAnalyticsService(),
      ),
      Provider<AiService>(
        create: (_) => aiService ?? GeminiAiService(),
      ),
      // Push transport. Nullable on purpose: hermetic widget tests run
      // without a real Firebase app, so we must NOT construct
      // FirebaseMessagingService there — consumers handle a null
      // MessagingService by disabling push (never by faking one).
      Provider<MessagingService?>(
        create: (_) {
          if (messagingService != null) return messagingService;
          if (!_usesRealComposition) return null;
          return FirebaseMessagingService()..attach();
        },
      ),
      Provider<CrashlyticsService>(
        create: (_) => crashlyticsService ?? CrashlyticsService(),
      ),
      Provider<LocalNotificationService?>.value(value: localNotificationService),
      ChangeNotifierProvider<RemoteConfigService>(
        create: (_) => remoteConfigService ?? RemoteConfigService(),
      ),
      Provider<ReportExportService>(
        create: (ctx) {
          final media = ctx.read<ReportMediaStorageService?>();
          return ReportExportService(
            storageService: media ?? ctx.read<StorageService>(),
            firebaseStorageService: ctx.read<StorageService>(),
            storageProvider: media == null
                ? 'Firebase Cloud Storage'
                : 'Cloudinary',
            firestoreService: ctx.read<FirestoreService>(),
            analyticsService: ctx.read<AnalyticsService>(),
            crashlyticsService: ctx.read<CrashlyticsService>(),
          );
        },
      ),

      // ── ViewModel Layer ──
      ChangeNotifierProvider<AuthViewModel>(
        create: (ctx) => AuthViewModel(
          authService: ctx.read<AuthService>(),
          analyticsService: ctx.read<AnalyticsService>(),
          crashlyticsService: ctx.read<CrashlyticsService>(),
          messagingService: ctx.read<MessagingService?>(),
          firestoreService: ctx.read<FirestoreService>(),
        ),
      ),
      ChangeNotifierProvider<NotificationsViewModel>(
        create: (ctx) => NotificationsViewModel(
          authService: ctx.read<AuthService>(),
          firestoreService: ctx.read<FirestoreService>(),
          messagingService: ctx.read<MessagingService?>(),
          analyticsService: ctx.read<AnalyticsService>(),
        ),
      ),
      ChangeNotifierProvider<RoadmapViewModel>(
        create: (ctx) => RoadmapViewModel(
          authService: ctx.read<AuthService>(),
          firestoreService: ctx.read<FirestoreService>(),
          analyticsService: ctx.read<AnalyticsService>(),
        ),
      ),
      ChangeNotifierProvider<TasksViewModel>(
        create: (ctx) => TasksViewModel(
          authService: ctx.read<AuthService>(),
          firestoreService: ctx.read<FirestoreService>(),
          analyticsService: ctx.read<AnalyticsService>(),
        ),
      ),
      ChangeNotifierProvider<NotesViewModel>(
        create: (ctx) => NotesViewModel(
          authService: ctx.read<AuthService>(),
          firestoreService: ctx.read<FirestoreService>(),
          storageService: ctx.read<StorageService>(),
          mediaStorageService: ctx.read<ReportMediaStorageService?>(),
          analyticsService: ctx.read<AnalyticsService>(),
        ),
      ),
      ChangeNotifierProvider<AcademicViewModel>(
        create: (ctx) => AcademicViewModel(
          authService: ctx.read<AuthService>(),
          firestoreService: ctx.read<FirestoreService>(),
        ),
      ),
      ChangeNotifierProvider<AdvisorViewModel>(
        create: (ctx) => AdvisorViewModel(
          academicViewModel: ctx.read<AcademicViewModel>(),
          remoteConfigService: ctx.read<RemoteConfigService>(),
          analyticsService: ctx.read<AnalyticsService>(),
          authService: ctx.read<AuthService>(),
          aiService: ctx.read<AiService>(),
          store: ctx.read<FinalFirestore?>(),
        ),
      ),
    ],
    child: Builder(
      builder: (ctx) => MaterialApp(
        // Drop pushed private screens as well as tab state on identity change.
        key: ValueKey(ctx.watch<AuthViewModel>().currentUserId),
        title: 'StudyPilot',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        navigatorObservers: ctx.read<AnalyticsService>().navigatorObservers,
        home: ReminderSync(
          child: AuthGate(checkRole: _usesRealComposition),
        ),
        routes: {
          '/home': (_) => AuthGate(checkRole: _usesRealComposition),
          '/sign-in': (_) => const SignInScreen(),
          '/course-detail': (ctx) {
            final uid = _usesRealComposition
                ? ctx.read<AuthViewModel>().currentUserId
                : null;
            return CourseDetailScreen(
              courseId: ModalRoute.of(ctx)!.settings.arguments as String? ?? '',
              store: ctx.read<FinalFirestore?>(),
              currentUid: uid,
            );
          },
          if (_usesRealComposition)
            '/course-tips': (ctx) {
              final uid = ctx.read<AuthViewModel>().currentUserId;
              return CourseDetailScreen(
                courseId:
                    ModalRoute.of(ctx)!.settings.arguments as String? ?? '',
                store: ctx.read<FinalFirestore?>(),
                currentUid: uid,
                initialTab: 3,
              );
            },
          if (_usesRealComposition)
            '/my-tips': (ctx) {
              final uid = ctx.read<AuthViewModel>().currentUserId;
              if (uid == null) return const SignInScreen();
              return MyTipsScreen(
                store: ctx.read<FinalFirestore?>()!,
                uid: uid,
              );
            },
          '/note-editor': (_) =>
              NoteEditorScreen(showLegacyMedia: _showLegacyMedia),
          '/academic-profile': (_) =>
              AcademicProfileScreen(),
          if (_usesRealComposition)
            '/study-plan': (context) {
              final uid = context.read<AuthViewModel>().currentUserId;
              if (uid == null) return const SignInScreen();
              return StudyPlanScreen(
                store: ctx.read<FinalFirestore?>()!,
                uid: uid,
              );
            },
          if (_usesRealComposition)
            '/announcements': (_) => AnnouncementsScreen(
              store: ctx.read<FinalFirestore?>()!,
            ),
          '/advisor': (_) => const AdvisorScreen(),
          '/strategy-sim': (_) => const StrategySimScreen(),
          // PDF cloud upload is a Lab 3 Storage requirement, not legacy media.
          '/sync-vault': (_) => const SyncVaultScreen(showLegacyMedia: true),
          '/notifications': (_) =>
              NotificationsScreen(showAnnouncements: _usesRealComposition),
          '/roadmap': (_) => const RoadmapScreen(),
          '/tasks': (_) => const TasksScreen(),
          '/notes': (_) => const NotesScreen(),
        },
      ),
    ),
  );
}

/// Blocking full-screen error shown when Firebase failed to initialize.
/// Replaces the old silent mock fallback so a broken configuration can never
/// masquerade as a working app (Lab 3 guide §1.4 "fail loudly").
class FirebaseConfigErrorApp extends StatelessWidget {
  const FirebaseConfigErrorApp({super.key, required this.initError});

  final Object initError;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'StudyPilot',
    debugShowCheckedModeBanner: false,
    theme: AppTheme.light(),
    home: Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.cloud_off_rounded,
                size: 64,
                color: AppColors.error,
              ),
              const SizedBox(height: 16),
              const Text(
                'Không thể kết nối Firebase',
                style: TextStyle(
                  fontSize: AppFontSize.heading,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Ứng dụng yêu cầu cấu hình Firebase hợp lệ '
                '(google-services.json + firebase_options.dart).\n\n'
                '$initError',
                style: const TextStyle(
                  fontSize: AppFontSize.dense,
                  color: AppColors.onSurface,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Authentication Gate: routes to [AppShell] when authenticated,
/// [SignInScreen] otherwise.
///
/// Two Remote Config gates run *before* the shell (audit M-09 — a flag that is
/// only printed in the Demo Area is not "enforced"):
/// 1. `min_app_version` — an outdated build is blocked even before sign-in, so
///    a user on an old APK cannot keep using removed/broken cloud calls.
/// 2. `maintenance_mode` — blocks signed-in users while the backend is down.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key, this.checkRole = false});

  final bool checkRole;

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool _checking = false;

  /// Re-fetch Remote Config and re-evaluate both gates. Returns true when the
  /// blocking screen may be left. A failed fetch simply keeps the current
  /// values, so the failure surfaces as "still blocked" plus a snackbar.
  Future<bool> _recheck() async {
    if (_checking) return false;
    setState(() => _checking = true);
    final rc = context.read<RemoteConfigService>();
    await rc.fetchAndActivate();
    if (!mounted) return false;
    setState(() => _checking = false);
    return !rc.isVersionBelowMinimum && !rc.isMaintenanceMode;
  }

  Future<void> _retry() async {
    final rc = context.read<RemoteConfigService>();
    final blockedBefore = rc.isVersionBelowMinimum;
    final cleared = await _recheck();
    if (!mounted || cleared) return;
    final message = blockedBefore
        ? 'Ứng dụng vẫn cần cập nhật lên phiên bản ${rc.minAppVersion}.'
        : 'Ứng dụng vẫn đang bảo trì.';
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final rc = context.watch<RemoteConfigService>();

    if (rc.isVersionBelowMinimum) {
      return VersionBlockedScreen(
        currentVersion: kAppVersion,
        minimumVersion: rc.minAppVersion,
        checking: _checking,
        onRecheck: _retry,
      );
    }

    if (!authVm.isAuthenticated) return const SignInScreen();

    if (rc.isMaintenanceMode) {
      return MaintenanceScreen(checking: _checking, onRecheck: _retry);
    }

    final uid = authVm.currentUserId;
    final shell = const _MajorOnboardingGate(child: AppShell());
    if (widget.checkRole && uid != null) {
      return _MobileRoleGate(key: ValueKey(uid), uid: uid, child: shell);
    }
    return shell;
  }
}

/// Blocks the student shell until a curriculum is selected. A major that no
/// longer exists in the admin catalog is treated as "not selected" so the
/// student can pick again instead of seeing an empty roadmap.
class _MajorOnboardingGate extends StatelessWidget {
  const _MajorOnboardingGate({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final academic = context.watch<AcademicViewModel>();
    switch (academic.state.state) {
      case ViewState.loading:
        return const Scaffold(
          body: AppLoadingState(message: 'Đang tải dữ liệu học tập...'),
        );
      case ViewState.error:
        return Scaffold(
          body: AppErrorState(
            message:
                academic.state.message ?? 'Không tải được dữ liệu học tập.',
            onRetry: academic.loadData,
          ),
        );
      case ViewState.empty:
      case ViewState.data:
        break;
    }
    final majors = academic.availableMajors;
    final major = academic.profile.major.trim();
    final valid = major.isNotEmpty &&
        (majors.isEmpty ||
            majors.any(
              (m) => m.code.toUpperCase() == major.toUpperCase(),
            ));
    if (!valid) return const MajorOnboardingScreen();
    return child;
  }
}

class _MobileRoleGate extends StatefulWidget {
  const _MobileRoleGate({
    super.key,
    required this.uid,
    required this.child,
  });

  final String uid;
  final Widget child;

  @override
  State<_MobileRoleGate> createState() => _MobileRoleGateState();
}

class _MobileRoleGateState extends State<_MobileRoleGate> {
  late final Stream<String?> _role = context
      .read<FirestoreService>()
      .watchUserRole(widget.uid);

  @override
  Widget build(BuildContext context) => StreamBuilder<String?>(
    stream: _role,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          body: Center(
            child: TextButton(
              onPressed: context.read<AuthViewModel>().signOut,
              child: const Text('Không xác minh được vai trò. Đăng xuất'),
            ),
          ),
        );
      }
      if (snapshot.connectionState == ConnectionState.waiting &&
          !snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final role = snapshot.data ?? 'user';
      if (role == 'user') return widget.child;
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tài khoản Staff/Admin dùng cổng quản trị web.'),
              TextButton(
                onPressed: context.read<AuthViewModel>().signOut,
                child: const Text('Đăng xuất'),
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Shown instead of the shell when Remote Config `min_app_version` is newer
/// than this build (audit M-09). Deliberately offers no "continue anyway" —
/// the only actions are retry (the value may have been lowered) and closing the
/// app to install the store update.
class VersionBlockedScreen extends StatelessWidget {
  const VersionBlockedScreen({
    super.key,
    required this.currentVersion,
    required this.minimumVersion,
    required this.checking,
    required this.onRecheck,
  });

  final String currentVersion;
  final String minimumVersion;
  final bool checking;
  final Future<void> Function() onRecheck;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.system_update_rounded, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Cần cập nhật ứng dụng',
              style: TextStyle(
                fontSize: AppFontSize.heading,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Phiên bản hiện tại $currentVersion thấp hơn mức tối thiểu '
              '$minimumVersion. Vui lòng cập nhật từ Google Play để tiếp tục.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            checking
                ? const CircularProgressIndicator()
                : TextButton(
                    onPressed: onRecheck,
                    child: const Text('Thử lại'),
                  ),
            const SizedBox(height: 8),
            const Text(
              'Cấu hình: Remote Config `min_app_version`.',
              style: TextStyle(fontSize: AppFontSize.label),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    ),
  );
}

/// Shown instead of [AppShell] when Remote Config `maintenance_mode` is on.
/// Signed-in users keep their session; "Thử lại" re-fetches the flag and leaves
/// the screen as soon as maintenance is over.
class MaintenanceScreen extends StatelessWidget {
  const MaintenanceScreen({
    super.key,
    required this.checking,
    required this.onRecheck,
  });

  final bool checking;
  final Future<void> Function() onRecheck;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction_rounded, size: 64),
            const SizedBox(height: 16),
            const Text(
              'Ứng dụng đang bảo trì',
              style: TextStyle(
                fontSize: AppFontSize.heading,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Vui lòng quay lại sau. Cấu hình: Remote Config '
              '`maintenance_mode`.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            checking
                ? const CircularProgressIndicator()
                : TextButton(
                    onPressed: onRecheck,
                    child: const Text('Thử lại'),
                  ),
          ],
        ),
      ),
    ),
  );
}

/// Root shell that manages bottom navigation between the 4 main tabs.
class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  bool _routingTap = false;

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  /// Notification Center tap-routing (Lab 3 T12): when a push wakes the app
  /// from background/terminated, NotificationsViewModel records its route and
  /// we navigate there once per tap. Guarded so a rebuild cannot re-push.
  void _maybeRouteTappedNotification() {
    final vm = context.read<NotificationsViewModel>();
    final route = vm.lastTappedRoute;
    if (route == null || _routingTap) return;
    _routingTap = true;
    final argument = vm.lastTappedArgument;
    vm.consumeTappedRoute();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) Navigator.pushNamed(context, route, arguments: argument);
      _routingTap = false;
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeRouteTappedNotification();
  }

  @override
  Widget build(BuildContext context) {
    // Re-evaluate on every rebuild so a tap arriving while idle routes too.
    _maybeRouteTappedNotification();
    final notificationsVm = context.watch<NotificationsViewModel>();
    final tasksVm = context.watch<TasksViewModel>();
    final banner = notificationsVm.banner;
    // System Back returns to the Home tab instead of exiting from a sub-tab.
    return PopScope(
      canPop: _currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _currentIndex != 0) {
          setState(() => _currentIndex = 0);
        }
      },
      child: Scaffold(
        body: Stack(
          children: [
            IndexedStack(
              index: _currentIndex,
              children: [
                HomeScreen(onNavigate: _onTabSelected),
                const RoadmapScreen(),
                const TasksScreen(),
                const NotesScreen(),
              ],
            ),
            if (banner != null)
              Positioned(
                top: MediaQuery.paddingOf(context).top + 8,
                left: 12,
                right: 12,
                child: ForegroundPushBanner(
                  notification: banner,
                  onOpen: () {
                    notificationsVm.dismissBanner();
                    notificationsVm.markAsRead(banner.id);
                    final route = banner.destinationRoute;
                    if (route != null && route.isNotEmpty) {
                      Navigator.pushNamed(
                        context,
                        route,
                        arguments: banner.destinationArgument,
                      );
                    }
                  },
                  onDismiss: notificationsVm.dismissBanner,
                ),
              ),
          ],
        ),
        bottomNavigationBar: AppBottomNav(
          currentIndex: _currentIndex,
          onSelected: _onTabSelected,
          dueSoonCount: tasksVm.dueSoonCount,
        ),
      ),
    );
  }
}
