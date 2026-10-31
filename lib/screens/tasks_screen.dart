import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/task_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/tasks_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_components.dart';
import '../widgets/app_states.dart';
import '../widgets/app_text_field.dart';

class TasksScreen extends StatelessWidget {
  const TasksScreen({super.key});

  /// Add-or-edit bottom sheet. [existing] non-null switches to edit mode and
  /// pre-fills the current values (D3: task edit UI). No hardcoded persona
  /// defaults — an empty add sheet starts blank.
  void _showTaskSheet(BuildContext context, TasksViewModel vm,
      {TaskModel? existing}) {
    final titleController = TextEditingController(text: existing?.title ?? '');
    final courseController =
        TextEditingController(text: existing?.courseCode ?? '');
    final dateController = TextEditingController(text: existing?.dueDate ?? '');
    var priority = existing?.priority ?? 'medium';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
            left: AppSpacing.md,
            right: AppSpacing.md,
            top: AppSpacing.lg,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(existing == null ? 'Thêm việc cần làm mới' : 'Sửa việc cần làm',
                  style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: titleController,
                label: 'Nội dung công việc',
                hint: 'Ví dụ: Làm bài tập Lab 3...',
                autofocus: existing == null,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: courseController,
                      label: 'Mã môn',
                      hint: 'PRM323',
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      controller: dateController,
                      label: 'Hạn chót',
                      hint: 'dd/MM/yyyy',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Text('Độ ưu tiên',
                      style: Theme.of(ctx).textTheme.bodyMedium),
                  const SizedBox(width: AppSpacing.sm),
                  ChoiceChip(
                    label: const Text('Thấp'),
                    selected: priority == 'low',
                    onSelected: (_) =>
                        setSheetState(() => priority = 'low'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ChoiceChip(
                    label: const Text('Trung bình'),
                    selected: priority == 'medium',
                    onSelected: (_) =>
                        setSheetState(() => priority = 'medium'),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ChoiceChip(
                    label: const Text('Cao'),
                    selected: priority == 'high',
                    onSelected: (_) =>
                        setSheetState(() => priority = 'high'),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: existing == null
                    ? 'Lưu việc cần làm'
                    : 'Cập nhật việc cần làm',
                icon: Icons.check,
                onPressed: () async {
                  final title = titleController.text.trim();
                  if (title.isEmpty) return;
                  final ok = existing == null
                      ? await vm.addTask(
                          title: title,
                          courseCode: courseController.text.trim(),
                          dueDate: dateController.text.trim(),
                          priority: priority,
                        )
                      : await vm.editTask(
                          existing.id,
                          title: title,
                          courseCode: courseController.text.trim(),
                          dueDate: dateController.text.trim(),
                        );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (!ok && ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(
                            vm.lastError ?? 'Không thể lưu việc cần làm.'),
                        backgroundColor: AppColors.error,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasksVm = context.watch<TasksViewModel>();
    final state = tasksVm.state;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Việc cần làm'),
      body: Column(
        children: [
          // Filter Chips Row
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
          const Divider(height: 1, color: AppColors.outline),

          // Task List Body
          Expanded(
            child: switch (state.state) {
              ViewState.loading =>
                  const AppLoadingState(message: 'Đang tải việc cần làm...'),
              ViewState.error => AppErrorState(
                  message: state.message ?? 'Lỗi tải dữ liệu',
                  onRetry: () => tasksVm.loadData(),
                ),
              ViewState.empty => AppEmptyState(
                  message: 'Không có việc cần làm nào.',
                  actionLabel: 'Thêm công việc',
                  onAction: () => _showTaskSheet(context, tasksVm),
                ),
              ViewState.data =>
                  _buildTaskList(context, tasksVm, tasksVm.filteredTasks),
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskSheet(context, tasksVm),
        icon: const Icon(Icons.add),
        label: const Text('Thêm việc'),
      ),
    );
  }

  /// Runs the delete and, if the remote write failed, reports it. The
  /// ViewModel restores the item so the list never shows a silent success.
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
        final isHigh = task.priority == 'high';

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: Dismissible(
            key: Key(task.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              color: AppColors.errorContainer,
              child:
                  const Icon(Icons.delete_outline, color: AppColors.error),
            ),
            onDismissed: (_) =>
                _deleteTaskWithFeedback(context, vm, task.id),
            child: AppCard(
              onTap: () => vm.toggleTask(task.id),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Checkbox(
                  value: task.isCompleted,
                  onChanged: (_) => vm.toggleTask(task.id),
                ),
                title: Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    decoration: task.isCompleted
                        ? TextDecoration.lineThrough
                        : null,
                    color: task.isCompleted
                        ? AppColors.onSurfaceVariant
                        : AppColors.onSurface,
                  ),
                ),
                subtitle: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        task.courseCode,
                        style: const TextStyle(
                          color: AppColors.onPrimaryContainer,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(
                      'Hạn: ${task.dueDate}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isHigh && !task.isCompleted
                            ? AppColors.error
                            : AppColors.onSurfaceVariant,
                        fontWeight: isHigh && !task.isCompleted
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                trailing: PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert,
                      size: 20, color: AppColors.onSurfaceVariant),
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showTaskSheet(context, vm, existing: task);
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
                        leading: Icon(Icons.delete_outline,
                            color: AppColors.error),
                        title:
                            Text('Xóa', style: TextStyle(color: AppColors.error)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
