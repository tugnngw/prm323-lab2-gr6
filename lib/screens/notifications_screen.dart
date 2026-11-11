import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/announcement_model.dart';
import '../models/app_state.dart';
import '../models/notification_model.dart';
import '../models/task_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/notifications_viewmodel.dart';
import '../viewmodels/tasks_viewmodel.dart';
import '../widgets/app_components.dart';
import '../widgets/app_states.dart';

/// Notification Center (Lab 3 T12) — merges school announcements, personal
/// pushes from `users/{uid}/notifications`, and the student's own upcoming
/// deadlines. Unread state is per-student; tapping marks items read.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key, this.showAnnouncements = false});

  final bool showAnnouncements;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationsViewModel>();
    final tasksVm = context.watch<TasksViewModel>();
    final state = vm.state;

    final deadlines = tasksVm.allTasks
        .where(TasksViewModel.isDueSoonOrOverdue)
        .toList()
      ..sort(TasksViewModel.compareByDeadline);
    final announcements = vm.announcements;
    final personal = state.data ?? const <NotificationModel>[];
    final hasContent =
        deadlines.isNotEmpty || announcements.isNotEmpty || personal.isNotEmpty;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Trung tâm Thông báo',
        onBack: () => Navigator.pop(context),
        actions: [
          if (showAnnouncements)
            IconButton(
              icon: const Icon(Icons.fact_check_outlined),
              tooltip: 'Bí kíp của tôi',
              onPressed: () => Navigator.pushNamed(context, '/my-tips'),
            ),
          if (showAnnouncements)
            IconButton(
              icon: const Icon(Icons.campaign_outlined),
              tooltip: 'Thông báo hệ thống',
              onPressed: () => Navigator.pushNamed(context, '/announcements'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: () {
              vm.loadData();
              tasksVm.loadData();
            },
          ),
        ],
      ),
      body: switch (state.state) {
        ViewState.loading => const AppLoadingState(
          message: 'Đang tải thông báo...',
        ),
        ViewState.error => AppErrorState(
          message: state.message ?? 'Không tải được thông báo.',
          onRetry: vm.loadData,
        ),
        _ when vm.currentUserId == null => const AppEmptyState(
          message: 'Bạn chưa đăng nhập — không có thông báo.',
        ),
        _ when !hasContent => const AppEmptyState(
          message:
              'Chưa có thông báo nào.\nDeadline trong 3 ngày tới, thông báo '
              'hệ thống và push sẽ hiển thị tại đây.',
        ),
        _ => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (deadlines.isNotEmpty) ...[
              const _SectionHeader(
                icon: Icons.event_busy_outlined,
                title: 'Deadline sắp tới',
                color: AppColors.warning,
              ),
              for (final task in deadlines) ...[
                _DeadlineCard(task: task),
                const SizedBox(height: AppSpacing.xs),
              ],
              const SizedBox(height: AppSpacing.sm),
            ],
            if (announcements.isNotEmpty) ...[
              const _SectionHeader(
                icon: Icons.campaign_outlined,
                title: 'Thông báo hệ thống',
                color: AppColors.primary,
              ),
              for (final item in announcements) ...[
                _AnnouncementCard(vm: vm, announcement: item),
                const SizedBox(height: AppSpacing.xs),
              ],
              const SizedBox(height: AppSpacing.sm),
            ],
            if (personal.isNotEmpty) ...[
              const _SectionHeader(
                icon: Icons.notifications_none_rounded,
                title: 'Thông báo của bạn',
                color: AppColors.secondary,
              ),
              _NotificationList(vm: vm, items: personal),
            ],
          ],
        ),
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.color,
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _DeadlineCard extends StatelessWidget {
  const _DeadlineCard({required this.task});

  final TaskModel task;

  @override
  Widget build(BuildContext context) {
    final overdue = TasksViewModel.isOverdue(task);
    final color = overdue ? AppColors.error : AppColors.warning;
    final container = overdue
        ? AppColors.errorContainer
        : AppColors.warningContainer;
    return AppCard(
      onTap: task.courseCode.trim().isEmpty
          ? null
          : () => Navigator.pushNamed(
              context,
              '/course-detail',
              arguments: task.courseCode,
            ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: container,
          child: Icon(Icons.event_busy_outlined, color: color, size: 20),
        ),
        title: Text(
          task.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          task.courseCode.trim().isEmpty
              ? 'Việc cần làm'
              : 'Môn ${task.courseCode}',
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.xxs,
          ),
          decoration: BoxDecoration(
            color: container,
            borderRadius: BorderRadius.circular(AppRadius.xs),
          ),
          child: Text(
            TasksViewModel.dueLabel(task),
            style: TextStyle(
              fontSize: AppFontSize.label,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  const _AnnouncementCard({required this.vm, required this.announcement});

  final NotificationsViewModel vm;
  final AnnouncementModel announcement;

  @override
  Widget build(BuildContext context) {
    final read = vm.isAnnouncementRead(announcement.id);
    return Opacity(
      opacity: read ? 0.65 : 1,
      child: AppCard(
        onTap: () {
          vm.markAnnouncementRead(announcement.id);
          Navigator.pushNamed(context, '/announcements');
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.campaign_outlined,
                  size: 18,
                  color: AppColors.primary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    announcement.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: read ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                ),
                if (!read)
                  const CircleAvatar(
                    radius: 4,
                    backgroundColor: AppColors.primary,
                  ),
              ],
            ),
            if (announcement.body.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                announcement.body,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: AppSpacing.xxs),
            Text(
              announcement.publishedLabel.isEmpty
                  ? 'Gần đây'
                  : announcement.publishedLabel,
              style: const TextStyle(
                fontSize: AppFontSize.caption,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationList extends StatelessWidget {
  const _NotificationList({required this.vm, required this.items});

  final NotificationsViewModel vm;
  final List<NotificationModel> items;

  IconData _iconFor(String type) => switch (type) {
    'task_due' => Icons.event_available_outlined,
    'sync' => Icons.cloud_sync_outlined,
    'advisor' => Icons.auto_awesome_outlined,
    _ => Icons.notifications_none_rounded,
  };

  @override
  Widget build(BuildContext context) => Column(
    children: [
      for (final item in items) ...[
        Opacity(
          opacity: item.isUnread ? 1 : 0.6,
          child: AppCard(
            onTap: () {
              vm.markAsRead(item.id);
              final route = item.destinationRoute;
              if (route != null && route.isNotEmpty) {
                Navigator.pushNamed(
                  context,
                  route,
                  arguments: item.destinationArgument,
                );
              }
            },
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: item.isUnread
                    ? AppColors.primaryContainer
                    : AppColors.skeleton,
                child: Icon(
                  _iconFor(item.type),
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              title: Text(
                item.title.isEmpty ? '(Không tiêu đề)' : item.title,
                style: TextStyle(
                  fontWeight: item.isUnread
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.body.isNotEmpty) Text(item.body),
                  const SizedBox(height: AppSpacing.hairline),
                  Text(
                    item.receivedAt.isEmpty ? 'Gần đây' : item.receivedAt,
                    style: const TextStyle(
                      fontSize: AppFontSize.caption,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              trailing: item.isUnread
                  ? const CircleAvatar(
                      radius: 5,
                      backgroundColor: AppColors.primary,
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
      ],
    ],
  );
}
