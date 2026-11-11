import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/task_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/advisor_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/notifications_viewmodel.dart';
import '../viewmodels/tasks_viewmodel.dart';
import '../widgets/app_components.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.onNavigate});

  final ValueChanged<int> onNavigate;

  void _showSignOutDialog(BuildContext context, AuthViewModel authVm) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AppConfirmDialog(
        title: 'Đăng xuất',
        message: 'Bạn có chắc chắn muốn đăng xuất khỏi StudyPilot?',
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
    final tasks = context.watch<TasksViewModel>();
    final unread = notificationsVm.unreadCount;
    final dueSoonTasks = tasks.dueSoonTasks;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'StudyPilot',
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
              Text(
                'Chào $displayName 👋',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Học tập hiệu quả, kể cả khi ngoại tuyến.',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Deadlines due within three days.
              if (dueSoonTasks.isNotEmpty) ...[
                _DueSoonCard(
                  tasks: dueSoonTasks,
                  onView: () => onNavigate(2),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],

              // Firebase Vault status card
              AppCard(
                onTap: () => Navigator.pushNamed(context, '/sync-vault'),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.cloud_done_outlined,
                    color: AppColors.success,
                  ),
                  title: Text('Firebase Cloud & Offline Vault'),
                  subtitle: Text(
                    'Đồng bộ Firestore và xuất tài liệu lên Storage.',
                  ),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Quick Actions / Navigation
              Text(
                'Truy cập nhanh',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.sm),

              AppCard(
                onTap: () =>
                    Navigator.pushNamed(context, '/academic-profile'),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.school_outlined,
                    color: AppColors.success,
                  ),
                  title: Text('Ngành học & Dữ liệu học tập'),
                  subtitle: Text(
                    'Xem ngành đang học và nhập bảng điểm để tính GPA.',
                  ),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              AppCard(
                onTap: () {
                  context
                      .read<AdvisorViewModel>()
                      .logStrategyOpened(source: 'home');
                  Navigator.pushNamed(context, '/strategy-sim');
                },
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.calculate_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text('Mô phỏng GPA'),
                  subtitle: Text(
                    'Thử kịch bản điểm — sandbox, không lưu và không sửa '
                    'bảng điểm thật.',
                  ),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              AppCard(
                onTap: () => onNavigate(1),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.route_outlined, color: AppColors.primary),
                  title: Text('Lộ trình môn học'),
                  subtitle: Text(
                    'Xem danh mục môn và kiểm tra môn tiên quyết.',
                  ),
                  trailing: Icon(Icons.chevron_right),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),

              AppCard(
                onTap: () => onNavigate(2),
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.task_alt_outlined,
                    color: AppColors.secondary,
                  ),
                  title: Text('Kế hoạch & Việc cần làm'),
                  subtitle: Text(
                    'Quản lý deadline bài tập, sprint SWP391 và lab PRM323.',
                  ),
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
                  leading: Icon(
                    Icons.auto_awesome_outlined,
                    color: AppColors.primary,
                  ),
                  title: Text('Cố vấn học tập'),
                  subtitle: Text('Hỏi đáp theo dữ liệu học tập của bạn.'),
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

class _DueSoonCard extends StatelessWidget {
  const _DueSoonCard({required this.tasks, required this.onView});

  final List<TaskModel> tasks;
  final VoidCallback onView;

  @override
  Widget build(BuildContext context) {
    final nearest = tasks.first;
    final count = tasks.length;
    return Card(
      color: AppColors.warningContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onView,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.schedule_outlined, color: AppColors.warning),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      count == 1
                          ? '1 việc đến hạn trong 3 ngày tới'
                          : '$count việc đến hạn trong 3 ngày tới',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: AppColors.warning,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'Gần nhất: ${nearest.title} · '
                      '${TasksViewModel.dueLabel(nearest)}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: AppFontSize.label,
                        color: AppColors.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(Icons.chevron_right, color: AppColors.warning),
            ],
          ),
        ),
      ),
    );
  }
}
