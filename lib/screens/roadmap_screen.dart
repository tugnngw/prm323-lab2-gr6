import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/course_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/roadmap_viewmodel.dart';
import '../widgets/app_components.dart';
import '../widgets/app_states.dart';
import '../widgets/app_text_field.dart';

class RoadmapScreen extends StatefulWidget {
  const RoadmapScreen({super.key});

  @override
  State<RoadmapScreen> createState() => _RoadmapScreenState();
}

class _RoadmapScreenState extends State<RoadmapScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final roadmapVm = context.watch<RoadmapViewModel>();
    final state = roadmapVm.state;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Lộ trình học tập'),
      body: Column(
        children: [
          // Search & Filter Header
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: Column(
              children: [
                AppSearchBar(
                  controller: _searchController,
                  hint: 'Tìm theo mã môn (PRM323) hoặc tên...',
                  onChanged: (val) => roadmapVm.setSearchQuery(val),
                ),
                const SizedBox(height: AppSpacing.xs),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      // Filter Prerequisite Chip
                      FilterChip(
                        label: const Text('Kiểm tra môn tiên quyết'),
                        avatar: Icon(
                          roadmapVm.filterPrerequisitesOnly
                              ? Icons.filter_alt
                              : Icons.filter_alt_outlined,
                          size: 16,
                        ),
                        selected: roadmapVm.filterPrerequisitesOnly,
                        onSelected: (_) => roadmapVm.togglePrerequisiteFilter(),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      // Semester Filter Chips
                      ChoiceChip(
                        label: const Text('Kỳ 4'),
                        selected: roadmapVm.selectedSemester == 4,
                        onSelected: (selected) {
                          if (selected) roadmapVm.selectSemester(4);
                        },
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      ChoiceChip(
                        label: const Text('Kỳ 5 (Hiện tại)'),
                        selected: roadmapVm.selectedSemester == 5,
                        onSelected: (selected) {
                          if (selected) roadmapVm.selectSemester(5);
                        },
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      ChoiceChip(
                        label: const Text('Kỳ 6'),
                        selected: roadmapVm.selectedSemester == 6,
                        onSelected: (selected) {
                          if (selected) roadmapVm.selectSemester(6);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.outline),

          // Body Content based on ViewState
          Expanded(
            child: switch (state.state) {
              ViewState.loading => const AppLoadingState(message: 'Đang tải danh sách môn học...'),
              ViewState.error => AppErrorState(
                  message: state.message ?? 'Đã có lỗi xảy ra',
                  onRetry: () => roadmapVm.loadData(),
                ),
              ViewState.empty => AppEmptyState(
                  message: 'Không tìm thấy môn học nào phù hợp với bộ lọc.',
                  actionLabel: 'Xóa bộ lọc',
                  onAction: () {
                    _searchController.clear();
                    roadmapVm.setSearchQuery('');
                    if (roadmapVm.filterPrerequisitesOnly) {
                      roadmapVm.togglePrerequisiteFilter();
                    }
                  },
                ),
              ViewState.data => _buildCourseList(context, roadmapVm, state.data ?? []),
            },
          ),
        ],
      ),
    );
  }

  Widget _buildCourseList(
    BuildContext context,
    RoadmapViewModel vm,
    List<CourseModel> courses,
  ) {
    if (courses.isEmpty) {
      return AppEmptyState(
        message: 'Không tìm thấy môn học nào phù hợp.',
        actionLabel: 'Xem tất cả',
        onAction: () {
          _searchController.clear();
          vm.setSearchQuery('');
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        final course = courses[index];
        final isEligible = vm.isEligibleForCourse(course);
        final missing = vm.getMissingPrerequisites(course);

        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: AppCard(
            onTap: () => Navigator.pushNamed(
              context,
              '/course-detail',
              arguments: course.id,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
                        course.code,
                        style: const TextStyle(
                          color: AppColors.onPrimaryContainer,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        course.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  '${course.credits} tín chỉ · Slot ${course.completedSlots}/${course.totalSlots} (${(course.progress * 100).toInt()}%)',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  child: LinearProgressIndicator(
                    value: course.progress,
                    minHeight: 6,
                    backgroundColor: AppColors.skeleton,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      course.progress >= 1.0 ? AppColors.success : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Prerequisite status chip
                if (course.prerequisites.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        isEligible ? Icons.check_circle_outline : Icons.warning_amber_rounded,
                        size: 16,
                        color: isEligible ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          isEligible
                              ? 'Đủ điều kiện tiên quyết (${course.prerequisites.join(', ')})'
                              : 'Chưa đủ điều kiện: Cần học trước ${missing.join(', ')}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isEligible ? AppColors.success : AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
