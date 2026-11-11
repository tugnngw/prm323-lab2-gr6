import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/course_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/academic_viewmodel.dart';
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

  Future<void> _changeMajor(String major) async {
    final roadmapVm = context.read<RoadmapViewModel>();
    final academicVm = context.read<AcademicViewModel>();
    await roadmapVm.selectMajor(major);
    if (!mounted) return;
    if (roadmapVm.state.state == ViewState.data) {
      // Profile, advisor and GPA simulation read the academic view model, so
      // it must follow the same curriculum the roadmap just downloaded.
      await academicVm.loadData();
    }
  }

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
      appBar: CustomAppBar(
        title: 'Lộ trình học tập',
        actions: [
          IconButton(
            tooltip: 'Tải lại ngành & môn học',
            icon: const Icon(Icons.refresh),
            onPressed: roadmapVm.loadData,
          ),
          IconButton(
            tooltip: 'Hỏi cố vấn học tập',
            icon: const Icon(Icons.support_agent),
            onPressed: () => Navigator.pushNamed(context, '/advisor'),
          ),
        ],
      ),
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
                Row(
                  children: [
                    Expanded(
                      child: AppSearchBar(
                        controller: _searchController,
                        hint: 'Tìm theo mã môn (PRM323) hoặc tên...',
                        onChanged: (val) => roadmapVm.setSearchQuery(val),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    PopupMenuButton<String>(
                      tooltip: 'Chọn chuyên ngành',
                      initialValue: roadmapVm.selectedMajor,
                      onSelected: _changeMajor,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                          border: Border.all(color: AppColors.primary),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.school,
                              size: 16,
                              color: AppColors.onPrimaryContainer,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              roadmapVm.selectedMajor,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.onPrimaryContainer,
                              ),
                            ),
                            const Icon(
                              Icons.arrow_drop_down,
                              size: 18,
                              color: AppColors.onPrimaryContainer,
                            ),
                          ],
                        ),
                      ),
                      itemBuilder: (ctx) => roadmapVm.availableMajors.map((m) => PopupMenuItem(
                        value: m.code,
                        child: Text('${m.code} — ${m.name} (${m.totalSemesters} kỳ)'),
                      )).toList(),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    roadmapVm.selectedMajor.isEmpty
                        ? 'Chưa chọn ngành — bấm nút chuyên ngành ở trên.'
                        : '${roadmapVm.selectedMajorName} (${roadmapVm.selectedMajor})'
                              ' · ${roadmapVm.majorCourseCount} môn'
                              ' · Kỳ ${roadmapVm.selectedSemester}: '
                              '${roadmapVm.filteredCourses.length} môn',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: AppFontSize.label,
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
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
                      // Dynamic Semester Filter Chips (Semesters 1 through 9 for SE)
                      ...roadmapVm.availableSemesters.map((sem) => Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: ChoiceChip(
                          key: ValueKey('semester_chip_$sem'),
                          label: Text(
                            sem == roadmapVm.selectedSemester
                                ? 'Kỳ $sem (Đang xem)'
                                : 'Kỳ $sem',
                          ),
                          selected: roadmapVm.selectedSemester == sem,
                          onSelected: (selected) {
                            if (selected) roadmapVm.selectSemester(sem);
                          },
                        ),
                      )),
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
              ViewState.loading => const AppLoadingState(
                message: 'Đang tải danh sách môn học...',
              ),
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
              ViewState.data => _buildCourseList(
                context,
                roadmapVm,
                state.data ?? [],
              ),
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
      if (vm.filterPrerequisitesOnly) {
        return AppEmptyState(
          message:
              'Không có môn học nào có điều kiện tiên quyết trong Kỳ ${vm.selectedSemester}.',
          actionLabel: 'Tắt lọc tiên quyết',
          onAction: () => vm.togglePrerequisiteFilter(),
        );
      }
      if (vm.searchQuery.isNotEmpty) {
        return AppEmptyState(
          message: 'Không tìm thấy môn học khớp với "${vm.searchQuery}".',
          actionLabel: 'Xóa tìm kiếm',
          onAction: () {
            _searchController.clear();
            vm.setSearchQuery('');
          },
        );
      }
      return AppEmptyState(
        message:
            'Chưa có môn học cho Kỳ ${vm.selectedSemester} (Ngành ${vm.selectedMajor}).',
        actionLabel: 'Xem kỳ có môn học',
        onAction: () {
          final coursesForMajor = vm.allCourses.where(
            (c) =>
                vm.selectedMajor.isEmpty ||
                c.major.isEmpty ||
                c.major.toUpperCase() == vm.selectedMajor.toUpperCase(),
          );
          if (coursesForMajor.isNotEmpty) {
            vm.selectSemester(coursesForMajor.first.semester);
          } else if (vm.allCourses.isNotEmpty) {
            vm.selectSemester(vm.allCourses.first.semester);
          }
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
        final slotTotal = vm.slotCountOf(course);
        final doneSlots = vm.completedSlotCount(course);
        final slotProgress = vm.slotProgress(course);

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
                          fontSize: AppFontSize.label,
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
                    const Icon(
                      Icons.chevron_right,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  slotTotal > 0
                      ? 'Kỳ ${course.semester} · ${course.credits} tín chỉ · Slot $doneSlots/$slotTotal (${(slotProgress * 100).toInt()}%)'
                      : 'Kỳ ${course.semester} · ${course.credits} tín chỉ · Chưa có dữ liệu slot',
                  style: Theme.of(context).textTheme.bodyMedium
                      ?.copyWith(color: AppColors.onSurfaceVariant),
                ),
                if (course.electiveGroups.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xxs),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: course.electiveGroups
                        .map(
                          (group) => Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryContainer,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              'Tự chọn: $group',
                              style: const TextStyle(
                                fontSize: AppFontSize.label,
                                fontWeight: FontWeight.w600,
                                color: AppColors.secondary,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                  child: LinearProgressIndicator(
                    value: slotProgress,
                    minHeight: 6,
                    backgroundColor: AppColors.skeleton,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      slotProgress >= 1.0
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),

                // Prerequisite status chip
                if (course.prerequisites.isNotEmpty) ...[
                  Row(
                    children: [
                      Icon(
                        isEligible
                            ? Icons.check_circle_outline
                            : Icons.warning_amber_rounded,
                        size: 16,
                        color: isEligible
                            ? AppColors.success
                            : AppColors.warning,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          isEligible
                              ? 'Đủ điều kiện tiên quyết (${course.prerequisites.join(', ')})'
                              : 'Chưa đủ điều kiện: Cần học trước ${missing.join(', ')}',
                          style: TextStyle(
                            fontSize: AppFontSize.label,
                            color: isEligible
                                ? AppColors.success
                                : AppColors.warning,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (course.prerequisites.isEmpty &&
                    course.prerequisiteNote.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        size: 16,
                        color: AppColors.onSurfaceVariant,
                      ),
                      const SizedBox(width: AppSpacing.xxs),
                      Expanded(
                        child: Text(
                          'Điều kiện tiên quyết: xem ghi chú trong đề cương',
                          style: TextStyle(
                            fontSize: AppFontSize.label,
                            color: AppColors.onSurfaceVariant,
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
