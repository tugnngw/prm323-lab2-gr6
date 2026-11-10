import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/academic_profile.dart';
import '../models/app_state.dart';
import '../models/schedule_rules.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/academic_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_components.dart';
import '../widgets/app_states.dart';
import 'session_editor_screen.dart';

/// Weekly timetable over the saved class sessions.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  /// Monday of the week on screen.
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    _weekStart = _mondayOf(DateTime.now());
  }

  static DateTime _mondayOf(DateTime date) {
    final day = DateTime(date.year, date.month, date.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  void _shiftWeek(int weeks) =>
      setState(() => _weekStart = _weekStart.add(Duration(days: 7 * weeks)));

  /// A session shows in this week unless its effective range excludes it.
  bool _activeInWeek(TimetableEntry entry) {
    final weekEnd = _weekStart.add(const Duration(days: 6));
    String date(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
    final start = entry.effectiveStart;
    final end = entry.effectiveEnd;
    if (start != null && start.isNotEmpty && start.compareTo(date(weekEnd)) > 0) {
      return false;
    }
    if (end != null && end.isNotEmpty && end.compareTo(date(_weekStart)) < 0) {
      return false;
    }
    return true;
  }

  Color _colorFor(String courseCode) {
    const palette = [
      AppColors.primary,
      AppColors.secondary,
      AppColors.success,
      AppColors.warning,
      Color(0xFF7C3AED),
      Color(0xFFDB2777),
      Color(0xFF0891B2),
      Color(0xFF65A30D),
    ];
    var hash = 0;
    for (final unit in courseCode.toUpperCase().codeUnits) {
      hash = (hash * 31 + unit) & 0x7fffffff;
    }
    return palette[hash % palette.length];
  }

  Future<void> _openEditor({TimetableEntry? entry, TimetableEntry? copyOf}) async {
    await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => SessionEditorScreen(entry: entry, copyOf: copyOf),
      ),
    );
  }

  Future<void> _delete(TimetableEntry entry) async {
    final vm = context.read<AcademicViewModel>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xóa buổi học'),
        content: Text(
          'Xóa ${entry.courseCode} '
          '(${ScheduleConflict.weekdayLabel(entry.weekday)}, '
          '${entry.startTime}–${entry.endTime})?\n'
          'Các buổi khác của môn này không bị ảnh hưởng.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    final ok = await vm.deleteSession(entry.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Đã xóa buổi học.' : vm.lastError ?? 'Không xóa được buổi học.',
        ),
      ),
    );
  }

  Future<void> _showActions(TimetableEntry entry) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(entry.courseCode),
              subtitle: Text(_sessionLine(entry)),
            ),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Sửa buổi học'),
              onTap: () => Navigator.pop(ctx, 'edit'),
            ),
            ListTile(
              leading: const Icon(Icons.copy_outlined),
              title: const Text('Nhân bản & sửa'),
              subtitle: const Text('Mở bản sao để chọn thứ/giờ khác'),
              onTap: () => Navigator.pop(ctx, 'duplicate'),
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: const Text(
                'Xóa buổi học',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () => Navigator.pop(ctx, 'delete'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'edit':
        await _openEditor(entry: entry);
      case 'duplicate':
        // Pre-fills a new (id-less) session so an identical copy is never
        // saved silently; the user picks the new day/slot before it persists.
        await _openEditor(copyOf: entry);
      case 'delete':
        await _delete(entry);
    }
  }

  static String _sessionLine(TimetableEntry entry) => [
    ScheduleConflict.weekdayLabel(entry.weekday),
    '${entry.startTime}–${entry.endTime}',
    if (entry.room.isNotEmpty) 'Phòng ${entry.room}',
    if (entry.campus.isNotEmpty) entry.campus,
    if (entry.lecturer.isNotEmpty) entry.lecturer,
    if (entry.section.isNotEmpty) entry.section,
  ].join(' · ');

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AcademicViewModel>();
    final weekSessions = vm.timetable.where(_activeInWeek).toList();
    final conflicts = ScheduleRules.allConflicts(weekSessions);

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Thời khóa biểu',
        onBack: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm buổi học',
            onPressed: () => _openEditor(),
          ),
        ],
      ),
      body: switch (vm.state.state) {
        ViewState.loading => const AppLoadingState(
          message: 'Đang tải thời khóa biểu...',
        ),
        ViewState.error => AppErrorState(
          message: vm.state.message ?? 'Không tải được thời khóa biểu.',
          onRetry: vm.loadData,
        ),
        ViewState.empty => const AppEmptyState(
          message: 'Đăng nhập để quản lý thời khóa biểu.',
        ),
        ViewState.data => vm.timetable.isEmpty
            ? AppEmptyState(
                message:
                    'Chưa có buổi học nào.\n'
                    'Thêm buổi học theo thời khóa biểu trên FAP của bạn.',
                actionLabel: 'Thêm buổi học',
                onAction: () => _openEditor(),
              )
            : _content(context, vm, weekSessions, conflicts),
      },
    );
  }

  Widget _content(
    BuildContext context,
    AcademicViewModel vm,
    List<TimetableEntry> weekSessions,
    List<ScheduleConflict> conflicts,
  ) {
    final weekLabel =
        '${_weekStart.day}/${_weekStart.month} – '
        '${_weekStart.add(const Duration(days: 6)).day}/'
        '${_weekStart.add(const Duration(days: 6)).month}';
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Tuần trước',
              onPressed: () => _shiftWeek(-1),
            ),
            Expanded(
              child: Column(
                children: [
                  Text(
                    'Tuần $weekLabel',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  TextButton(
                    onPressed: () => setState(
                      () => _weekStart = _mondayOf(DateTime.now()),
                    ),
                    child: const Text('Về tuần này'),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Tuần sau',
              onPressed: () => _shiftWeek(1),
            ),
          ],
        ),
        if (!vm.slotCatalog.verified)
          AppCard(
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  size: 20,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    'Giờ theo slot là giá trị mẫu, chưa xác minh là quy định '
                    'chính thức của FPTU. Đối chiếu với FAP trước khi dùng.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
        if (conflicts.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trùng lịch trong tuần',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.warning,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                for (final conflict in conflicts)
                  Text('• ${conflict.description}'),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        for (var day = 1; day <= 7; day++)
          ..._daySection(context, day, weekSessions, vm),
        const SizedBox(height: AppSpacing.md),
        AppOutlinedButton(
          label: 'Thêm buổi học',
          icon: Icons.add,
          isExpanded: true,
          onPressed: () => _openEditor(),
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  List<Widget> _daySection(
    BuildContext context,
    int day,
    List<TimetableEntry> weekSessions,
    AcademicViewModel vm,
  ) {
    final sessions = weekSessions.where((e) => e.weekday == day).toList()
      ..sort((a, b) => (a.startMinutes ?? 0).compareTo(b.startMinutes ?? 0));
    if (sessions.isEmpty) return const [];
    final date = _weekStart.add(Duration(days: day - 1));
    return [
      Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xs),
        child: Text(
          '${ScheduleConflict.weekdayLabel(day)} · ${date.day}/${date.month}',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
      for (final entry in sessions)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: AppCard(
            onTap: () => _showActions(entry),
            semanticLabel:
                '${entry.courseCode} ${_sessionLine(entry)}. Nhấn để sửa.',
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _colorFor(entry.courseCode),
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${entry.courseCode} · ${entry.courseName}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.hairline),
                      Text(_sessionLine(entry)),
                      if (entry.notes.isNotEmpty)
                        Text(
                          entry.notes,
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: AppFontSize.label,
                          ),
                        ),
                    ],
                  ),
                ),
                Text(
                  '${entry.startTime}\n${entry.endTime}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: AppFontSize.label),
                ),
              ],
            ),
          ),
        ),
    ];
  }
}
