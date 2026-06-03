import 'package:flutter/material.dart';

enum AppIconButtonVariant { standard, filled, tonal, outline }

/// Material 3 图标按钮封装。
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.variant = AppIconButtonVariant.standard,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final AppIconButtonVariant variant;

  @override
  Widget build(BuildContext context) {
    final button = switch (variant) {
      AppIconButtonVariant.standard => IconButton(
          onPressed: onPressed,
          icon: icon,
        ),
      AppIconButtonVariant.filled => IconButton.filled(
          onPressed: onPressed,
          icon: icon,
        ),
      AppIconButtonVariant.tonal => IconButton.filledTonal(
          onPressed: onPressed,
          icon: icon,
        ),
      AppIconButtonVariant.outline => IconButton.outlined(
          onPressed: onPressed,
          icon: icon,
        ),
    };

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
