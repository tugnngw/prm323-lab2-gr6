import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:study_pilot_core/study_pilot_core.dart';

import '../models/app_state.dart';
import '../models/course_model.dart';
import '../models/note_draft.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/academic_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/roadmap_viewmodel.dart';
import '../viewmodels/tasks_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_components.dart';
import '../widgets/app_states.dart';
import '../widgets/app_toast.dart';
import '../widgets/community_tips_section.dart';
import '../widgets/task_editor_sheet.dart';

class CourseDetailScreen extends StatefulWidget {
  const CourseDetailScreen({
    super.key,
    required this.courseId,
    this.store,
    this.currentUid,
    this.initialTab = 0,
  });

  final String courseId;
  final FinalFirestore? store;
  final String? currentUid;

  /// 0 slots · 1 assessments · 2 overview · 3 community tips.
  final int initialTab;

  @override
  State<CourseDetailScreen> createState() => _CourseDetailScreenState();
}

class _CourseDetailScreenState extends State<CourseDetailScreen> {
  final Map<String, TextEditingController> _scoreControllers = {};
  final Set<String> _seededScoreIds = {};
  bool _applyComponentTotal = true;
  bool _savingComponents = false;

  @override
  void dispose() {
    for (final controller in _scoreControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

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

    // Standard AsyncViewState branches (§4.2)
    switch (roadmapVm.state.state) {
      case ViewState.loading:
        return Scaffold(
          appBar: CustomAppBar(
            title: 'Chi tiết môn học',
            onBack: () => Navigator.of(context).pop(),
          ),
          body: AppLoadingState(message: 'Đang tải thông tin môn học...'),
        );
      case ViewState.error:
        return Scaffold(
          appBar: CustomAppBar(
            title: 'Chi tiết môn học',
            onBack: () => Navigator.of(context).pop(),
          ),
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
        appBar: CustomAppBar(
          title: 'Chi tiết môn học',
          onBack: () => Navigator.of(context).pop(),
        ),
        body: AppEmptyState(
          message: 'Không tìm thấy thông tin môn học này trong lộ trình.',
          actionLabel: 'Quay lại lộ trình',
          onAction: () => Navigator.pop(context),
        ),
      );
    }

    final isEligible = roadmapVm.isEligibleForCourse(course);
    final missingPrereqs = roadmapVm.getMissingPrerequisites(course);
    final academic = context.watch<AcademicViewModel>();
    final slotTotal = roadmapVm.slotCountOf(course);
    final completedSlots = roadmapVm.completedSlotCount(course);
    final slotProgress = roadmapVm.slotProgress(course);
    final personalLecturer = roadmapVm.lecturerFor(course);

    final effectiveStore =
        widget.store ?? (Firebase.apps.isEmpty ? null : context.read<FinalFirestore?>());

    String? activeUid = widget.currentUid;
    if (activeUid == null) {
      try {
        activeUid = context.read<AuthViewModel>().currentUserId;
      } catch (_) {
        activeUid = null;
      }
    }

    final syllabusInfo = <List<String>>[
      ['Trình độ', course.degreeLevel],
      ['Phân bổ thời gian', course.timeAllocation],
      ['Thang điểm', course.scoringScale],
      ['Điểm trung bình tối thiểu', course.minAvgMarkToPass],
      ['Phương pháp dạy - học', course.learningTeachingMethod],
      ['Nhiệm vụ sinh viên', course.studentTasks],
      ['Công cụ học tập', course.tools],
      ['Ghi chú', course.note],
      ['Quyết định', course.decisionNo],
      ['Ngày phê duyệt', course.approvedDate],
    ].where((row) => row[1].isNotEmpty).toList();

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
              if (course.electiveGroups.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: course.electiveGroups
                      .map(
                        (group) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.secondaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
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
              Row(
                children: [
                  const Icon(
                    Icons.person_outline,
                    size: 18,
                    color: AppColors.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      personalLecturer.isEmpty
                          ? 'Chưa có thông tin giảng viên — bạn có thể tự ghi lại.'
                          : 'Giảng viên: $personalLecturer',
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(color: AppColors.onSurfaceVariant),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () => _editLecturer(
                      context,
                      roadmapVm,
                      course,
                      personalLecturer,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: Text(
                      personalLecturer.isEmpty ? 'Nhập' : 'Sửa',
                      style: const TextStyle(fontSize: AppFontSize.label),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Attendance / Slot progress (per student)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tiến độ slot học',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    slotTotal == 0
                        ? 'Chưa có dữ liệu slot'
                        : 'Slot $completedSlots/$slotTotal (${(slotProgress * 100).toInt()}%)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                child: LinearProgressIndicator(
                  value: slotProgress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.skeleton,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    slotProgress >= 1.0 ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
              if (roadmapVm.isCourseCompleted(course)) ...[
                const SizedBox(height: AppSpacing.xs),
                const Row(
                  children: [
                    Icon(Icons.verified, size: 16, color: AppColors.success),
                    SizedBox(width: 4),
                    Text(
                      'Bạn đã đánh dấu hoàn thành môn này.',
                      style: TextStyle(
                        fontSize: AppFontSize.label,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
              ],
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
          child: course.prerequisites.isEmpty && course.prerequisiteNote.isEmpty
              ? const Row(
                  children: [
                    Icon(Icons.check_circle_outline, color: AppColors.success),
                    SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text('Môn học này không yêu cầu môn tiên quyết.'),
                    ),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (course.prerequisites.isEmpty)
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.warning),
                          SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Điều kiện tiên quyết được ghi dạng văn bản trong đề cương, không phải mã môn cố định.',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      )
                    else ...[
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
                      const Text(
                        'Điều kiện chỉ xét điểm môn tiên quyết (đạt khi từ 5.0). '
                        'Không cần đánh dấu hoàn thành slot học của môn đó.',
                        style: TextStyle(
                          fontSize: AppFontSize.label,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ...course.prerequisites.map((req) {
                        final passed = roadmapVm.passedCourses.contains(
                          req.trim().toUpperCase(),
                        );
                        final entry = academic.profile.transcript
                            .where(
                              (e) =>
                                  e.courseCode.trim().toUpperCase() ==
                                  req.trim().toUpperCase(),
                            )
                            .firstOrNull;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: AppSpacing.xxs,
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '• Môn $req'
                                  '${entry == null ? '' : ' · ${entry.grade.toStringAsFixed(1)} điểm'}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
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
                              const SizedBox(width: AppSpacing.xs),
                              TextButton(
                                onPressed: () => _openQuickGradeDialog(
                                  context,
                                  academic,
                                  roadmapVm,
                                  req,
                                  entry?.grade,
                                ),
                                child: Text(
                                  entry == null ? 'Nhập điểm' : 'Sửa điểm',
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
                    if (course.prerequisiteNote.isNotEmpty) ...[
                      if (course.prerequisites.isNotEmpty)
                        const Divider(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: AppColors.skeleton,
                          borderRadius: BorderRadius.circular(AppRadius.xs),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Ghi chú tiên quyết từ đề cương',
                              style: TextStyle(
                                fontSize: AppFontSize.label,
                                fontWeight: FontWeight.w600,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              course.prerequisiteNote,
                              style: const TextStyle(
                                fontSize: AppFontSize.label,
                                color: AppColors.onSurface,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (syllabusInfo.isNotEmpty) ...[
          Text(
            'Thông tin học phần',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: syllabusInfo
                  .map((row) => _infoRow(context, row[0], row[1]))
                  .toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Learning Outcomes (LOs) Section
        Text(
          'Chuẩn đầu ra môn học (Learning Outcomes)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: course.learningOutcomes.isEmpty
                ? const [
                    _SyllabusEmpty(
                      message: 'Chưa cập nhật chuẩn đầu ra từ đề cương FLM.',
                    ),
                  ]
                : course.learningOutcomes.map((lo) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xxs,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primaryContainer,
                              borderRadius: BorderRadius.circular(AppRadius.xs),
                            ),
                            child: Text(
                              lo.name,
                              style: const TextStyle(
                                fontSize: AppFontSize.label,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: Text(
                              lo.description,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Textbooks and Materials Section
        Text(
          'Giáo trình & Tài liệu học tập',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: course.courseMaterials.isEmpty
                ? const [
                    _SyllabusEmpty(
                      message: 'Chưa cập nhật giáo trình từ đề cương FLM.',
                    ),
                  ]
                : course.courseMaterials.map((mat) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        vertical: AppSpacing.xs,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: mat.isMain
                                      ? AppColors.primaryContainer
                                      : AppColors.skeleton,
                                  borderRadius: BorderRadius.circular(
                                    AppRadius.xs,
                                  ),
                                ),
                                child: Text(
                                  mat.isMain
                                      ? 'Giáo trình chính'
                                      : 'Tài liệu tham khảo',
                                  style: TextStyle(
                                    fontSize: AppFontSize.label,
                                    fontWeight: FontWeight.bold,
                                    color: mat.isMain
                                        ? AppColors.primary
                                        : AppColors.onSurfaceVariant,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mat.description,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          if (mat.author.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Tác giả: ${mat.author}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                          if (mat.publisher.isNotEmpty ||
                              mat.publishedDate.isNotEmpty ||
                              mat.edition.isNotEmpty ||
                              mat.isbn.isNotEmpty ||
                              mat.note.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              [
                                if (mat.publisher.isNotEmpty)
                                  'NXB: ${mat.publisher}',
                                if (mat.publishedDate.isNotEmpty)
                                  'Năm: ${mat.publishedDate}',
                                if (mat.edition.isNotEmpty)
                                  'Ấn bản: ${mat.edition}',
                                if (mat.isbn.isNotEmpty) 'ISBN: ${mat.isbn}',
                                if (mat.note.isNotEmpty) mat.note,
                              ].join(' · '),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    );
                  }).toList(),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        if (course.overview.isNotEmpty) ...[
          Text(course.overview),
          const SizedBox(height: AppSpacing.md),
        ],

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
            arguments: NoteDraft(
              courseCode: course.code,
              courseName: course.name,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        AppButton(
          label: 'Thêm việc cần làm cho ${course.code}',
          icon: Icons.playlist_add,
          isExpanded: true,
          onPressed: () => showTaskEditorSheet(
            context,
            vm: context.read<TasksViewModel>(),
            initialCourseCode: course.code,
            initialCourseName: course.name,
          ),
        ),
      ],
    );

    String viewerName = 'Sinh viên';
    try {
      final email = context.read<AuthViewModel>().currentUserEmail;
      if (email != null && email.contains('@')) {
        final localPart = email.split('@').first;
        viewerName = localPart.length > 80
            ? localPart.substring(0, 80)
            : localPart;
      }
    } catch (_) {}

    final tips = ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        CommunityTipsSection(
          course: course,
          store: effectiveStore,
          currentUid: activeUid,
          viewerName: viewerName,
          onSubmitted: () {
            try {
              roadmapVm.logExperienceNoteSubmitted(course);
            } catch (_) {}
          },
        ),
      ],
    );

    return DefaultTabController(
      length: 4,
      initialIndex: widget.initialTab.clamp(0, 3),
      child: Scaffold(
        appBar: CustomAppBar(
          title: course.code,
          onBack: () => Navigator.pop(context),
          actions: [
            IconButton(
              tooltip: 'Tạo ghi chú cho ${course.code}',
              icon: const Icon(Icons.edit_note_outlined),
              onPressed: () => Navigator.pushNamed(
                context,
                '/note-editor',
                arguments: NoteDraft(
                  courseCode: course.code,
                  courseName: course.name,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Thêm việc cần làm cho ${course.code}',
              icon: const Icon(Icons.playlist_add),
              onPressed: () => showTaskEditorSheet(
                context,
                vm: context.read<TasksViewModel>(),
                initialCourseCode: course.code,
                initialCourseName: course.name,
              ),
            ),
            IconButton(
              tooltip: 'Hỏi cố vấn về ${course.code}',
              icon: const Icon(Icons.support_agent),
              onPressed: () => Navigator.pushNamed(
                context,
                '/advisor',
                arguments: course.code,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Slots học'),
                Tab(text: 'Đánh giá & Điểm'),
                Tab(text: 'Tổng quan & Chuẩn đầu ra'),
                Tab(text: 'Bí kíp cộng đồng'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _slots(context, course, academic, roadmapVm),
                  _assessments(context, course),
                  overview,
                  tips,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _slots(
    BuildContext context,
    CourseModel course,
    AcademicViewModel academic,
    RoadmapViewModel roadmap,
  ) {
    final allSlots = course.slots;
    final total = roadmap.slotCountOf(course);
    final doneCount = roadmap.completedSlotCount(course);
    final progress = roadmap.slotProgress(course);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tiến độ học của bạn',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    total == 0
                        ? 'Chưa có dữ liệu slot'
                        : '$doneCount/$total slot',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.xs),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 8,
                  backgroundColor: AppColors.skeleton,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? AppColors.success : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed:
                          roadmap.isCourseCompleted(course) ||
                              doneCount >= total && total > 0
                          ? null
                          : () =>
                                _markCourseCompleted(context, roadmap, course),
                      icon: const Icon(Icons.done_all, size: 18),
                      label: const Text('Đã xong môn'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          doneCount == 0 && !roadmap.isCourseCompleted(course)
                          ? null
                          : () =>
                                _resetCourseProgress(context, roadmap, course),
                      icon: const Icon(Icons.restart_alt, size: 18),
                      label: const Text('Chưa xong môn'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Lịch học theo đề cương môn ${course.code}',
                style: Theme.of(context).textTheme.titleLarge,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '${allSlots.length} buổi học',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        if (allSlots.isEmpty)
          const AppCard(
            child: _SyllabusEmpty(
              message: 'Môn này chưa có lịch học chi tiết. Cán bộ có thể bổ sung bằng file đề cương FLM.',
            ),
          )
        else
          ...allSlots.map(
            (slot) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: roadmap.isSlotCompleted(course, slot.number)
                                ? AppColors.successContainer
                                : AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            'Slot ${slot.number}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color:
                                  roadmap.isSlotCompleted(course, slot.number)
                                  ? AppColors.success
                                  : AppColors.primary,
                              fontSize: AppFontSize.label,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            slot.displayTopic,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (roadmap.isSlotCompleted(course, slot.number))
                          const Icon(
                            Icons.check_circle,
                            color: AppColors.success,
                            size: 20,
                          ),
                      ],
                    ),
                    if (slot.date.isNotEmpty || slot.room.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        children: [
                          const Icon(
                            Icons.schedule_outlined,
                            size: 14,
                            color: AppColors.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            [
                              slot.date,
                              slot.room,
                            ].where((s) => s.isNotEmpty).join(' · '),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ],
                    if (slot.teachingType.isNotEmpty ||
                        slot.lo.isNotEmpty ||
                        slot.itu.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        [
                          if (slot.teachingType.isNotEmpty)
                            'Hình thức: ${slot.teachingType}',
                          if (slot.lo.isNotEmpty) 'LO: ${slot.lo}',
                          if (slot.itu.isNotEmpty) 'ITU: ${slot.itu}',
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                    if (slot.materials.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.menu_book_outlined,
                            size: 15,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Tài liệu: ${slot.materials}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (slot.tasks.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.task_alt_outlined,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Nhiệm vụ: ${slot.tasks}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (slot.cqs.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lightbulb_outline,
                            size: 15,
                            color: AppColors.warning,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Câu hỏi định hướng (CQ): ${slot.cqs}',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (slot.download.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Tải về: ${slot.download}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (slot.urls.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Liên kết: ${slot.urls}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.primary),
                      ),
                    ],
                    const Divider(height: AppSpacing.lg),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => _toggleSlot(
                          context,
                          roadmap,
                          course,
                          slot.number,
                          !roadmap.isSlotCompleted(course, slot.number),
                        ),
                        icon: Icon(
                          roadmap.isSlotCompleted(course, slot.number)
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 18,
                          color: roadmap.isSlotCompleted(course, slot.number)
                              ? AppColors.success
                              : AppColors.onSurfaceVariant,
                        ),
                        label: Text(
                          roadmap.isSlotCompleted(course, slot.number)
                              ? 'Đã học xong slot này'
                              : 'Đánh dấu đã học xong slot này',
                          style: TextStyle(
                            color: roadmap.isSlotCompleted(course, slot.number)
                                ? AppColors.success
                                : null,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _editLecturer(
    BuildContext context,
    RoadmapViewModel roadmap,
    CourseModel course,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Giảng viên môn ${course.code}'),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 120,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(
            labelText: 'Tên giảng viên',
            hintText: 'VD: Nguyễn Văn A',
            helperText: 'Thông tin này chỉ lưu trong hồ sơ của bạn.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || !context.mounted) return;
    final ok = await roadmap.saveCourseLecturer(course, result);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              roadmap.lastError ?? 'Không lưu được thông tin giảng viên.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      return;
    }
    showAppToast(
      context,
      message: result.isEmpty
          ? 'Đã xoá thông tin giảng viên.'
          : 'Đã lưu giảng viên: $result',
    );
  }

  Future<void> _toggleSlot(
    BuildContext context,
    RoadmapViewModel roadmap,
    CourseModel course,
    int slotNumber,
    bool completed,
  ) async {
    final ok = await roadmap.setSlotCompleted(
      course,
      slotNumber,
      completed: completed,
    );
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              roadmap.lastError ??
                  'Không lưu được tiến độ slot. Kiểm tra kết nối và thử lại.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      return;
    }
    showAppToast(
      context,
      message: completed
          ? 'Đã đánh dấu xong slot $slotNumber.'
          : 'Đã bỏ đánh dấu slot $slotNumber.',
    );
  }

  Future<void> _markCourseCompleted(
    BuildContext context,
    RoadmapViewModel roadmap,
    CourseModel course,
  ) async {
    final ok = await roadmap.setCourseCompleted(course, completed: true);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              roadmap.lastError ??
                  'Không lưu được tiến độ. Kiểm tra kết nối và thử lại.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      return;
    }
    showAppToast(
      context,
      message: 'Đã đánh dấu hoàn thành môn ${course.code}.',
      onAction: () async {
        final reset = await roadmap.resetCourseProgress(course);
        if (!reset && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                roadmap.lastError ?? 'Không hoàn tác được tiến độ môn học.',
              ),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
    );
  }

  Future<void> _resetCourseProgress(
    BuildContext context,
    RoadmapViewModel roadmap,
    CourseModel course,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Đánh dấu môn này là chưa học xong?'),
        content: const Text(
          'Toàn bộ slot đã đánh dấu sẽ được bỏ. Bạn có thể tích lại từng slot sau.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Đặt lại'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final ok = await roadmap.resetCourseProgress(course);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              roadmap.lastError ??
                  'Không lưu được tiến độ. Kiểm tra kết nối và thử lại.',
            ),
            backgroundColor: AppColors.error,
          ),
        );
      return;
    }
    showAppToast(context, message: 'Đã đặt lại tiến độ môn ${course.code}.');
  }

  Future<void> _openQuickGradeDialog(
    BuildContext context,
    AcademicViewModel academic,
    RoadmapViewModel roadmap,
    String courseCode,
    double? existingGrade,
  ) async {
    final controller = TextEditingController(
      text: existingGrade == null ? '' : existingGrade.toString(),
    );
    final grade = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        String? error;
        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: Text('Điểm môn $courseCode'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chỉ cần điểm môn tiên quyết từ 5.0 là đủ điều kiện. '
                  'Không cần đánh dấu xong slot của môn đó.',
                  style: TextStyle(fontSize: AppFontSize.label),
                ),
                const SizedBox(height: AppSpacing.sm),
                TextField(
                  controller: controller,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Điểm (0–10)',
                    hintText: 'VD: 7.5',
                    errorText: error,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: () {
                  final raw = controller.text.trim().replaceAll(',', '.');
                  final value = double.tryParse(raw);
                  if (value == null ||
                      !value.isFinite ||
                      value < 0 ||
                      value > 10) {
                    setDialogState(
                      () => error = 'Điểm phải nằm trong khoảng 0–10.',
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, value);
                },
                child: const Text('Lưu điểm'),
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (grade == null || !context.mounted) return;
    final ok = await academic.recordCourseGrade(
      courseCode: courseCode,
      grade: grade,
    );
    if (!context.mounted) return;
    if (ok) {
      await roadmap.loadData();
      if (!context.mounted) return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? grade >= 5
                      ? 'Đã lưu điểm $courseCode. Bạn đã đủ điều kiện tiên quyết.'
                      : 'Đã lưu điểm $courseCode. Điểm dưới 5.0 nên chưa đạt điều kiện.'
                : academic.lastError ?? 'Không lưu được điểm.',
          ),
        ),
      );
  }

  Widget _assessments(BuildContext context, CourseModel course) {
    final labs = course.labs;
    final academic = context.watch<AcademicViewModel>();
    final savedScores = academic.componentScoresFor(course.code);
    final profileReady = academic.state.state == ViewState.data;
    final enteredScores = <String, double>{};
    for (final lab in labs) {
      final text = _scoreControllers[lab.id]?.text.trim() ?? '';
      final value = double.tryParse(text.replaceAll(',', '.'));
      if (value != null) enteredScores[lab.id] = value;
    }
    final weightedTotal = AcademicViewModel.weightedTotal(
      course,
      enteredScores,
    );
    final totalWeight = AcademicViewModel.totalWeight(course);
    final weightMismatch = (totalWeight - 100).abs() > 0.01;

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Bài tập & Điểm thành phần',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              '${labs.length} đầu điểm',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        if (labs.isEmpty)
          const AppCard(
            child: _SyllabusEmpty(
              message: 'Môn này chưa có đầu điểm/trọng số từ đề cương FLM.',
            ),
          )
        else
          ...labs.map(
            (lab) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryContainer,
                            borderRadius: BorderRadius.circular(AppRadius.xs),
                          ),
                          child: Text(
                            lab.category.isNotEmpty ? lab.category : 'Đánh giá',
                            style: const TextStyle(
                              fontSize: AppFontSize.label,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                        if (lab.weight != null)
                          Text(
                            'Trọng số: ${(lab.weight!).toStringAsFixed(0)}%',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      lab.title,
                      style: Theme.of(context).textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    if (lab.type.isNotEmpty || lab.part.isNotEmpty)
                      Text(
                        [
                          if (lab.type.isNotEmpty) 'Hình thức: ${lab.type}',
                          if (lab.part.isNotEmpty) 'Phần: ${lab.part}',
                        ].join(' · '),
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    if (lab.completionCriteria.isNotEmpty)
                      Text(
                        'Điều kiện hoàn thành: ${lab.completionCriteria}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (lab.clo.isNotEmpty)
                      Text(
                        'CLO: ${lab.clo}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    if (lab.note.isNotEmpty)
                      Text(
                        'Ghi chú: ${lab.note}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    if (lab.duration.isNotEmpty)
                      Text(
                        'Thời gian: ${lab.duration}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    if (lab.deadline.isNotEmpty)
                      Text(
                        'Hạn chót: ${lab.deadline}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    if (lab.gradingCriteria.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Tiêu chí chấm: ${lab.gradingCriteria}',
                        style: Theme.of(context).textTheme.bodySmall
                            ?.copyWith(color: AppColors.onSurfaceVariant),
                      ),
                    ],
                    if (lab.score != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Điểm đã đạt: ${lab.score}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                    if ((lab.weight ?? 0) > 0) ...[
                      const SizedBox(height: AppSpacing.xs),
                      TextField(
                        controller: _scoreController(
                          lab,
                          savedScores,
                          profileReady,
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Điểm của bạn (0–10)',
                          hintText: 'VD: 8.5',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton.icon(
                          icon: const Icon(Icons.alarm_add, size: 16),
                          label: const Text('Thêm vào Việc cần làm'),
                          onPressed: () async {
                            final tasksVm = context.read<TasksViewModel>();
                            final ok = await tasksVm.addTask(
                              title: '${course.code}: ${lab.title}',
                              courseCode: course.code,
                              dueDate: lab.deadline.isNotEmpty
                                  ? lab.deadline
                                  : 'Hạn nộp theo thông báo kỳ',
                              priority: 'high',
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context)
                                  .hideCurrentSnackBar();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    ok
                                        ? 'Đã thêm "${lab.title}" vào danh sách Việc cần làm!'
                                        : 'Không thể thêm việc cần làm.',
                                  ),
                                ),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (labs.isNotEmpty && totalWeight > 0) ...[
          const SizedBox(height: AppSpacing.sm),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Điểm tổng tạm tính',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      weightedTotal == null
                          ? '—'
                          : '${weightedTotal.toStringAsFixed(2)} / 10',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: AppFontSize.displaySmall,
                        color: weightedTotal == null
                            ? AppColors.onSurfaceVariant
                            : (weightedTotal >= 5
                                  ? AppColors.success
                                  : AppColors.error),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Tổng trọng số đề cương: ${totalWeight.toStringAsFixed(0)}%'
                  '${weightMismatch ? ' · Đề cương không cộng đủ 100%, điểm tổng được chuẩn hóa theo tổng trọng số hiện có.' : ''}',
                  style: const TextStyle(
                    fontSize: AppFontSize.label,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                if (weightedTotal != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    weightedTotal >= 5
                        ? 'Kết quả tạm tính: qua môn.'
                        : 'Kết quả tạm tính: chưa qua môn (dưới 5).',
                    style: TextStyle(
                      fontSize: AppFontSize.label,
                      fontWeight: FontWeight.w600,
                      color: weightedTotal >= 5
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ),
                ] else ...[
                  const SizedBox(height: 4),
                  const Text(
                    'Nhập đủ điểm của mọi đầu điểm có trọng số để xem điểm tổng.',
                    style: TextStyle(
                      fontSize: AppFontSize.label,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _applyComponentTotal,
                  onChanged: (value) =>
                      setState(() => _applyComponentTotal = value ?? false),
                  title: const Text('Ghi điểm tổng vào bảng điểm'),
                  subtitle: const Text(
                    'Thay điểm môn này trong bảng điểm của bạn; đạt nếu điểm tổng từ 5 trở lên.',
                    style: TextStyle(fontSize: AppFontSize.label),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: AppButton(
                    label: 'Lưu điểm thành phần',
                    icon: Icons.save_outlined,
                    isLoading: _savingComponents,
                    onPressed: () => _saveComponentScores(
                      context,
                      course,
                      academic,
                      enteredScores,
                      weightedTotal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Điểm thành phần do bạn tự nhập để ước tính điểm tổng; hệ thống không tự suy đoán điểm từ danh mục.',
          style: TextStyle(
            fontSize: AppFontSize.label,
            color: AppColors.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  TextEditingController _scoreController(
    CourseLab lab,
    Map<String, double> savedScores,
    bool profileReady,
  ) {
    final controller = _scoreControllers.putIfAbsent(
      lab.id,
      () => TextEditingController(),
    );
    final saved = savedScores[lab.id];
    if (profileReady && _seededScoreIds.add(lab.id) && saved != null) {
      controller.text = saved == saved.roundToDouble()
          ? saved.toStringAsFixed(0)
          : saved.toStringAsFixed(1);
    }
    return controller;
  }

  Future<void> _saveComponentScores(
    BuildContext context,
    CourseModel course,
    AcademicViewModel academic,
    Map<String, double> enteredScores,
    double? weightedTotal,
  ) async {
    if (_savingComponents) return;
    if (enteredScores.isEmpty) {
      _showComponentMessage(context, 'Chưa nhập điểm thành phần nào.');
      return;
    }
    for (final score in enteredScores.values) {
      if (!score.isFinite || score < 0 || score > 10) {
        _showComponentMessage(
          context,
          'Điểm thành phần phải là số từ 0 đến 10.',
        );
        return;
      }
    }
    if (_applyComponentTotal && weightedTotal == null) {
      _showComponentMessage(
        context,
        'Cần nhập đủ điểm các đầu điểm có trọng số trước khi ghi vào bảng điểm.',
      );
      return;
    }
    setState(() => _savingComponents = true);
    final ok = await academic.saveComponentScores(
      course: course,
      scores: enteredScores,
      applyToTranscript: _applyComponentTotal,
    );
    if (!context.mounted) return;
    setState(() => _savingComponents = false);
    if (ok) {
      context.read<RoadmapViewModel>().loadData();
      _showComponentMessage(
        context,
        weightedTotal == null
            ? 'Đã lưu điểm thành phần.'
            : 'Đã lưu. Điểm tổng tạm tính: ${weightedTotal.toStringAsFixed(2)}/10.',
      );
    } else {
      _showComponentMessage(
        context,
        academic.lastError ?? 'Không lưu được điểm thành phần.',
      );
    }
  }

  void _showComponentMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _SyllabusEmpty extends StatelessWidget {
  const _SyllabusEmpty({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
