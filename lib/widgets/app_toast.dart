import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';

OverlayEntry? _activeEntry;
Timer? _activeTimer;

/// Shows a short-lived confirmation, optionally with one action.
///
/// A SnackBar with an action can stay on screen indefinitely when the device
/// has an accessibility timeout enabled, so this toast owns an explicit
/// [Timer] and always removes itself after [duration].
void showAppToast(
  BuildContext context, {
  required String message,
  VoidCallback? onAction,
  String actionLabel = 'Hoàn tác',
  Duration duration = const Duration(seconds: 5),
}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;
  _hideActiveToast();

  final entry = OverlayEntry(
    builder: (_) => _AppToast(
      message: message,
      actionLabel: actionLabel,
      onAction: onAction == null
          ? null
          : () {
              _hideActiveToast();
              onAction();
            },
    ),
  );
  _activeEntry = entry;
  overlay.insert(entry);
  _activeTimer = Timer(duration, _hideActiveToast);
}

void _hideActiveToast() {
  _activeTimer?.cancel();
  _activeTimer = null;
  final entry = _activeEntry;
  _activeEntry = null;
  if (entry == null) return;
  if (entry.mounted) entry.remove();
  entry.dispose();
}

class _AppToast extends StatefulWidget {
  const _AppToast({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  State<_AppToast> createState() => _AppToastState();
}

class _AppToastState extends State<_AppToast> {
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _visible = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Positioned(
      left: AppSpacing.md,
      right: AppSpacing.md,
      bottom: bottomInset + 88,
      child: AnimatedSlide(
        offset: _visible ? Offset.zero : const Offset(0, 0.25),
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        child: AnimatedOpacity(
          opacity: _visible ? 1 : 0,
          duration: const Duration(milliseconds: 180),
          child: Material(
            color: AppColors.snackbar,
            elevation: AppElevation.overlay,
            borderRadius: BorderRadius.circular(AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.xs,
                AppSpacing.xs,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: AppColors.onPrimary,
                        fontSize: AppFontSize.dense,
                      ),
                    ),
                  ),
                  if (widget.onAction != null) ...[
                    const SizedBox(width: AppSpacing.xs),
                    TextButton(
                      onPressed: widget.onAction,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryContainer,
                        minimumSize: const Size(0, 40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                        ),
                      ),
                      child: Text(
                        widget.actionLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ] else
                    const SizedBox(width: AppSpacing.xs),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
