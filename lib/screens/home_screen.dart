import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/notifications_viewmodel.dart';
import '../widgets/app_components.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  void _showSignOutDialog(BuildContext context, AuthViewModel authVm) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AppConfirmDialog(
        title: 'Đăng xuất',
        message: 'Bạn có chắc chắn muốn đăng xuất khỏi FPTU Second Brain?',
        onConfirm: () {
          Navigator.pop(ctx);
          authVm.signOut();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final notificationsVm = context.watch<NotificationsViewModel>();
    final unread = notificationsVm.unreadCount;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'FPTU Second Brain',
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: unread > 0,
              label: Text('$unread'),
              child: const Icon(Icons.notifications_outlined),
            ),
            tooltip: 'Trung tâm thông báo',
            onPressed: () => Navigator.pushNamed(context, '/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.sync_outlined),
            tooltip: 'Đồng bộ Vault',
            onPressed: () => Navigator.pushNamed(context, '/sync-vault'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_outlined),
            tooltip: 'Đăng xuất',
            onPressed: () => _showSignOutDialog(context, authVm),
          ),
        ],
      ),
      body: Builder(
        builder: (context) {
          final email = authVm.currentUserEmail;
          final displayName = email != null ? email.split('@').first : 'bạn';

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              // Greeting
              Text('Chào $displayName 👋', style: Theme.of(context).textTheme.headlineLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Học tập hiệu quả, kể cả khi ngoại tuyến.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Firebase Vault status card
              AppCard(
                onTap: () => Navigator.pushNamed(context, '/sync-vault'),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.cloud_done_outlined, color: AppColors.success),
                  title: Text('Firebase Cloud & Offline Vault'),
                  subtitle: Text('Sẵn sàng đồng bộ hai chiều (Firestore + Storage).'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Quick Actions / Navigation
              Text('Truy cập nhanh', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),

              AppCard(
                onTap: () => onNavigate(1),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.route_outlined, color: AppColors.primary),
                  title: Text('Lộ trình môn học'),
                  subtitle: Text('Kiểm tra môn tiên quyết và tiến độ kỳ Fall 2024.'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              AppCard(
                onTap: () => onNavigate(2),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.task_alt_outlined, color: AppColors.secondary),
                  title: Text('Kế hoạch & Việc cần làm'),
                  subtitle: Text('Quản lý deadline bài tập, sprint SWP391 và lab PRM323.'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              AppCard(
                onTap: () => onNavigate(3),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.notes_outlined, color: AppColors.warning),
                  title: Text('Notes Vault'),
                  subtitle: Text('Ghi chú môn học, lưu trữ tài liệu.'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              AppCard(
                onTap: () => Navigator.pushNamed(context, '/advisor'),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.auto_awesome_outlined, color: AppColors.primary),
                  title: Text('AI Academic Advisor'),
                  subtitle: Text('Mô phỏng chiến lược GPA và tư vấn kế hoạch học tập.'),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
