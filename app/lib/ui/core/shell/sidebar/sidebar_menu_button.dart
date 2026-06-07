import 'package:comic_book_maker/ui/core/shell/sidebar/sidebar_theme.dart';
import 'package:flutter/material.dart';

enum SidebarMenuButtonSize { normal, lg }

/// 侧栏/底栏导航按钮（中性 token + 悬停/选中态）。
class SidebarMenuButton extends StatefulWidget {
  const SidebarMenuButton({
    super.key,
    required this.child,
    this.icon,
    this.isActive = false,
    this.onPressed,
    this.size = SidebarMenuButtonSize.normal,
    this.tooltip,
  });

  final Widget child;
  final Widget? icon;
  final bool isActive;
  final VoidCallback? onPressed;
  final SidebarMenuButtonSize size;
  final String? tooltip;

  @override
  State<SidebarMenuButton> createState() => _SidebarMenuButtonState();
}

class _SidebarMenuButtonState extends State<SidebarMenuButton> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final height = widget.size == SidebarMenuButtonSize.lg
        ? AppSidebarTheme.menuButtonHeightLg
        : AppSidebarTheme.menuButtonHeight;

    final background = widget.isActive
        ? scheme.surfaceContainerHighest
        : _hovered
            ? scheme.surfaceContainerHigh
            : Colors.transparent;

    final foreground = widget.isActive
        ? scheme.onSurface
        : scheme.onSurfaceVariant;

    final textStyle = theme.textTheme.labelLarge?.copyWith(
      color: foreground,
      fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
      height: 1.25,
    );

    Widget button = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.onPressed,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(
              AppSidebarTheme.menuButtonRadius,
            ),
            border: widget.isActive
                ? Border.all(color: scheme.outline)
                : null,
          ),
          child: Row(
            children: [
              if (widget.icon != null) ...[
                IconTheme(
                  data: IconThemeData(
                    color: foreground,
                    size: widget.size == SidebarMenuButtonSize.lg ? 18 : 16,
                  ),
                  child: widget.icon!,
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: DefaultTextStyle(
                  style: textStyle ?? const TextStyle(),
                  child: widget.child,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}
