import 'package:flutter/material.dart';

import '../models/notification_model.dart';
import '../theme/app_spacing.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.onTap,
    this.semanticLabel,
  });

  final Widget child;
  final VoidCallback? onTap;

  /// Screen-reader label; falls back to the child's own text when null.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
    final tappable = onTap == null
        ? card
        : InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: card,
          );
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: tappable,
    );
  }
}

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  const CustomAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.bottom,
  });

  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) => AppBar(
    automaticallyImplyLeading: onBack != null,
    leading: onBack == null
        ? null
        : IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Quay lại',
          ),
    title: Text(title),
    actions: actions,
    bottom: bottom,
  );

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));
}

/// In-app banner for a push received while the app is in the foreground
/// (Lab 3 T12 — one of the three delivery states). Tapping opens the push's
/// destination; the close button dismisses without navigating.
class ForegroundPushBanner extends StatelessWidget {
  const ForegroundPushBanner({
    super.key,
    required this.notification,
    required this.onOpen,
    required this.onDismiss,
  });

  final NotificationModel notification;
  final VoidCallback onOpen;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label:
        'Thông báo mới: '
        '${notification.title.isEmpty ? 'Thông báo mới' : notification.title}',
    child: Material(
      elevation: AppElevation.overlay,
      borderRadius: BorderRadius.circular(AppRadius.md),
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: onOpen,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              const Icon(Icons.notifications_active_outlined, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      notification.title.isEmpty
                          ? 'Thông báo mới'
                          : notification.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (notification.body.isNotEmpty)
                      Text(
                        notification.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: AppFontSize.label),
                      ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                tooltip: 'Đóng',
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class AppConfirmDialog extends StatelessWidget {
  const AppConfirmDialog({
    super.key,
    required this.title,
    required this.message,
    required this.onConfirm,
  });

  final String title;
  final String message;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title),
    content: Text(message),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Hủy'),
      ),
      FilledButton(onPressed: onConfirm, child: const Text('Xác nhận')),
    ],
  );
}
