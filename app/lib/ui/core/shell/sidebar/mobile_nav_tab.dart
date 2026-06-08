import 'package:comic_book_maker/ui/core/shell/sidebar/sidebar_theme.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 窄屏底栏 Tab：上图标、下文字；选中仅靠颜色强调，无描边与常驻底色。
///
/// 常态背景须用 [AppSidebarTheme.menuItemBackgroundRest]，勿用 `Colors.transparent`；
/// 见 `docs/agents/flutter-ui.md` §颜色过渡动画。
class MobileNavTab extends StatefulWidget {
  const MobileNavTab({
    super.key,
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onPressed;

  static const iconSize = 20.0;
  static const labelGap = 4.0;
  static const padding = EdgeInsets.symmetric(horizontal: 8, vertical: 6);

  @override
  State<MobileNavTab> createState() => _MobileNavTabState();
}

class _MobileNavTabState extends State<MobileNavTab> {
  var _hovered = false;
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final showBackground = _pressed || (_hovered && !widget.isActive);
    final background = showBackground
        ? AppSidebarTheme.menuItemBackgroundHover(scheme)
        : AppSidebarTheme.menuItemBackgroundRest(scheme);

    final foreground =
        widget.isActive ? scheme.onSurface : scheme.onSurfaceVariant;

    final textStyle = theme.textTheme.labelLarge?.copyWith(
      fontSize: AppTypography.labelSize,
      color: foreground,
      fontWeight: widget.isActive ? FontWeight.w600 : FontWeight.w500,
      height: 1.25,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          padding: MobileNavTab.padding,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppSidebarTheme.menuButtonRadius),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, size: MobileNavTab.iconSize, color: foreground),
              const SizedBox(height: MobileNavTab.labelGap),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textStyle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
