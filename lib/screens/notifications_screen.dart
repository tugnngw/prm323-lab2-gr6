import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/notification_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/notifications_viewmodel.dart';
import '../widgets/app_components.dart';
import '../widgets/app_states.dart';

/// Notification Center (Lab 3 T12) — reads `users/{uid}/notifications`,
/// shows unread state, marks entries read on tap. Data comes from Firestore
/// only; an account with no pushes sees the honest empty state.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<NotificationsViewModel>();
    final state = vm.state;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Trung tâm Thông báo',
        onBack: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Tải lại',
            onPressed: vm.loadData,
          ),
        ],
      ),
      body: switch (state.state) {
        ViewState.loading => const AppLoadingState(message: 'Đang tải thông báo...'),
        ViewState.error => AppErrorState(
            message: state.message ?? 'Không tải được thông báo.',
            onRetry: vm.loadData,
          ),
        ViewState.empty => vm.currentUserId == null
            ? const AppEmptyState(message: 'Bạn chưa đăng nhập — không có thông báo.')
            : const AppEmptyState(
                message:
                    'Chưa có thông báo nào.\nĐẩy thử một push từ Firebase Console '
                    'để mục này hiển thị dữ liệu thật.',
              ),
        ViewState.data => _NotificationList(vm: vm, items: state.data ?? []),
      },
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
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        itemCount: items.length,
        separatorBuilder: (_, i) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, index) {
          final item = items[index];
          return Opacity(
            opacity: item.isUnread ? 1 : 0.6,
            child: AppCard(
              onTap: () => vm.markAsRead(item.id),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: item.isUnread
                      ? AppColors.primaryContainer
                      : AppColors.skeleton,
                  child: Icon(_iconFor(item.type),
                      color: AppColors.primary, size: 20),
                ),
                title: Text(
                  item.title.isEmpty ? '(Không tiêu đề)' : item.title,
                  style: TextStyle(
                    fontWeight:
                        item.isUnread ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.body.isNotEmpty) Text(item.body),
                    const SizedBox(height: 2),
                    Text(
                      item.receivedAt.isEmpty ? 'Gần đây' : item.receivedAt,
                      style: const TextStyle(
                          fontSize: 11, color: AppColors.onSurfaceVariant),
                    ),
                  ],
                ),
                trailing: item.isUnread
                    ? const CircleAvatar(
                        radius: 5, backgroundColor: AppColors.primary)
                    : null,
              ),
            ),
          );
        },
      );
}
