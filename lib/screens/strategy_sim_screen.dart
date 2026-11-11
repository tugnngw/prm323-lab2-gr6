import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/academic_profile.dart';
import '../models/app_state.dart';
import '../models/course_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/academic_viewmodel.dart';
import '../widgets/app_components.dart';
import '../widgets/app_states.dart';

enum _GpaMode { semester, cumulative }

/// GPA sandbox with exactly two questions:
/// 1. How would this semester's GPA look with the grades I expect?
/// 2. What is my cumulative GPA right now, including grades from other terms?
///
/// Transcript grades are always read-only here; only courses without a real
/// grade accept a hypothetical one, and nothing is written back to the profile.
class StrategySimScreen extends StatefulWidget {
  const StrategySimScreen({super.key});

  @override
  State<StrategySimScreen> createState() => _StrategySimScreenState();
}

class _StrategySimScreenState extends State<StrategySimScreen> {
  _GpaMode _mode = _GpaMode.semester;
  int? _cumulativeSemester;

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AcademicViewModel>();
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Mô phỏng GPA',
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
          message: 'Chưa có danh mục môn để mô phỏng.',
        ),
        ViewState.data => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            SegmentedButton<_GpaMode>(
              segments: const [
                ButtonSegment(
                  value: _GpaMode.semester,
                  label: Text('GPA kỳ'),
                  icon: Icon(Icons.calendar_month_outlined),
                ),
                ButtonSegment(
                  value: _GpaMode.cumulative,
                  label: Text('GPA tích lũy'),
                  icon: Icon(Icons.functions),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (selection) =>
                  setState(() => _mode = selection.first),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_mode == _GpaMode.semester)
              ..._buildSemesterMode(vm)
            else
              ..._buildCumulativeMode(vm),
          ],
        ),
      },
    );
  }

  // ── Mode 1: the semester currently selected in Academic Profile ──

  List<Widget> _buildSemesterMode(AcademicViewModel vm) {
    final semester = vm.selectedSemester;
    final courses = vm.semesterCourses;
    final rows = _semesterRows(vm);
    final gpa = _weightedGpa(rows);
    final credits = _totalCredits(rows);
    final missingGrades = courses.where((course) {
      return _latestEntry(vm, course.code) == null &&
          vm.plannedGrade(course.code) == null;
    }).length;

    return [
      _buildResultCard(
        title: 'GPA kỳ ${semester ?? '—'}',
        gpa: gpa,
        credits: credits,
        caption:
            '${rows.where((row) => row.fromTranscript).length} môn lấy từ bảng điểm, '
            '${rows.where((row) => !row.fromTranscript).length} môn dự kiến.'
            '${missingGrades > 0 ? ' Còn $missingGrades môn chưa nhập điểm.' : ''}',
      ),
      const SizedBox(height: AppSpacing.sm),
      const AppCard(
        child: Text(
          'Điểm đã có trong bảng điểm được tự động lấy và không sửa được ở đây. '
          'Môn chưa có điểm mới nhập điểm dự kiến. Kịch bản chỉ nằm trong bộ nhớ, '
          'không ghi vào bảng điểm thật.',
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      Wrap(
        spacing: AppSpacing.xs,
        children: [
          for (final value in vm.semesters)
            ChoiceChip(
              label: Text('Kỳ $value'),
              selected: semester == value,
              onSelected: (_) => vm.selectSemester(value),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      if (courses.isEmpty)
        const AppEmptyState(message: 'Danh mục chưa có môn cho kỳ này.')
      else
        for (final course in courses) ...[
          _buildCourseCard(vm, course),
          const SizedBox(height: AppSpacing.sm),
        ],
      _buildTargetLine(vm, gpa),
    ];
  }

  // ── Mode 2: cumulative GPA from every real + hypothetical grade ──

  List<Widget> _buildCumulativeMode(AcademicViewModel vm) {
    final rows = _cumulativeRows(vm);
    final gpa = _weightedGpa(rows);
    final credits = _totalCredits(rows);
    final semesters = vm.semesters;
    final entrySemester = _resolvedCumulativeSemester(vm);
    final entryCourses = vm.majorCourses
        .where((course) => course.semester == entrySemester)
        .toList();

    return [
      _buildResultCard(
        title: 'GPA tích lũy hiện tại',
        gpa: gpa,
        credits: credits,
        caption:
            '${rows.where((row) => row.fromTranscript).length} môn có điểm thật, '
            '${rows.where((row) => !row.fromTranscript).length} môn dự kiến.',
      ),
      const SizedBox(height: AppSpacing.sm),
      const AppCard(
        child: Text(
          'GPA tích lũy = tổng (điểm × tín chỉ) của mọi môn đã có điểm, chia tổng '
          'tín chỉ. Bạn có thể nhập điểm dự kiến cho môn chưa có điểm ở bất kỳ kỳ '
          'nào; điểm thật trong bảng điểm luôn được giữ nguyên.',
        ),
      ),
      const SizedBox(height: AppSpacing.sm),
      _buildTranscriptSection(vm),
      const SizedBox(height: AppSpacing.sm),
      Text(
        'Nhập điểm dự kiến theo kỳ',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: AppSpacing.xs),
      Wrap(
        spacing: AppSpacing.xs,
        children: [
          for (final value in semesters)
            ChoiceChip(
              label: Text('Kỳ $value'),
              selected: entrySemester == value,
              onSelected: (_) => setState(() => _cumulativeSemester = value),
            ),
        ],
      ),
      const SizedBox(height: AppSpacing.sm),
      if (entryCourses.isEmpty)
        const AppEmptyState(message: 'Danh mục chưa có môn cho kỳ này.')
      else
        for (final course in entryCourses) ...[
          _buildCourseCard(vm, course),
          const SizedBox(height: AppSpacing.sm),
        ],
      _buildTargetLine(vm, gpa, cumulative: true),
    ];
  }

  int? _resolvedCumulativeSemester(AcademicViewModel vm) {
    final semesters = vm.semesters;
    if (semesters.isEmpty) return null;
    if (_cumulativeSemester != null &&
        semesters.contains(_cumulativeSemester)) {
      return _cumulativeSemester;
    }
    return vm.selectedSemester ?? semesters.last;
  }

  // ── Shared pieces ──

  Widget _buildCourseCard(AcademicViewModel vm, CourseModel course) {
    final entry = _latestEntry(vm, course.code);
    if (entry != null) {
      return AppCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${course.code} · ${course.name}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    'Điểm trong bảng điểm · ${course.credits} tín chỉ',
                    style: const TextStyle(
                      fontSize: AppFontSize.caption,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              entry.grade.toStringAsFixed(1),
              style: const TextStyle(
                fontSize: AppFontSize.displaySmall,
                fontWeight: FontWeight.w700,
                color: AppColors.success,
              ),
            ),
          ],
        ),
      );
    }

    final planned = vm.plannedGrade(course.code);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${course.code} · ${course.name}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          Text(
            '${course.credits} tín chỉ · chưa có điểm trong bảng điểm',
            style: const TextStyle(
              fontSize: AppFontSize.caption,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (planned == null)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => vm.setPlannedGrade(course.code, 5),
                icon: const Icon(Icons.add_chart, size: 18),
                label: const Text('Nhập điểm dự kiến'),
              ),
            )
          else ...[
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: planned,
                    min: 0,
                    max: 10,
                    divisions: 100,
                    label: planned.toStringAsFixed(1),
                    onChanged: (value) =>
                        vm.setPlannedGrade(course.code, value),
                  ),
                ),
                SizedBox(
                  width: 44,
                  child: Text(
                    planned.toStringAsFixed(1),
                    textAlign: TextAlign.end,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => vm.setPlannedGrade(course.code, null),
                child: const Text('Bỏ dự kiến'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required String title,
    required double? gpa,
    required int credits,
    required String caption,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppColors.onPrimaryContainer,
            ),
          ),
          const SizedBox(height: AppSpacing.hairline),
          Text(
            gpa?.toStringAsFixed(2) ?? 'Chưa đủ điểm',
            style: const TextStyle(
              fontSize: AppFontSize.displayLarge,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryPressed,
            ),
          ),
          Text(
            '$credits tín chỉ được tính · $caption',
            style: const TextStyle(
              fontSize: AppFontSize.caption,
              color: AppColors.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTranscriptSection(AcademicViewModel vm) {
    final bySemester = <int, List<TranscriptEntry>>{};
    for (final entry in vm.profile.transcript) {
      bySemester.putIfAbsent(entry.semester, () => []).add(entry);
    }
    if (bySemester.isEmpty) {
      return const AppCard(
        child: Text(
          'Chưa có bảng điểm thật. Nhập điểm dự kiến bên dưới để xem GPA sẽ ra sao.',
        ),
      );
    }
    final keys = bySemester.keys.toList()..sort();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Điểm đã có trong bảng điểm',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          for (final semester in keys) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Kỳ $semester',
              style: const TextStyle(
                fontSize: AppFontSize.label,
                fontWeight: FontWeight.w700,
                color: AppColors.onSurfaceVariant,
              ),
            ),
            for (final entry in bySemester[semester]!)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.hairline),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${entry.courseCode} · ${entry.credits} TC'
                        '${entry.passed ? '' : ' · chưa qua'}',
                      ),
                    ),
                    Text(
                      entry.grade.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: entry.passed
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildTargetLine(
    AcademicViewModel vm,
    double? gpa, {
    bool cumulative = false,
  }) {
    final target = vm.profile.targetGpa;
    final gap = gpa == null ? null : gpa - target;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Text(
        'Mục tiêu cá nhân: ${target.toStringAsFixed(2)}'
        '${gap == null
            ? ''
            : gap >= 0
            ? ' — cao hơn ${gap.toStringAsFixed(2)}'
            : ' — còn thiếu ${(-gap).toStringAsFixed(2)}'}.\n'
        '${cumulative ? 'Mốc tham chiếu Sinh viên Giỏi: GPA tích lũy ≥ 8.0. ' : ''}'
        'Đây chỉ là con số tham chiếu, không phải kết luận danh hiệu hay xét tốt nghiệp.',
        style: const TextStyle(
          fontSize: AppFontSize.caption,
          color: AppColors.onSurfaceVariant,
        ),
      ),
    );
  }

  // ── Calculations ──

  List<_GpaRow> _semesterRows(AcademicViewModel vm) {
    final rows = <_GpaRow>[];
    for (final course in vm.semesterCourses) {
      final entry = _latestEntry(vm, course.code);
      if (entry != null) {
        rows.add(
          _GpaRow(
            credits: course.credits > 0 ? course.credits : entry.credits,
            grade: entry.grade,
            fromTranscript: true,
          ),
        );
      } else {
        final planned = vm.plannedGrade(course.code);
        if (planned != null) {
          rows.add(
            _GpaRow(
              credits: course.credits,
              grade: planned,
              fromTranscript: false,
            ),
          );
        }
      }
    }
    return rows;
  }

  List<_GpaRow> _cumulativeRows(AcademicViewModel vm) {
    final rows = <_GpaRow>[
      for (final entry in vm.profile.transcript)
        _GpaRow(
          credits: entry.credits,
          grade: entry.grade,
          fromTranscript: true,
        ),
    ];
    for (final course in vm.majorCourses) {
      if (_latestEntry(vm, course.code) != null) continue;
      final planned = vm.plannedGrade(course.code);
      if (planned == null) continue;
      rows.add(
        _GpaRow(credits: course.credits, grade: planned, fromTranscript: false),
      );
    }
    return rows;
  }

  static TranscriptEntry? _latestEntry(AcademicViewModel vm, String code) {
    final normalized = code.trim().toUpperCase();
    TranscriptEntry? latest;
    for (final entry in vm.profile.transcript) {
      if (entry.courseCode.trim().toUpperCase() != normalized) continue;
      if (latest == null || entry.semester >= latest.semester) latest = entry;
    }
    return latest;
  }

  static double? _weightedGpa(List<_GpaRow> rows) {
    var credits = 0;
    var weighted = 0.0;
    for (final row in rows) {
      if (row.credits <= 0) continue;
      credits += row.credits;
      weighted += row.grade * row.credits;
    }
    return credits == 0 ? null : weighted / credits;
  }

  static int _totalCredits(List<_GpaRow> rows) => rows
      .where((row) => row.credits > 0)
      .fold(0, (sum, row) => sum + row.credits);
}

class _GpaRow {
  const _GpaRow({
    required this.credits,
    required this.grade,
    required this.fromTranscript,
  });

  final int credits;
  final double grade;
  final bool fromTranscript;
}
