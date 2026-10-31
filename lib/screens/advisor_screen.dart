import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/advisor_viewmodel.dart';
import '../widgets/app_components.dart';

class AdvisorScreen extends StatefulWidget {
  const AdvisorScreen({super.key});

  @override
  State<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends State<AdvisorScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage(AdvisorViewModel vm, String text) {
    if (text.trim().isEmpty) return;
    vm.askQuestion(text.trim());
    _inputController.clear();

    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final advisorVm = context.watch<AdvisorViewModel>();

    return Scaffold(
      appBar: CustomAppBar(
        title: 'AI Academic Advisor',
        onBack: () => Navigator.pop(context),
        actions: [
          IconButton(
            icon: const Icon(Icons.calculate_outlined),
            tooltip: 'Mô phỏng GPA',
            onPressed: () => Navigator.pushNamed(context, '/strategy-sim'),
          ),
        ],
      ),
      body: !advisorVm.isAiEnabled
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.construction_outlined, size: 64, color: AppColors.warning),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Tính năng đang bảo trì',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Tính năng Cố vấn học tập AI tạm thời ngừng phục vụ theo cấu hình từ xa (Firebase Remote Config).',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Quay lại'),
                    ),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                // Top Banner: Link to GPA Simulation
                Container(
                  color: AppColors.primaryContainer,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.auto_awesome, size: 18, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.xs),
                      const Expanded(
                        child: Text(
                          'Mốc Sinh viên Giỏi: GPA tích lũy ≥ 8.0',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.onPrimaryContainer,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/strategy-sim'),
                        child: const Text('Mô phỏng →'),
                      ),
                    ],
                  ),
                ),

                // Chat Messages List
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(AppSpacing.md),
                    itemCount: advisorVm.messages.length,
                    itemBuilder: (context, index) {
                      final msg = advisorVm.messages[index];
                      final isUser = msg.sender == 'user';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: Row(
                          mainAxisAlignment:
                              isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (!isUser) ...[
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.school,
                                  size: 16,
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.xs),
                            ],
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: isUser ? AppColors.primary : AppColors.surface,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: isUser
                                      ? null
                                      : Border.all(color: AppColors.outline),
                                ),
                                child: Text(
                                  msg.text,
                                  style: TextStyle(
                                    color: isUser ? Colors.white : AppColors.onSurface,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),

                // Loading Indicator if AI is thinking
                if (advisorVm.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        SizedBox(width: AppSpacing.sm),
                        Text('AI đang suy nghĩ...', style: TextStyle(fontSize: 12)),
                      ],
                    ),
                  ),

                // Error branch (D3): retry the last question instead of
                // silently swallowing the failure.
                if (advisorVm.errorMessage != null && !advisorVm.isLoading)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 18, color: AppColors.error),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            advisorVm.errorMessage!,
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.error),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: advisorVm.retryLastQuestion,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  ),

                // Quick Prompt Chips
                Container(
                  color: AppColors.background,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ActionChip(
                          label: const Text('Chiến lược SWP391?'),
                          onPressed: () => _sendMessage(advisorVm, 'Chiến lược SWP391?'),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        ActionChip(
                          label: const Text('Duy trì điểm cao PRM323?'),
                          onPressed: () =>
                              _sendMessage(advisorVm, 'Duy trì điểm cao PRM323?'),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        ActionChip(
                          label: const Text('Mục tiêu GPA Giỏi?'),
                          onPressed: () =>
                              _sendMessage(advisorVm, 'Làm sao để đạt GPA Giỏi (>= 8.0)?'),
                        ),
                      ],
                    ),
                  ),
                ),

                // Text Input Bar
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: const BoxDecoration(
                    color: AppColors.surface,
                    border: Border(top: BorderSide(color: AppColors.outline)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _inputController,
                          decoration: const InputDecoration(
                            hintText: 'Hỏi AI Advisor bất kỳ điều gì về kỳ 5...',
                            isDense: true,
                          ),
                          onSubmitted: (val) => _sendMessage(advisorVm, val),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      IconButton.filled(
                        icon: const Icon(Icons.send_rounded),
                        onPressed: () => _sendMessage(advisorVm, _inputController.text),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
