import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/academic_viewmodel.dart';
import '../viewmodels/roadmap_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_components.dart';
import '../widgets/app_states.dart';

/// Explicit user entry, with no seeded transcript or external FAP credentials.
/// The class schedule is managed on its own screen (`/schedule`).
class AcademicProfileScreen extends StatefulWidget {
  const AcademicProfileScreen({super.key, this.showStudyPlan = false});

  final bool showStudyPlan;
  @override
  State<AcademicProfileScreen> createState() => _AcademicProfileScreenState();
}

class _AcademicProfileScreenState extends State<AcademicProfileScreen> {
  final _transcript = TextEditingController();
  final _semester = TextEditingController();
  final _target = TextEditingController();
  bool _initialized = false;

  @override
  void dispose() {
    _transcript.dispose();
    _semester.dispose();
    _target.dispose();
    super.dispose();
  }

  Future<void> _save(AcademicViewModel vm) async {
    final semester = int.tryParse(_semester.text.trim());
    final target = double.tryParse(_target.text.trim());
    if (semester == null || target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nhập kỳ học và mục tiêu GPA hợp lệ.')),
      );
      return;
    }
    final ok = await vm.save(
      transcript: _transcript.text,
      semester: semester,
      targetGpa: target,
    );
    if (!mounted) return;
    if (ok) {
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

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AcademicViewModel>();
    if (!_initialized && vm.state.state == ViewState.data) {
      _transcript.text = vm.transcriptText;
      _semester.text = vm.selectedSemester?.toString() ?? '';
      _target.text = vm.profile.targetGpa.toString();
      _initialized = true;
    }
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Dữ liệu học tập',
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
          message: 'Đăng nhập để nhập dữ liệu học tập.',
        ),
        ViewState.data => ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            if (widget.showStudyPlan)
              OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/study-plan'),
                child: const Text('Duyệt kế hoạch học tập'),
              ),
            const AppCard(
              child: Text(
                'Nhập dữ liệu thật từ bảng điểm và lịch học của bạn. Dữ liệu được lưu trong hồ sơ Firebase riêng theo tài khoản; không gửi bảng điểm, lịch học hay nội dung câu hỏi vào Analytics hoặc dịch vụ AI bên ngoài.',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppCard(
              onTap: () => Navigator.pushNamed(context, '/schedule'),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.calendar_month_outlined),
                title: const Text('Thời khóa biểu'),
                subtitle: Text(
                  vm.timetable.isEmpty
                      ? 'Chưa có buổi học. Thêm buổi học theo FAP.'
                      : '${vm.timetable.length} buổi học trong tuần',
                ),
                trailing: const Icon(Icons.chevron_right),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _semester,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Kỳ học đang lập kế hoạch',
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _target,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Mục tiêu GPA cá nhân (0–10)',
                helperText: 'Đây là mục tiêu cá nhân, không phải quy định xếp loại của trường.',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Bảng điểm', style: Theme.of(context).textTheme.titleLarge),
            const Text(
              'Mỗi dòng: mã môn,tín chỉ,điểm,kỳ,đã qua(true/false). Chỉ nhập kết quả hiện hành theo bảng điểm chính thức; không suy đoán điểm hoặc quy tắc học lại.',
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _transcript,
              minLines: 4,
              maxLines: 10,
              decoration: const InputDecoration(
                labelText: 'Bảng điểm của bạn',
                alignLabelWithHint: true,
                hintText: 'Mã môn,tín chỉ,điểm,kỳ,true/false',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Lưu dữ liệu học tập riêng tư',
              icon: Icons.save_outlined,
              isLoading: vm.isSaving,
              onPressed: () => _save(vm),
            ),
          ],
        ),
      },
    );
  }
}
