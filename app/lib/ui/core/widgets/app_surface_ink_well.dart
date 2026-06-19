import 'package:flutter/material.dart';

/// 大面积可点 surface 的 ink 反馈 preset（无 Material ripple）。
enum AppSurfaceInkPreset {
  /// 库卡片：hover 8%、按下 12%。
  libraryCard,

  /// 密 grid 格（缩略图、添加页）：仅按下 8%，无 hover。
  gridTile,
}

/// 无 ripple 的大面积 surface [InkWell]；overlay 按 [preset] 提供 hover/按下反馈。
class AppSurfaceInkWell extends StatelessWidget {
  const AppSurfaceInkWell({
    super.key,
    required this.preset,
    required this.onTap,
    required this.child,
    this.onLongPress,
    this.borderRadius,
    this.customBorder,
  });

  final AppSurfaceInkPreset preset;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Widget child;
  final BorderRadius? borderRadius;
  final ShapeBorder? customBorder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      splashFactory: NoSplash.splashFactory,
      borderRadius: borderRadius,
      customBorder: customBorder,
      overlayColor: _overlayColor(scheme, preset),
      child: child,
    );
  }

  static WidgetStateProperty<Color?> _overlayColor(
    ColorScheme scheme,
    AppSurfaceInkPreset preset,
  ) {
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.pressed)) {
        final alpha = preset == AppSurfaceInkPreset.libraryCard ? 0.12 : 0.08;
        return scheme.onSurface.withValues(alpha: alpha);
      }
      if (preset == AppSurfaceInkPreset.libraryCard &&
          states.contains(WidgetState.hovered)) {
        return scheme.onSurface.withValues(alpha: 0.08);
      }
      return null;
    });
  }
}
