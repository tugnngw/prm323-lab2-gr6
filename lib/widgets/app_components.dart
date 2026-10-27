import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Card(child: Padding(padding: const EdgeInsets.all(AppSpacing.md), child: child));
    return onTap == null ? card : InkWell(onTap: onTap, borderRadius: BorderRadius.circular(AppRadius.md), child: card);
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key, required this.title, this.onBack, this.actions});

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) => AppBar(
        automaticallyImplyLeading: onBack != null,
        leading: onBack == null ? null : IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back)),
        title: Text(title),
        actions: actions,
      );

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({super.key, required this.title, required this.message, required this.onConfirm});

  final String title;
  final String message;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy')),
          FilledButton(onPressed: onConfirm, child: const Text('Xác nhận')),
        ],
      );
}
