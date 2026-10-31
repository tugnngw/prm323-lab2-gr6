import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/advisor_screen.dart';
import 'screens/course_detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/note_editor_screen.dart';
import 'screens/notes_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/roadmap_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/strategy_sim_screen.dart';
import 'screens/sync_vault_screen.dart';
import 'screens/tasks_screen.dart';
import 'services/analytics_service.dart';
import 'services/auth_service.dart';
import 'services/crashlytics_service.dart';
import 'services/firebase_analytics_service.dart';
import 'services/firebase_auth_service.dart';
import 'services/firebase_firestore_service.dart';
import 'services/firebase_messaging_service.dart';
import 'services/firebase_storage_service.dart';
import 'services/firestore_service.dart';
import 'services/messaging_service.dart';
import 'services/remote_config_service.dart';
import 'services/report_export_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/advisor_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/notes_viewmodel.dart';
import 'viewmodels/notifications_viewmodel.dart';
import 'viewmodels/roadmap_viewmodel.dart';
import 'viewmodels/tasks_viewmodel.dart';
import 'widgets/app_navigation.dart';

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

    // Initialize Crashlytics & Remote Config (single instances shared with DI).
    final crashlytics = CrashlyticsService();
    final remoteConfig = RemoteConfigService();
    await crashlytics.initialize();
    await remoteConfig.initialize();
    _sharedCrashlytics = crashlytics;
    _sharedRemoteConfig = remoteConfig;

    // FCM: background/terminated handler must be attached before init of any
    // messaging stream (Lab 3 T12).
    FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);
  } catch (e) {
    _firebaseInitError = e;
    debugPrint('[Firebase] Initialization FAILED — showing blocking error screen: $e');
  }

  runApp(FptuSecondBrainApp(
    initError: _firebaseInitError,
    crashlyticsService: _sharedCrashlytics,
    remoteConfigService: _sharedRemoteConfig,
  ));
}

CrashlyticsService? _sharedCrashlytics;
RemoteConfigService? _sharedRemoteConfig;

class FptuSecondBrainApp extends StatelessWidget {
  const FptuSecondBrainApp({
    super.key,
    this.authService,
    this.firestoreService,
    this.storageService,
    this.analyticsService,
    this.messagingService,
    this.crashlyticsService,
    this.remoteConfigService,
    this.initError,
  });

  final AuthService? authService;
  final FirestoreService? firestoreService;
  final StorageService? storageService;
  final AnalyticsService? analyticsService;

  /// Push transport (Lab 3 T12). Real composition builds
  /// [FirebaseMessagingService]; widget tests inject a fake under test/.
  final MessagingService? messagingService;
  final CrashlyticsService? crashlyticsService;
  final RemoteConfigService? remoteConfigService;

  /// Non-null when Firebase initialization failed in [main]. The app then shows
  /// a blocking error screen instead of silently serving mock data (T04).
  /// Injected services (widget tests) bypass the real Firebase wiring.
  final Object? initError;

  bool get _usesRealComposition => authService == null;

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
          Provider<AnalyticsService>(
            create: (_) => analyticsService ?? FirebaseAnalyticsService(),
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
          Provider<RemoteConfigService>(
            create: (_) => remoteConfigService ?? RemoteConfigService(),
          ),
          Provider<ReportExportService>(
            create: (ctx) => ReportExportService(
              storageService: ctx.read<StorageService>(),
              firestoreService: ctx.read<FirestoreService>(),
              analyticsService: ctx.read<AnalyticsService>(),
            ),
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
              analyticsService: ctx.read<AnalyticsService>(),
            ),
          ),
          ChangeNotifierProvider<AdvisorViewModel>(
            create: (ctx) => AdvisorViewModel(
              remoteConfigService: ctx.read<RemoteConfigService>(),
              analyticsService: ctx.read<AnalyticsService>(),
              authService: ctx.read<AuthService>(),
            ),
          ),
        ],
        child: Builder(
          builder: (ctx) => MaterialApp(
            title: 'FPTU Second Brain',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            navigatorObservers:
                ctx.read<AnalyticsService>().navigatorObservers,
            home: const AuthGate(),
            routes: {
              '/home': (_) => const AppShell(),
              '/sign-in': (_) => const SignInScreen(),
              '/course-detail': (ctx) => CourseDetailScreen(
                    courseId:
                        ModalRoute.of(ctx)!.settings.arguments as String? ?? '',
                  ),
              '/note-editor': (ctx) => NoteEditorScreen(
                    noteId: ModalRoute.of(ctx)!.settings.arguments as String?,
                  ),
              '/advisor': (_) => const AdvisorScreen(),
              '/strategy-sim': (_) => const StrategySimScreen(),
              '/sync-vault': (_) => const SyncVaultScreen(),
              '/notifications': (_) => const NotificationsScreen(),
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
        title: 'FPTU Second Brain',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off_rounded,
                      size: 64, color: Color(0xFFB3261E)),
                  const SizedBox(height: 16),
                  const Text(
                    'Không thể kết nối Firebase',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ứng dụng yêu cầu cấu hình Firebase hợp lệ '
                    '(google-services.json + firebase_options.dart).\n\n'
                    '$initError',
                    style: const TextStyle(fontSize: 13, color: Colors.black87),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}

/// Authentication Gate: Routes to [AppShell] when authenticated, [SignInScreen] otherwise.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    if (authVm.isAuthenticated) {
      return const AppShell();
    }
    return const SignInScreen();
  }
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
    vm.consumeTappedRoute();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) Navigator.pushNamed(context, route);
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
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: [
          HomeScreen(onNavigate: _onTabSelected),
          const RoadmapScreen(),
          const TasksScreen(),
          const NotesScreen(),
        ],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onSelected: _onTabSelected,
      ),
    );
  }
}
