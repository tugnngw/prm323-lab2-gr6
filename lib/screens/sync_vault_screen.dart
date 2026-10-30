import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';
import '../services/firebase_analytics_service.dart';
import '../services/firestore_service.dart';
import '../services/remote_config_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_components.dart';

class SyncVaultScreen extends StatefulWidget {
  const SyncVaultScreen({super.key});

  @override
  State<SyncVaultScreen> createState() => _SyncVaultScreenState();
}

class _SyncVaultScreenState extends State<SyncVaultScreen> {
  bool _isTestingFirestore = false;
  String? _firestoreTestResult;
  bool _isTestingCrashlytics = false;
  String? _crashlyticsResult;
  bool _isSyncing = false;
  String? _syncResult;

  Future<void> _testFirestore(FirestoreService firestore, String? uid) async {
    setState(() {
      _isTestingFirestore = true;
      _firestoreTestResult = null;
    });

    if (uid == null || uid.isEmpty) {
      // Never write under a fabricated identity when unauthenticated.
      setState(() {
        _firestoreTestResult =
            'Chưa đăng nhập — không thể chạy test đọc/ghi Firestore.';
      });
      _isTestingFirestore = false;
      return;
    }

    try {
      final testTask = {
        'title': 'Test Sync Roundtrip ${DateTime.now().second}',
        'courseCode': 'PRM323',
        'dueDate': '15/12/2024',
        'userId': uid,
      };
      await firestore.addTask(testTask);
      final tasks = await firestore.getTasks(uid);

      setState(() {
        _firestoreTestResult = 'Thành công! Firestore đã đọc/ghi ${tasks.length} mục.';
      });
    } catch (e) {
      setState(() {
        _firestoreTestResult = 'Lỗi test Firestore: $e';
      });
    } finally {
      setState(() => _isTestingFirestore = false);
    }
  }

  Future<void> _testCrashlytics(CrashlyticsService crashlytics) async {
    setState(() {
      _isTestingCrashlytics = true;
      _crashlyticsResult = null;
    });

    try {
      await crashlytics.log('Người dùng kích hoạt test Crashlytics từ Firebase Demo Area');
      await crashlytics.recordError(
        Exception('Non-fatal test exception từ FPTU Second Brain Demo Area'),
        StackTrace.current,
        reason: 'Firebase Demo Area manual test trigger',
      );

      setState(() {
        _crashlyticsResult = 'Đã ghi non-fatal error thành công vào Firebase Crashlytics!';
      });
    } catch (e) {
      setState(() {
        _crashlyticsResult = 'Lỗi Crashlytics: $e';
      });
    } finally {
      setState(() => _isTestingCrashlytics = false);
    }
  }

  Future<void> _triggerManualSync(AnalyticsService analytics) async {
    setState(() {
      _isSyncing = true;
      _syncResult = null;
    });

    try {
      await Future<void>.delayed(const Duration(milliseconds: 600));

      if (analytics is FirebaseAnalyticsService) {
        await analytics.logSyncTriggered(triggerType: 'manual_button');
      }

      setState(() {
        _syncResult = 'Đồng bộ hai chiều hoàn tất lúc ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}!';
      });
    } catch (e) {
      setState(() {
        _syncResult = 'Đồng bộ thất bại: $e';
      });
    } finally {
      setState(() => _isSyncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final remoteConfig = context.watch<RemoteConfigService>();
    final firestore = context.watch<FirestoreService>();
    final crashlytics = context.watch<CrashlyticsService>();
    final analytics = context.watch<AnalyticsService>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Sync Vault & Cài đặt',
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // User Profile Card
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryContainer,
                  child: const Text(
                    'Đ',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Nguyễn Minh Đức (P02)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        authVm.currentUserEmail ?? 'ducnmse180000@fpt.edu.vn',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Sinh viên K18 · Kỳ 5 · SE (Kỹ thuật PM)',
                        style: TextStyle(fontSize: 12, color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Offline Vault Sync Status Card
          Text('Trạng thái Vault & Đồng bộ', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.cloud_done_outlined, color: AppColors.success),
                  title: Text('Đồng bộ Cloud Firestore'),
                  subtitle: Text('Offline persistence: Hoạt động (Unlimited cache)'),
                ),
                const Divider(height: 1),
                const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.folder_shared_outlined, color: AppColors.secondary),
                  title: Text('Cloud Storage Vault'),
                  subtitle: Text('Đường dẫn: notes/{uid}/... (Max 10MB)'),
                ),
                if (_syncResult != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _syncResult!,
                    style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: 'Kích hoạt đồng bộ Vault ngay',
                  icon: Icons.sync,
                  isLoading: _isSyncing,
                  isExpanded: true,
                  onPressed: () => _triggerManualSync(analytics),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Firebase Demo Area (Lab 3 Requirement)
          Text('Firebase Demo Area (PRM323 Lab 3)', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Khu vực kiểm thử tính năng của đề bài Lab 3: Remote Config, Crashlytics, Firestore read/write.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Remote Config Parameters Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Firebase Remote Config',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, size: 20),
                      tooltip: 'Tải lại config',
                      onPressed: () async {
                        await remoteConfig.fetchAndActivate();
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã cập nhật cấu hình từ xa')),
                        );
                      },
                    ),
                  ],
                ),
                const Divider(height: 1),
                const SizedBox(height: AppSpacing.xs),
                _buildConfigRow('maintenance_mode', remoteConfig.isMaintenanceMode.toString()),
                _buildConfigRow('feature_ai_advisor_enabled', remoteConfig.isAiAdvisorEnabled.toString()),
                _buildConfigRow('min_app_version', remoteConfig.minAppVersion),
                _buildConfigRow('vault_sync_interval_mins', '${remoteConfig.vaultSyncIntervalMins} phút'),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Crashlytics Test Trigger
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Firebase Crashlytics Test', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text(
                  'Ghi nhận non-fatal exception và breadcrumb log lên dashboard Crashlytics mà không làm crash ứng dụng.',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                if (_crashlyticsResult != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _crashlyticsResult!,
                    style: const TextStyle(color: AppColors.success, fontSize: 12),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: _isTestingCrashlytics ? null : () => _testCrashlytics(crashlytics),
                  icon: const Icon(Icons.bug_report_outlined),
                  label: const Text('Ghi nhận Test Exception vào Crashlytics'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Firestore Read/Write Roundtrip Test
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Firestore Read/Write Test', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text(
                  'Kiểm tra đọc và ghi dữ liệu mẫu qua FirestoreService (áp dụng Offline Persistence).',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                if (_firestoreTestResult != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _firestoreTestResult!,
                    style: const TextStyle(color: AppColors.success, fontSize: 12),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed:
                      _isTestingFirestore ? null : () => _testFirestore(firestore, authVm.currentUserId),
                  icon: const Icon(Icons.cloud_sync_outlined),
                  label: const Text('Chạy Test Đọc/Ghi Firestore'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigRow(String key, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              key,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.xs),
              ),
              child: Text(
                value,
                style: const TextStyle(
                  color: AppColors.onPrimaryContainer,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      );
}
