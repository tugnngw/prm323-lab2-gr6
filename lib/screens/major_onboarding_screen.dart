import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_state.dart';
import '../models/course_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/academic_viewmodel.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../viewmodels/roadmap_viewmodel.dart';
import '../widgets/app_components.dart';
import '../widgets/app_states.dart';

/// First-run gate: a signed-in student must pick a curriculum before the main
/// shell opens. The list is read from the `majors` collection managed by the
/// web admin, so newly imported majors appear without an app update.
class MajorOnboardingScreen extends StatefulWidget {
  const MajorOnboardingScreen({super.key});

  @override
  State<MajorOnboardingScreen> createState() => _MajorOnboardingScreenState();
}

class _MajorOnboardingScreenState extends State<MajorOnboardingScreen> {
  Future<void> _choose(AcademicViewModel vm, MajorModel major) async {
    final roadmap = context.read<RoadmapViewModel>();
    final ok = await vm.chooseMajor(major.code);
    if (ok) {
      await roadmap.loadData();
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(vm.lastError ?? 'Không lưu được chuyên ngành.'),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AcademicViewModel>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chọn chuyên ngành'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            tooltip: 'Đăng xuất',
            icon: const Icon(Icons.logout_outlined),
            onPressed: context.read<AuthViewModel>().signOut,
          ),
        ],
      ),
      body: switch (vm.state.state) {
        ViewState.loading => const AppLoadingState(
          message: 'Đang tải danh sách chuyên ngành...',
        ),
        ViewState.error => AppErrorState(
          message:
              vm.state.message ?? 'Không tải được danh sách chuyên ngành.',
          onRetry: vm.loadData,
        ),
        _ => _buildBody(context, vm),
      },
    );
  }

  Widget _buildBody(BuildContext context, AcademicViewModel vm) {
    final majors = vm.availableMajors;
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Chào mừng bạn!',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Chọn chuyên ngành để tải đúng lộ trình học. Danh sách lấy trực tiếp '
          'từ hệ thống quản trị, và app chỉ tải môn học của ngành bạn chọn.',
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(color: AppColors.onSurfaceVariant),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Chuyên ngành của bạn',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: AppSpacing.sm),
        if (majors.isEmpty)
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.warning),
                    SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Chưa có chuyên ngành nào trên hệ thống.',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                const Text(
                  'Quản trị viên cần import chương trình từ FLM trước khi bạn '
                  'có thể chọn ngành.',
                ),
                const SizedBox(height: AppSpacing.sm),
                OutlinedButton.icon(
                  onPressed: vm.loadData,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Tải lại danh sách'),
                ),
              ],
            ),
          )
        else
          ...majors.map(
            (major) => Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: AppCard(
                onTap: vm.isSaving ? null : () => _choose(vm, major),
                child: Row(
                  children: [
                    const Icon(
                      Icons.school_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            major.name.trim().isEmpty
                                ? major.code
                                : major.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${major.code} · ${major.totalSemesters} kỳ học',
                            style: const TextStyle(
                              fontSize: AppFontSize.label,
                              color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (vm.isSaving)
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else
                      const Icon(
                        Icons.chevron_right,
                        color: AppColors.onSurfaceVariant,
                      ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        const Text(
          'Sau khi chọn, bạn có thể đổi chuyên ngành ở tab Lộ trình.',
          style: TextStyle(
            fontSize: AppFontSize.label,
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
