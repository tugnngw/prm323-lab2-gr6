import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/advisor_viewmodel.dart';
import '../widgets/app_components.dart';

class StrategySimScreen extends StatelessWidget {
  const StrategySimScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final advisorVm = context.watch<AdvisorViewModel>();

    final semGpa = advisorVm.predictedSemesterGpa;
    final isHonors = advisorVm.reachesHonorsTarget;

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Mô phỏng Chiến lược & GPA',
        onBack: () => Navigator.pop(context),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Target Status Card
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Mục tiêu học tập (kịch bản mô phỏng)', style: Theme.of(context).textTheme.titleLarge),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isHonors ? AppColors.successContainer : AppColors.warningContainer,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: Text(
                        isHonors ? 'Đạt loại Giỏi 🎉' : 'Chưa đạt mục tiêu',
                        style: TextStyle(
                          color: isHonors ? AppColors.success : AppColors.warning,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricTile(
                        context,
                        title: 'GPA kỳ 5 (kịch bản)',
                        value: semGpa.toStringAsFixed(2),
                        subtitle: '11 tín chỉ · Mốc Giỏi: ≥ 8.00',
                        color: isHonors ? AppColors.success : AppColors.warning,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  isHonors
                      ? '✓ Kịch bản này đạt ngưỡng 8.0 — đủ điều kiện điểm cho danh hiệu Sinh viên Giỏi.'
                      : '⚠️ Kịch bản này dưới ngưỡng 8.0. Tăng điểm môn SWP391 (5 tín chỉ trọng số cao) sẽ kéo GPA kỳ lên mạnh nhất.',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isHonors ? AppColors.success : AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          Text('Điều chỉnh điểm số dự kiến kỳ 5', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),

          // Course 1: PRM323
          _buildScoreSlider(
            context,
            code: 'PRM323',
            name: 'Lập trình Di động Flutter (3 TC)',
            value: advisorVm.prmScore,
            onChanged: (val) => advisorVm.updateSimulation(prm: val),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Course 2: SWP391
          _buildScoreSlider(
            context,
            code: 'SWP391',
            name: 'Dự án Phát triển PM (5 TC - Quan trọng nhất)',
            value: advisorVm.swpScore,
            isImportant: true,
            onChanged: (val) => advisorVm.updateSimulation(swp: val),
          ),
          const SizedBox(height: AppSpacing.xs),

          // Course 3: SWR302
          _buildScoreSlider(
            context,
            code: 'SWR302',
            name: 'Kỹ thuật Yêu cầu PM (3 TC)',
            value: advisorVm.swrScore,
            onChanged: (val) => advisorVm.updateSimulation(swr: val),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Presets buttons
          Text('Kịch bản mẫu nhanh', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    advisorVm.updateSimulation(prm: 8.5, swp: 8.5, swr: 8.5);
                  },
                  child: const Text('Kịch bản Giỏi (8.5)'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    advisorVm.updateSimulation(prm: 9.0, swp: 8.5, swr: 8.0);
                  },
                  child: const Text('Kịch bản Đột phá'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) =>
      Container(
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
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.onSurfaceVariant)),
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
  }) =>
      AppCard(
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
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isImportant ? AppColors.primary : AppColors.onSurface,
                  ),
                ),
              ],
            ),
            Slider(
              value: value,
              min: 5.0,
              max: 10.0,
              divisions: 50,
              label: value.toStringAsFixed(1),
              onChanged: onChanged,
            ),
          ],
        ),
      );
}
