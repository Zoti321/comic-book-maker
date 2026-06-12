import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// [HoverRevealMenuAnchor] 弹出菜单行：16px 图标、紧凑内边距、[TextTheme.bodySmall]。
class RevealPopupMenuRow extends StatelessWidget {
  const RevealPopupMenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final Color? foregroundColor;

  static const iconSize = 16.0;
  static const horizontalPadding = 8.0;
  static const verticalPadding = 4.0;
  static const iconGap = 8.0;
  static const menuItemHeight = 28.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = foregroundColor ?? scheme.onSurface;
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: iconSize, color: color),
          const SizedBox(width: iconGap),
          Text(label, style: textStyle),
        ],
      ),
    );
  }
}

/// 悬停 ⋮ 按钮的中性样式。
class RevealMenuButtonStyle {
  const RevealMenuButtonStyle({
    required this.iconColor,
    this.backgroundColor,
  });

  final Color iconColor;
  final Color? backgroundColor;
}

/// 桌面：悬停显示 ⋮ 按钮；移动端：长按弹出 [showMenu]（不显示按钮）。
class HoverRevealMenuAnchor<T> extends StatefulWidget {
  const HoverRevealMenuAnchor({
    super.key,
    required this.child,
    required this.menuItemsBuilder,
    required this.onSelected,
    this.enableLongPressMenu = true,
    this.buttonTop = 4,
    this.buttonRight = 4,
    this.menuIconColor = Colors.white,
    this.menuButtonStyle,
  });

  final Widget child;
  final List<PopupMenuEntry<T>> Function(BuildContext context) menuItemsBuilder;
  final ValueChanged<T> onSelected;
  final bool enableLongPressMenu;
  final double buttonTop;
  final double buttonRight;

  /// 旧 API；优先使用 [menuButtonStyle]。
  final Color menuIconColor;
  final RevealMenuButtonStyle? menuButtonStyle;

  @override
  State<HoverRevealMenuAnchor<T>> createState() => _HoverRevealMenuAnchorState<T>();
}

class _HoverRevealMenuAnchorState<T> extends State<HoverRevealMenuAnchor<T>> {
  bool _hovering = false;
  final GlobalKey _anchorKey = GlobalKey();
  BuildContext? _menuThemeContext;

  bool _showHoverButton(BuildContext context) =>
      !isCompact(context);

  bool _showLongPressMenu(BuildContext context) =>
      isCompact(context) && widget.enableLongPressMenu;

  Future<void> _openMenu() async {
    final anchorContext = _anchorKey.currentContext;
    final menuContext = _menuThemeContext;
    if (anchorContext == null || menuContext == null) return;

    final renderBox = anchorContext.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final overlayBox =
        Overlay.of(anchorContext).context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;

    final topLeft = renderBox.localToGlobal(Offset.zero, ancestor: overlayBox);
    final size = renderBox.size;
    final position = RelativeRect.fromLTRB(
      topLeft.dx + size.width - 40,
      topLeft.dy + 8,
      overlayBox.size.width - topLeft.dx - size.width + 40,
      overlayBox.size.height - topLeft.dy - 8,
    );

    final selected = await showMenu<T>(
      context: menuContext,
      position: position,
      color: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      items: widget.menuItemsBuilder(anchorContext),
    );

    if (selected != null && mounted) {
      widget.onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showHover = _showHoverButton(context);
    final longPress = _showLongPressMenu(context);
    final baseTheme = Theme.of(context);
    final localTheme = baseTheme.copyWith(
      popupMenuTheme: baseTheme.popupMenuTheme.copyWith(
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        textStyle: baseTheme.textTheme.bodySmall,
      ),
    );

    return Theme(
      data: localTheme,
      child: Builder(
        builder: (menuContext) {
          _menuThemeContext = menuContext;

          return KeyedSubtree(
            key: _anchorKey,
            child: MouseRegion(
              onEnter: showHover ? (_) => setState(() => _hovering = true) : null,
              onExit: showHover ? (_) => setState(() => _hovering = false) : null,
              child: GestureDetector(
                onLongPress: longPress ? _openMenu : null,
                behavior: HitTestBehavior.deferToChild,
                child: Stack(
                  clipBehavior: Clip.none,
                  fit: StackFit.passthrough,
                  children: [
                    widget.child,
                    if (showHover && _hovering)
                      Positioned(
                        top: widget.buttonTop,
                        right: widget.buttonRight,
                        child: RevealMenuIconButton(
                          onPressed: _openMenu,
                          iconColor: widget.menuButtonStyle?.iconColor ??
                              widget.menuIconColor,
                          backgroundColor:
                              widget.menuButtonStyle?.backgroundColor,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// 透明底、高对比 ⋮；圆形 [InkWell] 与波纹一致。
class RevealMenuIconButton extends StatelessWidget {
  const RevealMenuIconButton({
    super.key,
    required this.onPressed,
    this.tooltip,
    this.iconColor = Colors.white,
    this.backgroundColor,
  });

  final VoidCallback onPressed;
  final String? tooltip;
  final Color iconColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = backgroundColor;
    final usePill = bg != null && bg.a > 0;

    final button = Material(
      type: MaterialType.transparency,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: DecoratedBox(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: usePill ? bg : null,
            border: usePill
                ? Border.all(color: scheme.outline.withValues(alpha: 0.8))
                : null,
            boxShadow: usePill
                ? [
                    BoxShadow(
                      color: scheme.shadow.withValues(alpha: 0.12),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              LucideIcons.ellipsisVertical,
              size: 20,
              color: iconColor,
            ),
          ),
        ),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}
