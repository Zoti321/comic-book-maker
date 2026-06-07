import 'package:comic_book_maker/ui/core/design_system/app_button_core.dart';
import 'package:flutter/material.dart';

/// 自绘纯图标按钮（无 M3 水波纹）。
///
/// [tooltip] 仅用于启用态、纯图标且语义不够直观时；[disabledTooltip] 仅在禁用时显示。
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.disabledTooltip,
    this.variant = AppButtonVariant.ghost,
    this.size = AppButtonSize.md,
    this.metrics,
    this.radius = AppButtonRadius.md,
  });

  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? disabledTooltip;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final AppButtonMetrics? metrics;
  final AppButtonRadius radius;

  @override
  Widget build(BuildContext context) {
    final button = AppButtonCore(
      onPressed: onPressed,
      variant: variant,
      size: size,
      metrics: metrics,
      radius: radius,
      icon: icon,
      iconOnly: true,
    );

    final message = onPressed == null ? disabledTooltip : tooltip;
    if (message == null) return button;
    return Tooltip(message: message, child: button);
  }
}
