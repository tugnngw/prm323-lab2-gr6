import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_spacing.dart';

abstract final class AppTheme {
  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: AppColors.primary,
      onPrimary: Colors.white,
      primaryContainer: AppColors.primaryContainer,
      onPrimaryContainer: AppColors.onPrimaryContainer,
      secondary: AppColors.secondary,
      surface: AppColors.surface,
      error: AppColors.error,
      onSurface: AppColors.onSurface,
      onSurfaceVariant: AppColors.onSurfaceVariant,
      outline: AppColors.outline,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.background,
      fontFamily: 'Inter',
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 28, height: 34 / 28, fontWeight: FontWeight.w700),
        headlineMedium: TextStyle(fontSize: 22, height: 28 / 22, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 18, height: 24 / 18, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 16, height: 22 / 16, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 16, height: 24 / 16),
        bodyMedium: TextStyle(fontSize: 14, height: 20 / 14),
        labelLarge: TextStyle(fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500),
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.outline),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 48),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
      ),
      navigationBarTheme: const NavigationBarThemeData(
        height: 80,
        labelTextStyle: WidgetStatePropertyAll(TextStyle(fontSize: 12)),
      ),
    );
  }
}
