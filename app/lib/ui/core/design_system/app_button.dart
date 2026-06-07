import 'package:flutter/material.dart';

enum AppButtonVariant { primary, secondary, outline, ghost, destructive }

/// Material 3 按钮封装；高度与圆角跟随主题。
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final label = isLoading
        ? SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: _progressColor(context),
            ),
          )
        : child;

    final childWidget = icon == null
        ? label
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme.merge(
                data: const IconThemeData(size: 18),
                child: icon!,
              ),
              const SizedBox(width: 8),
              Flexible(child: label),
            ],
          );

    return switch (variant) {
      AppButtonVariant.primary => FilledButton(
          onPressed: enabled ? onPressed : null,
          child: childWidget,
        ),
      AppButtonVariant.secondary => FilledButton.tonal(
          onPressed: enabled ? onPressed : null,
          child: childWidget,
        ),
      AppButtonVariant.outline => OutlinedButton(
          onPressed: enabled ? onPressed : null,
          child: childWidget,
        ),
      AppButtonVariant.ghost => TextButton(
          onPressed: enabled ? onPressed : null,
          child: childWidget,
        ),
      AppButtonVariant.destructive => FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          onPressed: enabled ? onPressed : null,
          child: childWidget,
        ),
    };
  }

  Color? _progressColor(BuildContext context) {
    return switch (variant) {
      AppButtonVariant.primary ||
      AppButtonVariant.destructive =>
        Theme.of(context).colorScheme.onPrimary,
      AppButtonVariant.secondary =>
        Theme.of(context).colorScheme.onSecondaryContainer,
      AppButtonVariant.outline ||
      AppButtonVariant.ghost =>
        Theme.of(context).colorScheme.onSurface,
    };
  }
}
