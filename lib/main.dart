import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/advisor_screen.dart';
import 'screens/course_detail_screen.dart';
import 'screens/home_screen.dart';
import 'screens/note_editor_screen.dart';
import 'screens/notes_screen.dart';
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
import 'services/firebase_storage_service.dart';
import 'services/firestore_service.dart';
import 'services/mock_auth_service.dart';
import 'services/mock_firestore_service.dart';
import 'services/remote_config_service.dart';
import 'services/storage_service.dart';
import 'theme/app_theme.dart';
import 'viewmodels/advisor_viewmodel.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/home_viewmodel.dart';
import 'viewmodels/notes_viewmodel.dart';
import 'viewmodels/roadmap_viewmodel.dart';
import 'viewmodels/tasks_viewmodel.dart';
import 'widgets/app_navigation.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Suite
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('[Firebase] Initialized successfully.');

    // Initialize Crashlytics & Remote Config
    await CrashlyticsService().initialize();
    await RemoteConfigService().initialize();
  } catch (e) {
    debugPrint('[Firebase] Initialization caught (running with fallback): $e');
  }

  runApp(const FptuSecondBrainApp());
}

class FptuSecondBrainApp extends StatelessWidget {
  const FptuSecondBrainApp({
    super.key,
    this.authService,
    this.firestoreService,
    this.storageService,
    this.analyticsService,
    this.crashlyticsService,
    this.remoteConfigService,
  });

  final AuthService? authService;
  final FirestoreService? firestoreService;
  final StorageService? storageService;
  final AnalyticsService? analyticsService;
  final CrashlyticsService? crashlyticsService;
  final RemoteConfigService? remoteConfigService;

  bool get _hasFirebase => Firebase.apps.isNotEmpty;

  @override
  Widget build(BuildContext context) => MultiProvider(
        providers: [
          // ── Core Service Layer ──
          Provider<AuthService>(
            create: (_) =>
                authService ??
                (_hasFirebase ? FirebaseAuthService() : MockAuthService()),
          ),
          Provider<FirestoreService>(
            create: (_) =>
                firestoreService ??
                (_hasFirebase ? FirebaseFirestoreService() : MockFirestoreService()),
          ),
          Provider<StorageService>(
            create: (_) =>
                storageService ??
                (_hasFirebase ? FirebaseStorageService() : FirebaseStorageService()),
          ),
          Provider<AnalyticsService>(
            create: (_) =>
                analyticsService ?? FirebaseAnalyticsService(),
          ),
          Provider<CrashlyticsService>(
            create: (_) =>
                crashlyticsService ?? CrashlyticsService(),
          ),
          Provider<RemoteConfigService>(
            create: (_) =>
                remoteConfigService ?? RemoteConfigService(),
          ),

          // ── ViewModel Layer ──
          ChangeNotifierProvider<AuthViewModel>(
            create: (ctx) => AuthViewModel(authService: ctx.read<AuthService>()),
          ),
          ChangeNotifierProvider<HomeViewModel>(create: (_) => HomeViewModel()),
          ChangeNotifierProvider<RoadmapViewModel>(
            create: (ctx) => RoadmapViewModel(
              firestoreService: ctx.read<FirestoreService>(),
              analyticsService: ctx.read<AnalyticsService>(),
            ),
          ),
          ChangeNotifierProvider<TasksViewModel>(
            create: (ctx) => TasksViewModel(
              firestoreService: ctx.read<FirestoreService>(),
              analyticsService: ctx.read<AnalyticsService>(),
            ),
          ),
          ChangeNotifierProvider<NotesViewModel>(
            create: (ctx) => NotesViewModel(
              firestoreService: ctx.read<FirestoreService>(),
              storageService: ctx.read<StorageService>(),
              analyticsService: ctx.read<AnalyticsService>(),
            ),
          ),
          ChangeNotifierProvider<AdvisorViewModel>(
            create: (ctx) => AdvisorViewModel(
              remoteConfigService: ctx.read<RemoteConfigService>(),
              analyticsService: ctx.read<AnalyticsService>(),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'FPTU Second Brain',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          home: const AuthGate(),
          routes: {
            '/home': (_) => const AppShell(),
            '/sign-in': (_) => const SignInScreen(),
            '/course-detail': (ctx) => CourseDetailScreen(
                  courseId: ModalRoute.of(ctx)!.settings.arguments as String? ?? '',
                ),
            '/note-editor': (ctx) => NoteEditorScreen(
                  noteId: ModalRoute.of(ctx)!.settings.arguments as String?,
                ),
            '/advisor': (_) => const AdvisorScreen(),
            '/strategy-sim': (_) => const StrategySimScreen(),
            '/sync-vault': (_) => const SyncVaultScreen(),
          },
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

  void _onTabSelected(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
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
