import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/task_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/tasks_viewmodel.dart';
import '../widgets/app_components.dart';
import '../widgets/app_states.dart';
import '../widgets/app_toast.dart';
import '../widgets/task_editor_sheet.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  void _openEditor(
    BuildContext context,
    TasksViewModel vm, {
    TaskModel? existing,
  }) {
    showTaskEditorSheet(context, vm: vm, existing: existing);
  }

  @override
  Widget build(BuildContext context) {
    final tasksVm = context.watch<TasksViewModel>();
    final state = tasksVm.state;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Việc cần làm'),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Tất cả'),
                  selected: tasksVm.currentFilter == 'all',
                  onSelected: (selected) {
                    if (selected) tasksVm.setFilter('all');
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                ChoiceChip(
                  label: Text('Chưa xong (${tasksVm.pendingCount})'),
                  selected: tasksVm.currentFilter == 'pending',
                  onSelected: (selected) {
                    if (selected) tasksVm.setFilter('pending');
                  },
                ),
                const SizedBox(width: AppSpacing.xs),
                ChoiceChip(
                  label: Text('Đã xong (${tasksVm.completedCount})'),
                  selected: tasksVm.currentFilter == 'completed',
                  onSelected: (selected) {
                    if (selected) tasksVm.setFilter('completed');
                  },
                ),
              ],
            ),
          ),
          if (tasksVm.dueSoonCount > 0) _DueSoonBanner(vm: tasksVm),
          const Divider(height: 1, color: AppColors.outline),
          Expanded(
            child: switch (state.state) {
              ViewState.loading => const AppLoadingState(
                message: 'Đang tải việc cần làm...',
              ),
              ViewState.error => AppErrorState(
                message: state.message ?? 'Lỗi tải dữ liệu',
                onRetry: () => tasksVm.loadData(),
              ),
              ViewState.empty => AppEmptyState(
                message: 'Không có việc cần làm nào.',
                actionLabel: 'Thêm công việc',
                onAction: () => _openEditor(context, tasksVm),
              ),
              ViewState.data => _buildTaskList(
                context,
                tasksVm,
                tasksVm.filteredTasks,
              ),
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'tasks-add',
        onPressed: () => _openEditor(context, tasksVm),
        icon: const Icon(Icons.add),
        label: const Text('Thêm việc'),
      ),
    );
  }

  Future<void> _toggleWithUndo(
    BuildContext context,
    TasksViewModel vm,
    TaskModel task,
  ) async {
    final uid = vm.currentUserId;
    final wasCompleted = task.isCompleted;
    final ok = await vm.setTaskCompletion(task.id, !wasCompleted);
    if (!context.mounted || uid != vm.currentUserId) return;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    if (!ok) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(vm.lastError ?? 'Không thể cập nhật việc cần làm.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    showAppToast(
      context,
      message: wasCompleted
          ? 'Đã chuyển về chưa xong.'
          : 'Đã đánh dấu hoàn thành công việc.',
      duration: const Duration(seconds: 8),
      onAction: () async {
        if (uid != vm.currentUserId) return;
        final restored = await vm.setTaskCompletion(task.id, wasCompleted);
        if (!restored && context.mounted && uid == vm.currentUserId) {
          messenger.showSnackBar(
            SnackBar(
              content: Text(vm.lastError ?? 'Không thể hoàn tác.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );
  }

  Future<void> _deleteTaskWithFeedback(
    BuildContext context,
    TasksViewModel vm,
    String taskId,
  ) async {
    final ok = await vm.deleteTask(taskId);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(vm.lastError ?? 'Không thể xóa việc cần làm.'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Widget _buildTaskList(
    BuildContext context,
    TasksViewModel vm,
    List<TaskModel> tasks,
  ) {
    if (tasks.isEmpty) {
      return AppEmptyState(
        message: 'Không có việc cần làm nào trong mục này.',
        actionLabel: 'Xem tất cả',
        onAction: () => vm.setFilter('all'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        final overdue = TasksViewModel.isOverdue(task);
        final dueSoon = TasksViewModel.isDueSoon(task);
        final days = TasksViewModel.daysUntilDue(task);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Dismissible(
            key: Key(task.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              color: AppColors.errorContainer,
              child: const Icon(Icons.delete_outline, color: AppColors.error),
            ),
            onDismissed: (_) => _deleteTaskWithFeedback(context, vm, task.id),
            child: AppCard(
              onTap: () => _openEditor(context, vm, existing: task),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                decoration: task.isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: task.isCompleted
                                    ? AppColors.onSurfaceVariant
                                    : AppColors.onSurface,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _chip(
                                  text: task.courseCode,
                                  background: AppColors.primaryContainer,
                                  foreground: AppColors.onPrimaryContainer,
                                ),
                                if (task.dueDate.trim().isNotEmpty)
                                  _chip(
                                    text:
                                        TasksViewModel.isDueSoonOrOverdue(task)
                                        ? TasksViewModel.dueLabel(task)
                                        : 'Hạn: ${task.dueDate}',
                                    background: overdue
                                        ? AppColors.errorContainer
                                        : dueSoon
                                        ? AppColors.warningContainer
                                        : AppColors.skeleton,
                                    foreground: overdue
                                        ? AppColors.error
                                        : dueSoon
                                        ? AppColors.warning
                                        : AppColors.onSurfaceVariant,
                                    icon: overdue
                                        ? Icons.error_outline
                                        : dueSoon
                                        ? Icons.alarm
                                        : Icons.event_outlined,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(
                          Icons.more_vert,
                          size: 20,
                          color: AppColors.onSurfaceVariant,
                        ),
                        onSelected: (value) {
                          if (value == 'edit') {
                            _openEditor(context, vm, existing: task);
                          } else if (value == 'delete') {
                            _deleteTaskWithFeedback(context, vm, task.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'edit',
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.edit_outlined),
                              title: Text('Sửa'),
                            ),
                          ),
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              dense: true,
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(
                                Icons.delete_outline,
                                color: AppColors.error,
                              ),
                              title: Text(
                                'Xóa',
                                style: TextStyle(color: AppColors.error),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (days != null && !task.isCompleted && overdue)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Đã quá hạn ${-days} ngày — hãy xử lý hoặc đổi hạn.',
                        style: const TextStyle(
                          fontSize: AppFontSize.caption,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  const SizedBox(height: AppSpacing.xs),
                  Align(
                    alignment: Alignment.centerRight,
                    child: task.isCompleted
                        ? TextButton.icon(
                            onPressed: () => _toggleWithUndo(context, vm, task),
                            icon: const Icon(
                              Icons.undo,
                              size: 18,
                              color: AppColors.success,
                            ),
                            label: const Text(
                              'Đã xong — hoàn tác',
                              style: TextStyle(color: AppColors.success),
                            ),
                          )
                        : FilledButton.tonalIcon(
                            onPressed: () => _toggleWithUndo(context, vm, task),
                            icon: const Icon(Icons.task_alt, size: 18),
                            label: const Text('Đánh dấu đã xong'),
                          ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _chip({
    required String text,
    required Color background,
    required Color foreground,
    IconData? icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: foreground),
            const SizedBox(width: 3),
          ],
          Text(
            text,
            style: TextStyle(
              fontSize: AppFontSize.caption,
              fontWeight: FontWeight.w600,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _DueSoonBanner extends StatelessWidget {
  const _DueSoonBanner({required this.vm});

  final TasksViewModel vm;

  @override
  Widget build(BuildContext context) {
    final soonest = vm.dueSoonTasks.first;
    final count = vm.dueSoonCount;
    return Container(
      width: double.infinity,
      color: AppColors.warningContainer,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          const Icon(Icons.alarm, color: AppColors.warning, size: 20),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$count việc đến hạn trong 3 ngày tới',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: AppFontSize.label,
                    color: AppColors.warning,
                  ),
                ),
                Text(
                  'Gần nhất: ${soonest.title} · ${TasksViewModel.dueLabel(soonest)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: AppFontSize.caption),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => vm.setFilter('pending'),
            child: const Text('Xem'),
          ),
        ],
      ),
    );
  }
}
