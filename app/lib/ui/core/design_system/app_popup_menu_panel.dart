import 'package:comic_book_maker/ui/core/theme/app_colors.dart';
import 'package:comic_book_maker/ui/core/theme/app_fonts.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 自绘弹出菜单面板（shadcn Popover / Command 风格）。
class AppPopupMenuPanel extends StatelessWidget {
  const AppPopupMenuPanel({
    super.key,
    required this.child,
    this.width,
    this.padding = const EdgeInsets.all(AppSpacing.xs),
  });

  final Widget child;
  final double? width;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: width,
        padding: padding,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.mdBorder,
          border: Border.all(color: AppColors.outline),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: width == null ? IntrinsicWidth(child: child) : child,
      ),
    );
  }
}

/// 弹出菜单单行；[leading] 固定 20px 槽位（如排序方向图标）。
class AppPopupMenuItem extends StatefulWidget {
  const AppPopupMenuItem({
    super.key,
    required this.label,
    required this.onTap,
    this.leading,
    this.selected = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final Widget? leading;
  final bool selected;
  final bool enabled;

  @override
  State<AppPopupMenuItem> createState() => _AppPopupMenuItemState();
}

class _AppPopupMenuItemState extends State<AppPopupMenuItem> {
  var _hovered = false;

  Color? get _backgroundColor {
    if (!widget.enabled) return null;
    if (widget.selected) return AppColors.surfaceContainer;
    if (_hovered) return AppColors.surfaceContainer;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final textStyle = AppFonts.textStyle(
      scheme: Theme.of(context).colorScheme,
      fontSize: AppTypography.bodySize,
      color: widget.enabled ? AppColors.onSurface : AppColors.onSurfaceVariant,
    );

    return MouseRegion(
      onEnter: widget.enabled ? (_) => setState(() => _hovered = true) : null,
      onExit: widget.enabled ? (_) => setState(() => _hovered = false) : null,
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: _backgroundColor,
            borderRadius: AppRadius.smBorder,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              SizedBox(width: 20, child: widget.leading),
              const SizedBox(width: AppSpacing.sm),
              Text(widget.label, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}
