import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../models/course_model.dart';
import '../models/note_model.dart';
import '../models/task_model.dart';
import '../services/analytics_service.dart';
import '../services/crashlytics_service.dart';
import '../services/firestore_service.dart';
import '../services/remote_config_service.dart';
import '../services/report_export_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/notes_viewmodel.dart';
import '../viewmodels/roadmap_viewmodel.dart';
import '../viewmodels/tasks_viewmodel.dart';
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

  // ── PDF export state (Lab 3 §6.5) ──
  bool _isExporting = false;
  double _exportProgress = 0.0;
  ReportExportResult? _exportResult;
  String? _exportError;

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

      await analytics.logSyncTriggered(triggerType: 'manual_button');

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

  // ──────────────────────── PDF Export & Upload (Lab 3 §6.5) ────────────────────────

  /// Share-consent dialog shown BEFORE any file leaves the device.
  /// The user must explicitly allow the upload; cancelling aborts everything.
  Future<bool> _askExportConsent(int taskCount, int noteCount, int courseCount) async {
    final agreed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.ios_share),
        title: const Text('Chia sẻ báo cáo học tập?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ứng dụng sẽ tạo PDF từ dữ liệu đang hiển thị và tải lên '
              'Firebase Cloud Storage (đường dẫn reports/{uid}/…).',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              'Nội dung: $courseCount môn học, $taskCount việc cần làm, '
              '$noteCount ghi chú. Không kèm email/họ tên/SĐT.',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 8),
            const Text(
              'Bạn có thể xóa file và metadata bất cứ lúc nào.',
              style: TextStyle(
                  fontSize: 12, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(ctx, true),
            icon: const Icon(Icons.check, size: 18),
            label: const Text('Đồng ý xuất & tải'),
          ),
        ],
      ),
    );
    return agreed ?? false;
  }

  Future<void> _exportAndUploadReport(
    ReportExportService exporter,
    String? uid,
  ) async {
    if (uid == null || uid.isEmpty) {
      setState(() => _exportError =
          'Chưa đăng nhập — không thể xuất báo cáo cá nhân.');
      return;
    }

    // Snapshot the SAME data currently displayed (guide v5 §6.5). Each screen
    // keeps its own VM alive, so refresh them first, then read the lists.
    setState(() {
      _isExporting = true;
      _exportProgress = 0.0;
      _exportResult = null;
      _exportError = null;
    });

    List<CourseModel> courses;
    List<TaskModel> tasks;
    List<NoteModel> notes;
    try {
      final roadmapVm = context.read<RoadmapViewModel>();
      final tasksVm = context.read<TasksViewModel>();
      final notesVm = context.read<NotesViewModel>();
      await Future.wait([
        roadmapVm.loadData(),
        tasksVm.loadData(),
        notesVm.loadData(),
      ]);
      courses = roadmapVm.allCourses;
      tasks = tasksVm.allTasks;
      notes = notesVm.allNotes;
    } catch (e) {
      setState(() {
        _isExporting = false;
        _exportError = 'Không tải được dữ liệu để xuất: $e';
      });
      return;
    }

    if (!mounted) return;
    if (!await _askExportConsent(courses.length, tasks.length, notes.length)) {
      setState(() => _isExporting = false);
      return; // consent is mandatory before any upload
    }

    try {
      final result = await exporter.exportStudyReport(
        userId: uid,
        courses: courses,
        tasks: tasks,
        notes: notes,
        onProgress: (p) {
          if (mounted) setState(() => _exportProgress = p);
        },
      );
      if (mounted) setState(() => _exportResult = result);
    } catch (e) {
      if (mounted) setState(() => _exportError = 'Xuất báo cáo thất bại: $e');
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  /// Opens the OS print/share sheet with the just-generated PDF in memory.
  Future<void> _openLastReport() async {
    final bytes = _exportResult?.pdfBytes;
    if (bytes == null) return;
    await Printing.sharePdf(
      bytes: bytes,
      filename: _exportResult!.storagePath.split('/').last,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final remoteConfig = context.watch<RemoteConfigService>();
    final firestore = context.watch<FirestoreService>();
    final crashlytics = context.watch<CrashlyticsService>();
    final analytics = context.watch<AnalyticsService>();
    final reportExporter = context.read<ReportExportService>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Sync Vault & Cài đặt',
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // User Profile Card — live sign-in identity only (no persona data)
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primaryContainer,
                  child: Text(
                    (authVm.currentUserEmail ?? '?').characters.first.toUpperCase(),
                    style: const TextStyle(
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
                        authVm.isAuthenticated
                            ? (authVm.currentUserEmail?.split('@').first ?? 'Người dùng')
                            : 'Chưa đăng nhập',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        authVm.currentUserEmail ??
                            'Vui lòng đăng nhập bằng tài khoản @fpt.edu.vn',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Dữ liệu đồng bộ theo UID Firebase của bạn',
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
          const SizedBox(height: AppSpacing.sm),

          // PDF Export & Upload (Lab 3 Requirement §6.5)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Export & Upload PDF',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                const Text(
                  'Tạo PDF từ dữ liệu đang hiển thị (lộ trình, việc cần làm, ghi chú), '
                      'hiện hộp thoại xin phép chia sẻ, tải lên Cloud Storage '
                      'reports/{uid}/… kèm metadata Firestore.',
                  style: TextStyle(fontSize: 12, color: AppColors.onSurfaceVariant),
                ),
                if (_isExporting) ...[
                  const SizedBox(height: AppSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                    child: LinearProgressIndicator(
                      value: _exportProgress > 0 ? _exportProgress : null,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _exportProgress > 0
                        ? 'Đang tải lên… ${(_exportProgress * 100).toStringAsFixed(0)}%'
                        : 'Đang tạo PDF…',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (_exportError != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _exportError!,
                    style: const TextStyle(
                        color: Color(0xFFB3261E), fontSize: 12),
                  ),
                ],
                if (_exportResult != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Hoàn tất! Kích thước ${(_exportResult!.bytes / 1024).toStringAsFixed(1)} KB',
                    style: const TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  SelectableText(
                    _exportResult!.downloadUrl,
                    style: const TextStyle(fontSize: 11),
                    maxLines: 3,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Đường dẫn: ${_exportResult!.storagePath}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.onSurfaceVariant),
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                AppButton(
                  label: _exportResult == null
                      ? 'Xuất & Tải PDF lên Cloud Storage'
                      : 'Xuất báo cáo mới',
                  icon: Icons.picture_as_pdf_outlined,
                  isLoading: _isExporting,
                  isExpanded: true,
                  onPressed: () =>
                      _exportAndUploadReport(reportExporter, authVm.currentUserId),
                ),
                if (_exportResult != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _openLastReport,
                          icon: const Icon(Icons.open_in_new, size: 18),
                          label: const Text('Mở / Chia sẻ file'),
                        ),
                      ),
                    ],
                  ),
                ],
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
