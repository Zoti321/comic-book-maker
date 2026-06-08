import 'package:comic_book_maker/ui/core/design_system/app_button_core.dart';
import 'package:flutter/material.dart';

export 'app_button_core.dart'
    show
        AppButtonMetrics,
        AppButtonRadius,
        AppButtonSize,
        AppButtonVariant;

/// 自绘文字 / 图标+文字按钮（无 M3 水波纹）。
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.size = AppButtonSize.md,
    this.metrics,
    this.radius = AppButtonRadius.md,
    this.expanded = false,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final AppButtonVariant variant;
  final Widget? icon;
  final bool isLoading;
  final AppButtonSize size;
  final AppButtonMetrics? metrics;
  final AppButtonRadius radius;

  /// 拉满父级宽度，图标与文字左对齐。
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    return AppButtonCore(
      onPressed: onPressed,
      variant: variant,
      size: size,
      metrics: metrics,
      radius: radius,
      icon: icon,
      label: child,
      isLoading: isLoading,
      expanded: expanded,
    );
  }
}
