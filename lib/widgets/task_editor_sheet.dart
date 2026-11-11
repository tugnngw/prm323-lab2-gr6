import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/tasks_viewmodel.dart';
import 'app_button.dart';
import 'app_text_field.dart';
import 'course_picker.dart';

/// Shared add/edit task sheet used by the Tasks tab and Course Detail.
/// The course is selected from the catalog (major → searchable list) instead of
/// asking the student to remember a course code.
Future<bool> showTaskEditorSheet(
  BuildContext context, {
  required TasksViewModel vm,
  TaskModel? existing,
  String? initialCourseCode,
  String? initialTitle,
  String? initialCourseName,
}) async {
  final result = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
    ),
    builder: (_) => _TaskEditorSheet(
      vm: vm,
      existing: existing,
      initialCourseCode: initialCourseCode,
      initialTitle: initialTitle ?? '',
      initialCourseName: initialCourseName ?? '',
    ),
  );
  return result ?? false;
}

class _TaskEditorSheet extends StatefulWidget {
  const _TaskEditorSheet({
    required this.vm,
    required this.existing,
    required this.initialCourseCode,
    required this.initialTitle,
    required this.initialCourseName,
  });

  final TasksViewModel vm;
  final TaskModel? existing;
  final String? initialCourseCode;
  final String initialTitle;
  final String initialCourseName;

  @override
  State<_TaskEditorSheet> createState() => _TaskEditorSheetState();
}

class _TaskEditorSheetState extends State<_TaskEditorSheet> {
  late final TextEditingController _title;
  late final TextEditingController _courseCode;
  late final TextEditingController _courseName;
  final _date = TextEditingController();
  DateTime? _due;
  late String _priority;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    _title = TextEditingController(
      text: existing?.title ?? widget.initialTitle,
    );
    _courseCode = TextEditingController(
      text: existing?.courseCode ?? widget.initialCourseCode ?? '',
    );
    _courseName = TextEditingController(text: widget.initialCourseName);
    _priority = existing?.priority ?? 'medium';
    _due = existing?.dueDateValue;
    if (_due != null) {
      _date.text = DateFormat('dd/MM/yyyy').format(_due!);
    }
  }

  @override
  void dispose() {
    _title.dispose();
    _courseCode.dispose();
    _courseName.dispose();
    _date.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _due ?? now.add(const Duration(days: 1)),
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 4),
      helpText: 'Chọn hạn chót',
    );
    if (picked == null || !mounted) return;
    setState(() {
      _due = picked;
      _date.text = DateFormat('dd/MM/yyyy').format(picked);
    });
  }

  Future<void> _pickCourse() async {
    final course = await showCoursePicker(
      context,
      initialCourseCode: _courseCode.text.trim().isEmpty
          ? null
          : _courseCode.text.trim(),
    );
    if (course == null || !mounted) return;
    setState(() {
      _courseCode.text = course.code;
      _courseName.text = course.name;
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      _message('Nhập nội dung công việc.');
      return;
    }
    final courseCode = _courseCode.text.trim();
    if (courseCode.isEmpty) {
      _message('Chọn môn học cho công việc này.');
      return;
    }
    setState(() => _saving = true);
    final ok = widget.existing == null
        ? await widget.vm.addTask(
            title: title,
            courseCode: courseCode,
            dueDate: _date.text.trim(),
            priority: _priority,
          )
        : await widget.vm.editTask(
            widget.existing!.id,
            title: title,
            courseCode: courseCode,
            dueDate: _date.text.trim(),
          );
    if (!mounted) return;
    setState(() => _saving = false);
    if (!ok) {
      _message(widget.vm.lastError ?? 'Không thể lưu việc cần làm.');
      return;
    }
    Navigator.pop(context, true);
  }

  void _message(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(text), backgroundColor: AppColors.error),
      );
  }

  @override
  Widget build(BuildContext context) {
    final hasCourse = _courseCode.text.trim().isNotEmpty;
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.lg,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.lg,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.existing == null
                  ? 'Thêm việc cần làm'
                  : 'Sửa việc cần làm',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _title,
              label: 'Nội dung công việc',
              hint: 'Ví dụ: Ôn Lab 3 PRM323...',
              autofocus: widget.existing == null,
            ),
            const SizedBox(height: AppSpacing.sm),
            InkWell(
              borderRadius: BorderRadius.circular(AppRadius.sm),
              onTap: _pickCourse,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Môn học',
                  suffixIcon: Icon(Icons.search),
                ),
                child: Text(
                  hasCourse
                      ? (_courseName.text.isEmpty
                            ? _courseCode.text
                            : '${_courseCode.text} · ${_courseName.text}')
                      : 'Chọn ngành rồi tìm môn',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: hasCourse
                        ? AppColors.onSurface
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _date,
              readOnly: true,
              onTap: _pickDueDate,
              decoration: InputDecoration(
                labelText: 'Hạn chót',
                hintText: 'Chọn ngày',
                suffixIcon: _date.text.isEmpty
                    ? const Icon(Icons.calendar_today_outlined)
                    : IconButton(
                        tooltip: 'Xoá hạn chót',
                        icon: const Icon(Icons.close),
                        onPressed: () => setState(() {
                          _due = null;
                          _date.clear();
                        }),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text('Độ ưu tiên', style: Theme.of(context).textTheme.bodyMedium),
                ChoiceChip(
                  label: const Text('Thấp'),
                  selected: _priority == 'low',
                  onSelected: (_) => setState(() => _priority = 'low'),
                ),
                ChoiceChip(
                  label: const Text('Trung bình'),
                  selected: _priority == 'medium',
                  onSelected: (_) => setState(() => _priority = 'medium'),
                ),
                ChoiceChip(
                  label: const Text('Cao'),
                  selected: _priority == 'high',
                  onSelected: (_) => setState(() => _priority = 'high'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: widget.existing == null
                  ? 'Lưu việc cần làm'
                  : 'Cập nhật việc cần làm',
              icon: Icons.check,
              isLoading: _saving,
              onPressed: _saving ? null : _save,
            ),
          ],
        ),
      ),
    );
  }
}
