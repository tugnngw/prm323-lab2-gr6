import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/advisor_viewmodel.dart';
import '../viewmodels/academic_viewmodel.dart';
import '../models/academic_profile.dart';
import '../models/app_state.dart';
import '../widgets/app_states.dart';
import '../widgets/app_components.dart';

class StrategySimScreen extends StatelessWidget {
  const StrategySimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AcademicViewModel>();
    final advisor = context.read<AdvisorViewModel>();
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Mô phỏng Chiến lược & GPA',
        onBack: () => Navigator.pop(context),
      ),
      body: switch (vm.state.state) {
        ViewState.loading => const AppLoadingState(
          message: 'Đang tải dữ liệu học tập...',
        ),
        ViewState.error => AppErrorState(
          message: vm.state.message ?? 'Không tải được dữ liệu.',
          onRetry: vm.loadData,
        ),
        ViewState.empty => const AppEmptyState(
          message: 'Đăng nhập để lập kế hoạch.',
        ),
        ViewState.data => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const AppCard(
              child: Text(
                'Dữ liệu môn từ danh mục Firebase; bảng điểm/lịch học do bạn nhập. Các điểm dự kiến bên dưới chỉ là kịch bản, không ghi đè bảng điểm.',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, '/academic-profile'),
              icon: const Icon(Icons.edit_note),
              label: const Text('Nhập bảng điểm & lịch học'),
            ),
            if (vm.profile.transcript.isEmpty)
              const AppEmptyState(
                message: 'Chưa có bảng điểm thật. Nhập dữ liệu để tính GPA tích lũy và xem môn học lại.',
              ),
            if (vm.profile.timetable.isEmpty)
              const Text(
                'Chưa có thời khóa biểu: chưa thể kết luận kế hoạch không trùng lịch.',
              ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                _buildMetricTile(
                  context,
                  title: 'GPA bảng điểm hiện hành',
                  value:
                      vm.profile.cumulativeGpa?.toStringAsFixed(2) ?? 'Chưa có',
                  subtitle: 'Từ kết quả hiện hành do bạn nhập',
                  color: AppColors.primary,
                ),
                _buildMetricTile(
                  context,
                  title: 'GPA kỳ dự kiến',
                  value: vm.plannedGpa?.toStringAsFixed(2) ?? 'Chưa đặt',
                  subtitle: '${vm.plannedCredits} tín chỉ đã chọn',
                  color: AppColors.primary,
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Mục tiêu cá nhân: ${vm.profile.targetGpa.toStringAsFixed(2)}. Đây không phải kết luận về danh hiệu học tập.',
            ),
            if (vm.semesters.isNotEmpty)
              Wrap(
                spacing: AppSpacing.xs,
                children: [
                  for (final semester in vm.semesters)
                    ChoiceChip(
                      label: Text('Kỳ $semester'),
                      selected: vm.selectedSemester == semester,
                      onSelected: (_) => vm.selectSemester(semester),
                    ),
                ],
              ),
            const SizedBox(height: AppSpacing.sm),
            if (vm.semesterCourses.isEmpty)
              const AppEmptyState(message: 'Danh mục chưa có môn cho kỳ này.'),
            for (final course in vm.semesterCourses) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${course.code} · ${course.name} · ${course.credits} tín chỉ',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      vm.isRetake(course)
                          ? 'Học lại: bảng điểm đánh dấu chưa qua.'
                          : 'Môn trong danh mục.',
                    ),
                    if (vm.missingPrerequisites(course).isNotEmpty)
                      Text(
                        'Chưa xác nhận tiên quyết: ${vm.missingPrerequisites(course).join(', ')}',
                      ),
                    CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('Đưa ${course.code} vào kế hoạch'),
                      value: vm.plannedGrade(course.code) != null,
                      onChanged: (value) {
                        vm.setPlannedGrade(
                          course.code,
                          value == true ? 5 : null,
                        );
                        advisor.applyPreset(preset: 'course_selection');
                      },
                    ),
                    if (vm.plannedGrade(course.code) != null)
                      _buildScoreSlider(
                        context,
                        code: course.code,
                        name: 'Điểm dự kiến ${course.code}',
                        value: vm.plannedGrade(course.code)!,
                        onChanged: (value) =>
                            vm.setPlannedGrade(course.code, value),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],
            Text(
              'Đối chiếu thời khóa biểu',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (vm.profile.timetable.isEmpty)
              const Text('Chưa có lịch học để kiểm tra.')
            else if (vm.plannedCourses.isEmpty)
              const Text('Chọn môn để kiểm tra trùng slot.')
            else if (vm.conflicts.isEmpty)
              const Text(
                'Không thấy trùng slot trong lịch đã nhập. Những môn chưa có lịch vẫn cần kiểm tra.',
              )
            else
              ...vm.conflicts.map(
                (conflict) => Text(
                  'Trùng lịch: $conflict',
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            const SizedBox(height: AppSpacing.sm),
            for (final entry in vm.profile.timetable)
              Text(
                '${entry.courseCode}: ${ScheduleConflict.weekdayLabel(entry.weekday)}, ${entry.startTime}–${entry.endTime}',
              ),
            OutlinedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/schedule'),
              icon: const Icon(Icons.calendar_month_outlined),
              label: const Text('Mở thời khóa biểu'),
            ),
          ],
        ),
      },
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) => Container(
    padding: const EdgeInsets.all(AppSpacing.sm),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      border: Border.all(color: AppColors.outline),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: AppSpacing.hairline),
        Text(
          value,
          style: TextStyle(
            fontSize: AppFontSize.displayLarge,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: AppFontSize.caption,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    ),
  );

  Widget _buildScoreSlider(
    BuildContext context, {
    required String code,
    required String name,
    required double value,
    required ValueChanged<double> onChanged,
    bool isImportant = false,
  }) => AppCard(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: TextStyle(
                  fontWeight: isImportant ? FontWeight.w700 : FontWeight.w600,
                  color: isImportant ? AppColors.primary : AppColors.onSurface,
                ),
              ),
            ),
            Text(
              value.toStringAsFixed(1),
              style: TextStyle(
                fontSize: AppFontSize.displaySmall,
                fontWeight: FontWeight.w700,
                color: isImportant ? AppColors.primary : AppColors.onSurface,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: 0.0,
          max: 10.0,
          divisions: 100,
          label: value.toStringAsFixed(1),
          onChanged: onChanged,
        ),
      ],
    ),
  );
}
