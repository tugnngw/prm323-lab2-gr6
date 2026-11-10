import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/academic_profile.dart';
import '../models/app_state.dart';
import '../models/course_model.dart';
import '../viewmodels/academic_viewmodel.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/roadmap_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_components.dart';
import '../widgets/app_states.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({super.key, required this.courseId});

  final String courseId;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  @override
  void initState() {
    super.initState();
    // course_view + prerequisite_check fire exactly once per screen open —
    // never from build().
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<RoadmapViewModel>();
      vm.logCourseOpened(widget.courseId);
      final course = vm.findCourseById(widget.courseId);
      if (course != null && course.prerequisites.isNotEmpty) {
        vm.checkEligibilityForCourse(course);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final roadmapVm = context.watch<RoadmapViewModel>();

    // Standard AsyncViewState branches (§4.2) — a detail screen that loads
    // from the catalog must not render a bare "not found" while the catalog
    // is still loading or has failed.
    switch (roadmapVm.state.state) {
      case ViewState.loading:
        return Scaffold(
          appBar: const CustomAppBar(title: 'Chi tiết môn học'),
          body: const AppLoadingState(message: 'Đang tải thông tin môn học...'),
        );
      case ViewState.error:
        return Scaffold(
          appBar: const CustomAppBar(title: 'Chi tiết môn học'),
          body: AppErrorState(
            message:
                roadmapVm.state.message ?? 'Không tải được dữ liệu môn học.',
            onRetry: roadmapVm.loadData,
          ),
        );
      case ViewState.empty:
      case ViewState.data:
        break;
    }

    final course = roadmapVm.findCourseById(widget.courseId);

    if (course == null) {
      return Scaffold(
        appBar: const CustomAppBar(title: 'Chi tiết môn học'),
        body: AppEmptyState(
          message: 'Không tìm thấy thông tin môn học này trong lộ trình.',
          actionLabel: 'Quay lại lộ trình',
          onAction: () => Navigator.pop(context),
        ),
      );
    }

    final isEligible = roadmapVm.isEligibleForCourse(course);
    final missingPrereqs = roadmapVm.getMissingPrerequisites(course);

    final overview = ListView(
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
                        fontSize: AppFontSize.label,
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
                course.lecturer.isEmpty
                    ? 'Chưa có thông tin giảng viên.'
                    : 'Giảng viên: ${course.lecturer}',
                style: Theme.of(context).textTheme.bodyMedium
                    ?.copyWith(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.md),

              // Attendance / Slot progress
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tiến độ slot học',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    course.totalSlots == 0
                        ? 'Chưa có dữ liệu slot'
                        : 'Slot ${course.completedSlots}/${course.totalSlots} (${(course.progress * 100).toInt()}%)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                child: LinearProgressIndicator(
                  value: course.progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.skeleton,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    course.progress >= 1.0
                        ? AppColors.success
                        : AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Prerequisite Check Section
        Text(
          'Điều kiện tiên quyết',
          style: Theme.of(context).textTheme.titleLarge,
        ),
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
                          isEligible
                              ? Icons.check_circle_outline
                              : Icons.warning_amber_rounded,
                          color: isEligible
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            isEligible
                                ? 'Bạn đã hoàn thành đủ các môn tiên quyết!'
                                : 'Cảnh báo: Bạn chưa đạt điều kiện tiên quyết!',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isEligible
                                  ? AppColors.success
                                  : AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: AppSpacing.lg),
                    ...course.prerequisites.map((req) {
                      final passed = roadmapVm.passedCourses.contains(req);
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xxs,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '• Môn $req',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              passed ? 'Đã đạt ✓' : 'Chưa đạt ✗',
                              style: TextStyle(
                                color: passed
                                    ? AppColors.success
                                    : AppColors.error,
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
                          style: const TextStyle(
                            fontSize: AppFontSize.label,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (course.overview.isNotEmpty) Text(course.overview),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Hỏi cố vấn về ${course.code}',
          icon: Icons.school_outlined,
          onPressed: () =>
              Navigator.pushNamed(context, '/advisor', arguments: course.code),
        ),
        const SizedBox(height: AppSpacing.md),
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
    );
    final academic = context.watch<AcademicViewModel>();
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: CustomAppBar(
          title: course.code,
          onBack: () => Navigator.pop(context),
        ),
        body: Column(
          children: [
            const TabBar(
              tabs: [
                Tab(text: 'Lịch slot'),
                Tab(text: 'Đánh giá'),
                Tab(text: 'Tổng quan'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _slots(context, course, academic),
                  _assessments(context, course),
                  overview,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _slots(
    BuildContext context,
    CourseModel course,
    AcademicViewModel academic,
  ) {
    // Stored codes are upper-cased; the catalog code may not be.
    final entries = academic.profile.timetable
        .where((e) => e.courseCode.toUpperCase() == course.code.toUpperCase())
        .toList();
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Lịch slot ${course.code}',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        if (course.slots.isEmpty)
          const AppEmptyState(
            message: 'Danh mục chưa có lịch slot chi tiết cho môn này.',
          )
        else
          ...course.slots.map(
            (slot) => AppCard(
              child: ListTile(
                leading: const Icon(Icons.calendar_today_outlined),
                title: Text('Slot ${slot.number}: ${slot.title}'),
                subtitle: Text(
                  [slot.date, slot.room].where((s) => s.isNotEmpty).join(' · '),
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Lịch cá nhân đã nhập',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        if (entries.isEmpty)
          const Text('Chưa có lịch cá nhân cho môn này.')
        else
          ...entries.map((e) {
            final detail = [
              if (e.room.isNotEmpty) 'Phòng ${e.room}',
              if (e.lecturer.isNotEmpty) e.lecturer,
            ].join(' · ');
            return ListTile(
              leading: const Icon(Icons.schedule),
              title: Text(
                '${ScheduleConflict.weekdayLabel(e.weekday)} · '
                '${e.startTime}–${e.endTime}',
              ),
              subtitle: detail.isEmpty ? null : Text(detail),
            );
          }),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/schedule'),
          icon: const Icon(Icons.edit_note),
          label: const Text('Quản lý thời khóa biểu'),
        ),
      ],
    );
  }

  Widget _assessments(BuildContext context, CourseModel course) => ListView(
    padding: const EdgeInsets.all(AppSpacing.md),
    children: [
      Text(
        'Bài tập & Điểm thành phần',
        style: Theme.of(context).textTheme.titleLarge,
      ),
      if (course.labs.isEmpty)
        const AppEmptyState(
          message: 'Danh mục chưa có đầu điểm/bài tập cho môn này.',
        )
      else
        ...course.labs.map(
          (lab) => AppCard(
            child: ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: Text(lab.title),
              subtitle: Text(
                [
                  if (lab.deadline.isNotEmpty) 'Hạn: ${lab.deadline}',
                  if (lab.weight != null) 'Trọng số: ${lab.weight}%',
                  'Nguồn: danh mục môn học',
                ].join(' · '),
              ),
            ),
          ),
        ),
      const Text(
        'Điểm cá nhân được quản lý trong bảng điểm của bạn; không tự suy đoán điểm từ danh mục.',
      ),
    ],
  );
}
