import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Primary filled button with minimum 48 dp touch target.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.isExpanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    Widget button;

    if (icon != null) {
      button = FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        icon: isLoading ? const _ButtonSpinner() : Icon(icon),
        label: Text(label),
      );
    } else {
      button = FilledButton(
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? const _ButtonSpinner()
            : Text(label),
      );
    }

    return isExpanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Secondary outlined button with minimum 48 dp touch target.
class AppOutlinedButton extends StatelessWidget {
  const AppOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isExpanded = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    Widget button;

    if (icon != null) {
      button = OutlinedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      );
    } else {
      button = OutlinedButton(
        onPressed: onPressed,
        child: Text(label),
      );
    }

    return isExpanded ? SizedBox(width: double.infinity, child: button) : button;
  }
}

class _ButtonSpinner extends StatelessWidget {
  const _ButtonSpinner();

  @override
  Widget build(BuildContext context) => const SizedBox(
        width: AppSpacing.lg,
        height: AppSpacing.lg,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
}
