import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/roadmap_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_components.dart';

class CourseDetailScreen extends StatelessWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  Widget build(BuildContext context) {
    final roadmapVm = context.watch<RoadmapViewModel>();
    final course = roadmapVm.findCourseById(courseId);

    if (course == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Chi tiết môn học'),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off_outlined, size: 48, color: AppColors.error),
              const SizedBox(height: AppSpacing.md),
              const Text('Không tìm thấy thông tin môn học.'),
              const SizedBox(height: AppSpacing.md),
              FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Quay lại'),
              ),
            ],
          ),
        ),
      );
    }

    final isEligible = roadmapVm.isEligibleForCourse(course);
    final missingPrereqs = roadmapVm.getMissingPrerequisites(course);

    return Scaffold(
      appBar: CustomAppBar(
        title: course.code,
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Course Header Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: AppSpacing.xxs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primaryContainer,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        'Kỳ ${course.semester} · ${course.major}',
                        style: const TextStyle(
                          color: AppColors.onPrimaryContainer,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Text(
                      '${course.credits} Tín chỉ',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  course.name,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Giảng viên: ${course.lecturer}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Attendance / Slot progress
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tiến độ slot học', style: Theme.of(context).textTheme.titleSmall),
                    Text(
                      'Slot ${course.completedSlots}/${course.totalSlots} (${(course.progress * 100).toInt()}%)',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  child: LinearProgressIndicator(
                    value: course.progress,
                    minHeight: 8,
                    backgroundColor: AppColors.skeleton,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      course.progress >= 1.0 ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Prerequisite Check Section
          Text('Điều kiện tiên quyết', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: course.prerequisites.isEmpty
                ? const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppColors.success),
                      SizedBox(width: AppSpacing.sm),
                      Text('Môn học này không yêu cầu môn tiên quyết.'),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isEligible ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                            color: isEligible ? AppColors.success : AppColors.warning,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              isEligible
                                  ? 'Bạn đã hoàn thành đủ các môn tiên quyết!'
                                  : 'Cảnh báo: Bạn chưa đạt điều kiện tiên quyết!',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: isEligible ? AppColors.success : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: AppSpacing.lg),
                      ...course.prerequisites.map((req) {
                        final passed = roadmapVm.passedCourses.contains(req);
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('• Môn $req', style: const TextStyle(fontWeight: FontWeight.w500)),
                              Text(
                                passed ? 'Đã đạt ✓' : 'Chưa đạt ✗',
                                style: TextStyle(
                                  color: passed ? AppColors.success : AppColors.error,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      if (!isEligible) ...[
                        const SizedBox(height: AppSpacing.sm),
                        Container(
                          padding: const EdgeInsets.all(AppSpacing.xs),
                          decoration: BoxDecoration(
                            color: AppColors.warningContainer,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            'Khuyến nghị: Cần hoàn thành môn ${missingPrereqs.join(', ')} trước khi làm đồ án/thi môn này.',
                            style: const TextStyle(fontSize: 12, color: AppColors.warning),
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Assignments / Labs Section
          Text('Bài tập & Điểm thành phần', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),

          if (course.labs.isEmpty)
            const AppCard(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.sm),
                child: Text('Chưa có danh sách bài tập cho môn này.'),
              ),
            )
          else
            ...course.labs.map((lab) {
              final isGraded = lab.status == 'graded';
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                child: AppCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      isGraded ? Icons.assignment_turned_in_outlined : Icons.pending_actions_outlined,
                      color: isGraded ? AppColors.success : AppColors.warning,
                    ),
                    title: Text(lab.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    subtitle: Text('Hạn nộp: ${lab.deadline}'),
                    trailing: isGraded
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.xs,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.successContainer,
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              '${lab.score}/10',
                              style: const TextStyle(
                                color: AppColors.success,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        : const Text('Đang làm', style: TextStyle(color: AppColors.warning)),
                  ),
                ),
              );
            }),

          const SizedBox(height: AppSpacing.lg),

          // Action buttons
          AppButton(
            label: 'Tạo ghi chú cho ${course.code}',
            icon: Icons.edit_note_outlined,
            isExpanded: true,
            onPressed: () => Navigator.pushNamed(
              context,
              '/note-editor',
              arguments: course.code,
            ),
          ),
        ],
      ),
    );
  }
}
