import 'package:comic_book_maker/ui/core/theme/app_colors.dart';
import 'package:comic_book_maker/ui/core/theme/app_fonts.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 按钮视觉变体（[AppButton] / [AppIconButton] 共用）。
enum AppButtonVariant { primary, secondary, ghost, destructive }

/// Tailwind 风格尺寸档位；默认 [md]。
enum AppButtonSize { xs, sm, md, lg, xl }

/// 圆角档位；默认 [md]（8px）。纯图标按钮可用 [circle]。
enum AppButtonRadius { sm, md, lg, pill, circle }

/// 可选指标覆盖；未设字段沿用 [AppButtonSize] 基准。
class AppButtonMetrics {
  const AppButtonMetrics({
    this.height,
    this.padding,
    this.fontSize,
    this.iconSize,
    this.iconGap,
    this.minWidth,
  });

  final double? height;
  final EdgeInsets? padding;
  final double? fontSize;
  final double? iconSize;
  final double? iconGap;
  final double? minWidth;
}

@immutable
class _ResolvedButtonMetrics {
  const _ResolvedButtonMetrics({
    required this.height,
    required this.padding,
    required this.fontSize,
    required this.iconSize,
    required this.iconGap,
    required this.minWidth,
  });

  final double height;
  final EdgeInsets padding;
  final double fontSize;
  final double iconSize;
  final double iconGap;
  final double minWidth;
}

_ResolvedButtonMetrics _resolveButtonMetrics(
  AppButtonSize size, [
  AppButtonMetrics? overrides,
]) {
  final base = switch (size) {
    AppButtonSize.xs => const _ResolvedButtonMetrics(
        height: 28,
        padding: EdgeInsets.symmetric(horizontal: 10),
        fontSize: 12,
        iconSize: 14,
        iconGap: 6,
        minWidth: 48,
      ),
    AppButtonSize.sm => const _ResolvedButtonMetrics(
        height: 32,
        padding: EdgeInsets.symmetric(horizontal: 12),
        fontSize: 13,
        iconSize: 16,
        iconGap: 6,
        minWidth: 56,
      ),
    AppButtonSize.md => const _ResolvedButtonMetrics(
        height: 36,
        padding: EdgeInsets.symmetric(horizontal: 16),
        fontSize: 14,
        iconSize: 18,
        iconGap: 8,
        minWidth: 64,
      ),
    AppButtonSize.lg => const _ResolvedButtonMetrics(
        height: 40,
        padding: EdgeInsets.symmetric(horizontal: 20),
        fontSize: 15,
        iconSize: 20,
        iconGap: 8,
        minWidth: 72,
      ),
    AppButtonSize.xl => const _ResolvedButtonMetrics(
        height: 44,
        padding: EdgeInsets.symmetric(horizontal: 24),
        fontSize: 16,
        iconSize: 22,
        iconGap: 10,
        minWidth: 80,
      ),
  };

  if (overrides == null) return base;

  return _ResolvedButtonMetrics(
    height: overrides.height ?? base.height,
    padding: overrides.padding ?? base.padding,
    fontSize: overrides.fontSize ?? base.fontSize,
    iconSize: overrides.iconSize ?? base.iconSize,
    iconGap: overrides.iconGap ?? base.iconGap,
    minWidth: overrides.minWidth ?? base.minWidth,
  );
}

BorderRadius _resolveButtonBorderRadius(
  AppButtonRadius radius,
  double height, {
  required bool iconOnly,
}) {
  if (iconOnly || radius == AppButtonRadius.circle) {
    return BorderRadius.circular(height / 2);
  }
  return switch (radius) {
    AppButtonRadius.sm => AppRadius.smBorder,
    AppButtonRadius.md => AppRadius.mdBorder,
    AppButtonRadius.lg => AppRadius.lgBorder,
    AppButtonRadius.pill => BorderRadius.circular(height / 2),
    AppButtonRadius.circle => BorderRadius.circular(height / 2),
  };
}

@immutable
class _ButtonColors {
  const _ButtonColors({
    required this.background,
    required this.foreground,
    required this.border,
    required this.borderWidth,
    required this.spinnerColor,
  });

  final Color background;
  final Color foreground;
  final Color? border;
  final double borderWidth;
  final Color spinnerColor;
}

_ButtonColors _colorsFor({
  required AppButtonVariant variant,
  required bool enabled,
  required bool hovered,
  required bool pressed,
}) {
  if (!enabled) {
    return _ButtonColors(
      background: _restBackground(variant),
      foreground: _restForeground(variant),
      border: _restBorder(variant),
      borderWidth: variant == AppButtonVariant.secondary ? 1 : 0,
      spinnerColor: _restForeground(variant),
    );
  }

  if (pressed) {
    return _ButtonColors(
      background: _pressedBackground(variant),
      foreground: _restForeground(variant),
      border: _pressedBorder(variant),
      borderWidth: variant == AppButtonVariant.secondary ? 1 : 0,
      spinnerColor: _restForeground(variant),
    );
  }

  if (hovered) {
    return _ButtonColors(
      background: _hoverBackground(variant),
      foreground: _restForeground(variant),
      border: _hoverBorder(variant),
      borderWidth: variant == AppButtonVariant.secondary ? 1 : 0,
      spinnerColor: _restForeground(variant),
    );
  }

  return _ButtonColors(
    background: _restBackground(variant),
    foreground: _restForeground(variant),
    border: _restBorder(variant),
    borderWidth: variant == AppButtonVariant.secondary ? 1 : 0,
    spinnerColor: _restForeground(variant),
  );
}

Color _restBackground(AppButtonVariant variant) => switch (variant) {
      AppButtonVariant.primary => AppColors.primary,
      AppButtonVariant.secondary => Colors.transparent,
      AppButtonVariant.ghost => Colors.transparent,
      AppButtonVariant.destructive => AppColors.error,
    };

Color _hoverBackground(AppButtonVariant variant) => switch (variant) {
      AppButtonVariant.primary => const Color(0xFF3F3F46),
      AppButtonVariant.secondary => AppColors.surfaceContainer,
      AppButtonVariant.ghost => AppColors.surfaceLow,
      AppButtonVariant.destructive => const Color(0xFFB91C1C),
    };

Color _pressedBackground(AppButtonVariant variant) => switch (variant) {
      AppButtonVariant.primary => const Color(0xFF18181B),
      AppButtonVariant.secondary => AppColors.surfaceContainerHigh,
      AppButtonVariant.ghost => AppColors.surfaceContainer,
      AppButtonVariant.destructive => const Color(0xFF991B1B),
    };

Color _restForeground(AppButtonVariant variant) => switch (variant) {
      AppButtonVariant.primary => AppColors.onPrimary,
      AppButtonVariant.secondary => AppColors.onSurface,
      AppButtonVariant.ghost => AppColors.onSurface,
      AppButtonVariant.destructive => AppColors.onError,
    };

Color? _restBorder(AppButtonVariant variant) => switch (variant) {
      AppButtonVariant.secondary => AppColors.outline,
      _ => null,
    };

Color? _hoverBorder(AppButtonVariant variant) => switch (variant) {
      AppButtonVariant.secondary => AppColors.surfaceContainerHigh,
      _ => null,
    };

Color? _pressedBorder(AppButtonVariant variant) => switch (variant) {
      AppButtonVariant.secondary => AppColors.surfaceContainerHighest,
      _ => null,
    };

/// 自绘按钮内核（无 M3 水波纹）；供 [AppButton] / [AppIconButton] 共用。
class AppButtonCore extends StatefulWidget {
  const AppButtonCore({
    super.key,
    required this.onPressed,
    required this.variant,
    this.size = AppButtonSize.md,
    this.metrics,
    this.radius = AppButtonRadius.md,
    this.icon,
    this.label,
    this.isLoading = false,
    this.iconOnly = false,
  });

  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final AppButtonMetrics? metrics;
  final AppButtonRadius radius;
  final Widget? icon;
  final Widget? label;
  final bool isLoading;
  final bool iconOnly;

  @override
  State<AppButtonCore> createState() => _AppButtonCoreState();
}

class _AppButtonCoreState extends State<AppButtonCore> {
  var _hovered = false;
  var _pressed = false;
  var _focused = false;

  bool get _enabled => widget.onPressed != null && !widget.isLoading;

  @override
  Widget build(BuildContext context) {
    final resolved = _resolveButtonMetrics(widget.size, widget.metrics);
    final iconOnly = widget.iconOnly || widget.label == null;
    final borderRadius = _resolveButtonBorderRadius(
      widget.radius,
      resolved.height,
      iconOnly: iconOnly,
    );
    final colors = _colorsFor(
      variant: widget.variant,
      enabled: _enabled,
      hovered: _hovered && _enabled,
      pressed: _pressed && _enabled,
    );

    final minWidth = iconOnly ? resolved.height : resolved.minWidth;
    final padding = iconOnly
        ? EdgeInsets.zero
        : resolved.padding;

    Widget content = _buildContent(resolved, colors, iconOnly);

    final button = Opacity(
      opacity: _enabled ? 1 : 0.45,
      child: MouseRegion(
      onEnter: _enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: _enabled ? (_) => setState(() => _hovered = false) : null,
      cursor: _enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Focus(
        onFocusChange: (focused) => setState(() => _focused = focused),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: _enabled ? (_) => setState(() => _pressed = true) : null,
          onTapUp: _enabled ? (_) => setState(() => _pressed = false) : null,
          onTapCancel: _enabled ? () => setState(() => _pressed = false) : null,
          onTap: _enabled ? widget.onPressed : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOut,
            constraints: BoxConstraints(
              minWidth: minWidth,
              minHeight: resolved.height,
            ),
            height: resolved.height,
            padding: padding,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: borderRadius,
              border: Border.all(
                color: _focused
                    ? AppColors.primary
                    : colors.border ?? Colors.transparent,
                width: _focused ? 2 : colors.borderWidth,
              ),
            ),
            child: content,
          ),
        ),
      ),
      ),
    );

    return button;
  }

  Widget _buildContent(
    _ResolvedButtonMetrics resolved,
    _ButtonColors colors,
    bool iconOnly,
  ) {
    if (widget.isLoading) {
      return SizedBox(
        width: resolved.iconSize,
        height: resolved.iconSize,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: colors.spinnerColor,
        ),
      );
    }

    final icon = widget.icon == null
        ? null
        : IconTheme.merge(
            data: IconThemeData(
              size: resolved.iconSize,
              color: colors.foreground,
            ),
            child: widget.icon!,
          );

    if (iconOnly) {
      return icon ?? const SizedBox.shrink();
    }

    final labelStyle = AppFonts.textStyle(
      scheme: Theme.of(context).colorScheme,
      fontSize: resolved.fontSize,
      fontWeight: FontWeight.w600,
      color: colors.foreground,
    );

    final label = DefaultTextStyle(
      style: labelStyle,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      child: widget.label!,
    );

    if (icon == null) return label;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        icon,
        SizedBox(width: resolved.iconGap),
        Flexible(child: label),
      ],
    );
  }
}
