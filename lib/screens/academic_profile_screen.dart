import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/academic_viewmodel.dart';
import '../viewmodels/roadmap_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_components.dart';
import '../widgets/app_states.dart';

/// Explicit user entry, with no seeded transcript or external FAP credentials.
/// Split into two tabs so grades and personal targets each have a dedicated
/// place instead of one very long scroll.
class AcademicProfileScreen extends StatefulWidget {
  const AcademicProfileScreen({super.key, this.showStudyPlan = false});

  final bool showStudyPlan;
  @override
  State<AcademicProfileScreen> createState() => _AcademicProfileScreenState();
}

class _GradeDraft {
  _GradeDraft({
    String code = '',
    String credits = '',
    String grade = '',
    this.semester = 1,
  }) : code = TextEditingController(text: code),
       credits = TextEditingController(text: credits),
       grade = TextEditingController(text: grade);

  final TextEditingController code;
  final TextEditingController credits;
  final TextEditingController grade;
  int semester;

  bool get isBlank =>
      code.text.trim().isEmpty &&
      credits.text.trim().isEmpty &&
      grade.text.trim().isEmpty;

  String get codeValue => code.text.trim().toUpperCase();
  int? get creditsValue => int.tryParse(credits.text.trim());
  double? get gradeValue =>
      double.tryParse(grade.text.trim().replaceAll(',', '.'));

  void dispose() {
    code.dispose();
    credits.dispose();
    grade.dispose();
  }
}

class _AcademicProfileScreenState extends State<AcademicProfileScreen> {
  final _target = TextEditingController();
  final _grades = <_GradeDraft>[];
  bool _initialized = false;
  bool _resettingMajor = false;

  @override
  void dispose() {
    _target.dispose();
    for (final row in _grades) {
      row.dispose();
    }
    super.dispose();
  }

  void _loadDrafts(AcademicViewModel vm) {
    for (final row in _grades) {
      row.dispose();
    }
    _grades
      ..clear()
      ..addAll(
        vm.profile.transcript.map(
          (e) => _GradeDraft(
            code: e.courseCode,
            credits: e.credits.toString(),
            grade: e.grade.toString(),
            semester: e.semester,
          ),
        ),
      );
    _target.text = vm.profile.targetGpa.toString();
  }

  void _autofillFromCode(AcademicViewModel vm, _GradeDraft row) {
    final code = row.codeValue;
    if (code.isEmpty) return;
    for (final course in vm.courses) {
      if (course.code.toUpperCase() != code) continue;
      if (row.credits.text.trim().isEmpty && course.credits > 0) {
        row.credits.text = course.credits.toString();
      }
      if (row.semester == 0 && course.semester > 0) {
        row.semester = course.semester;
      }
      return;
    }
  }

  String? _validate(AcademicViewModel vm) {
    final seen = <String>{};
    for (final row in _grades.where((r) => !r.isBlank)) {
      final code = row.codeValue;
      final credits = row.creditsValue;
      final grade = row.gradeValue;
      if (code.isEmpty) return 'Bảng điểm: nhập mã môn cho mọi dòng đã điền.';
      if (credits == null || credits <= 0) {
        return 'Môn $code: tín chỉ phải là số nguyên dương.';
      }
      if (grade == null || !grade.isFinite || grade < 0 || grade > 10) {
        return 'Môn $code: điểm phải nằm trong khoảng 0–10.';
      }
      if (row.semester < 1) return 'Môn $code: kỳ học phải từ 1 trở lên.';
      if (!seen.add(code)) {
        return 'Môn $code bị nhập trùng. Mỗi môn chỉ giữ một kết quả hiện hành.';
      }
    }
    return null;
  }

  String get _transcriptCsv => _grades
      .where((row) => !row.isBlank)
      .map(
        (row) =>
            '${row.codeValue},${row.creditsValue},${row.gradeValue},${row.semester},${row.gradeValue! >= 5}',
      )
      .join('\n');

  Future<void> _save(AcademicViewModel vm) async {
    final target = double.tryParse(_target.text.trim());
    if (target == null || !target.isFinite || target < 0 || target > 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mục tiêu GPA phải nằm trong khoảng 0–10.'),
        ),
      );
      return;
    }
    final validationError = _validate(vm);
    if (validationError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }
    final ok = await vm.save(
      transcript: _transcriptCsv,
      targetGpa: target,
    );
    if (!mounted) return;
    if (ok) {
      setState(() => _loadDrafts(vm));
      await context.read<RoadmapViewModel>().loadData();
      if (!mounted) return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Đã lưu dữ liệu học tập của bạn.'
              : vm.lastError ?? 'Không lưu được dữ liệu.',
        ),
      ),
    );
  }

  Future<void> _confirmResetMajor(AcademicViewModel vm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chọn lại chuyên ngành?'),
        content: const Text(
          'App sẽ quay về màn hình chọn ngành như lần đầu. Bảng điểm và mục '
          'tiêu GPA vẫn được giữ nguyên.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Chọn lại ngành'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _resettingMajor = true);
    final ok = await vm.resetMajor();
    if (!mounted) return;
    setState(() => _resettingMajor = false);
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(vm.lastError ?? 'Không xoá được chuyên ngành.')),
      );
      return;
    }
    await context.read<RoadmapViewModel>().loadData();
    if (!mounted) return;
    // The onboarding gate lives on the root route, so pop this screen to let
    // the major picker become visible.
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AcademicViewModel>();
    if (!_initialized && vm.state.state == ViewState.data) {
      _loadDrafts(vm);
      _initialized = true;
    }
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Dữ liệu học tập',
          onBack: () => Navigator.pop(context),
          bottom: const PreferredSize(
            preferredSize: Size.fromHeight(48),
            child: TabBar(
              tabs: [
                Tab(text: 'Thông tin'),
                Tab(text: 'Bảng điểm'),
              ],
            ),
          ),
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
            message: 'Đăng nhập để nhập dữ liệu học tập.',
          ),
          ViewState.data => Column(
            children: [
              Expanded(
                child: TabBarView(
                  children: [
                    _buildInfoTab(context, vm),
                    _buildGradesTab(context, vm),
                  ],
                ),
              ),
              _buildSaveBar(context, vm),
            ],
          ),
        },
      ),
    );
  }

  Widget _buildSaveBar(BuildContext context, AcademicViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: AppButton(
          label: 'Lưu dữ liệu học tập riêng tư',
          icon: Icons.save_outlined,
          isLoading: vm.isSaving,
          onPressed: () => _save(vm),
        ),
      ),
    );
  }

  Widget _buildInfoTab(BuildContext context, AcademicViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (widget.showStudyPlan)
          OutlinedButton(
            onPressed: () => Navigator.pushNamed(context, '/study-plan'),
            child: const Text('Duyệt kế hoạch học tập'),
          ),
        const AppCard(
          child: Text(
            'Chuyên ngành được chọn khi bắt đầu dùng ứng dụng. Bảng điểm và '
            'mục tiêu GPA là tùy chọn — bạn có thể bỏ trống và nhập sau. Dữ '
            'liệu chỉ lưu trong hồ sơ Firebase riêng của tài khoản.',
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          'Chuyên ngành',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.school_outlined, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _majorLabel(vm),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          '${vm.profile.major} · ${vm.majorTotalSemesters} kỳ học'
                          ' · Đổi ngành tại tab Lộ trình',
                          style: const TextStyle(
                            fontSize: AppFontSize.label,
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              OutlinedButton.icon(
                onPressed: _resettingMajor ? null : () => _confirmResetMajor(vm),
                icon: _resettingMajor
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.restart_alt),
                label: const Text('Chọn lại ngành'),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Mục tiêu cá nhân (tùy chọn)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        TextField(
          controller: _target,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Mục tiêu GPA (0–10)',
            helperText:
                'Chỉ dùng cho phần mô phỏng GPA ở Cố vấn học tập; không phải quy định xếp loại của trường.',
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const AppCard(
          child: Text(
            'Mẹo: nhập bảng điểm trước để app kiểm tra môn tiên quyết và tính '
            'GPA; cố vấn học tập dùng chính dữ liệu này để trả lời trên thiết bị.',
          ),
        ),
      ],
    );
  }

  Widget _buildGradesTab(BuildContext context, AcademicViewModel vm) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Bảng điểm (tùy chọn)',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.xxs),
        const Text(
          'Nhập từng môn đã học. Hệ thống tự điền tín chỉ theo đề cương và tự xác định Đạt khi điểm từ 5.0 trở lên.',
        ),
        const SizedBox(height: AppSpacing.sm),
        if (vm.profile.cumulativeGpa != null) ...[
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.insights_outlined, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'GPA tích lũy (tự tính): ${vm.profile.cumulativeGpa!.toStringAsFixed(2)} / 10',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
        for (var i = 0; i < _grades.length; i++) ...[
          _buildGradeCard(context, vm, i),
          const SizedBox(height: AppSpacing.sm),
        ],
        OutlinedButton.icon(
          onPressed: () => setState(
            () => _grades.add(_GradeDraft(semester: vm.selectedSemester ?? 1)),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Thêm môn vào bảng điểm'),
        ),
      ],
    );
  }

  String _majorLabel(AcademicViewModel vm) {
    final code = vm.profile.major.trim().toUpperCase();
    final matches = vm.availableMajors.where(
      (m) => m.code.toUpperCase() == code,
    );
    if (matches.isNotEmpty && matches.first.name.trim().isNotEmpty) {
      return matches.first.name.trim();
    }
    return vm.profile.major.isEmpty
        ? 'Chưa chọn chuyên ngành'
        : vm.profile.major;
  }

  Widget _buildGradeCard(
    BuildContext context,
    AcademicViewModel vm,
    int index,
  ) {
    final row = _grades[index];
    final grade = row.gradeValue;
    final passed = grade != null && grade >= 5;
    final maxSemester = vm.majorTotalSemesters;
    final semesterOptions = <int>{
      for (var s = 1; s <= maxSemester; s++) s,
      if (row.semester > maxSemester) row.semester,
    }.toList()..sort();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: row.code,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Mã môn',
                    hintText: 'VD: PRM323',
                  ),
                  onChanged: (_) => setState(() => _autofillFromCode(vm, row)),
                ),
              ),
              IconButton(
                tooltip: 'Xóa môn',
                onPressed: () => setState(() {
                  _grades.removeAt(index).dispose();
                }),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: row.credits,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tín chỉ'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: TextField(
                  controller: row.grade,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(labelText: 'Điểm (0–10)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<int>(
                  initialValue: row.semester,
                  decoration: const InputDecoration(labelText: 'Kỳ học'),
                  items: semesterOptions
                      .map(
                        (semester) => DropdownMenuItem(
                          value: semester,
                          child: Text('Kỳ $semester'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => row.semester = value);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Container(
                  height: 56,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: passed ? AppColors.successContainer : AppColors.skeleton,
                    borderRadius: BorderRadius.circular(AppRadius.xs),
                  ),
                  child: Text(
                    grade == null
                        ? 'Chưa có điểm'
                        : passed
                        ? 'Đạt'
                        : 'Chưa đạt',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: grade == null
                          ? AppColors.onSurfaceVariant
                          : passed
                          ? AppColors.success
                          : AppColors.warning,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
