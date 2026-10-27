import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../widgets/app_button.dart';

/// SCR-00.01_AuthSetup — Màn hình đăng nhập bằng Google.
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo / Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.school_rounded,
                    size: 44,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Title & Subtitle
                Text(
                  'FPTU Second Brain',
                  style: Theme.of(context).textTheme.headlineLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Trợ lý học tập thông minh cho sinh viên Đại học FPT.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Error message banner
                if (authViewModel.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.errorContainer,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(color: AppColors.error),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            authViewModel.errorMessage!,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                        IconButton(
                          onPressed: authViewModel.clearError,
                          icon: const Icon(Icons.close, size: 18),
                          color: AppColors.error,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Features highlight
                _buildFeatureItem(
                  context,
                  icon: Icons.offline_pin_outlined,
                  title: 'Hoạt động ngoại tuyến',
                  subtitle: 'Ghi chú và lộ trình luôn sẵn sàng ngay cả khi mất mạng.',
                ),
                const SizedBox(height: AppSpacing.md),
                _buildFeatureItem(
                  context,
                  icon: Icons.sync_outlined,
                  title: 'Đồng bộ đám mây',
                  subtitle: 'Dữ liệu tự động đồng bộ lên Firebase khi có kết nối.',
                ),
                const SizedBox(height: AppSpacing.md),
                _buildFeatureItem(
                  context,
                  icon: Icons.auto_awesome_outlined,
                  title: 'AI Advisor',
                  subtitle: 'Hỗ trợ lên chiến lược học tập và kiểm tra môn tiên quyết.',
                ),
                const SizedBox(height: AppSpacing.xxl),

                // Google Sign-In Button
                AppButton(
                  label: 'Đăng nhập với Google (@fpt.edu.vn)',
                  icon: Icons.login_rounded,
                  isLoading: authViewModel.isLoading,
                  isExpanded: true,
                  onPressed: () => authViewModel.signInWithGoogle(),
                ),
                const SizedBox(height: AppSpacing.md),

                // Terms disclaimer
                Text(
                  'Bằng cách đăng nhập, bạn đồng ý với Điều khoản dịch vụ và Chính sách quyền riêng tư của FPTU Second Brain.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 12,
                        color: AppColors.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) =>
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
        ],
      );
}
