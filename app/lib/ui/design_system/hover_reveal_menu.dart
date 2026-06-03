import 'package:comic_book_maker/ui/layout/responsive.dart';
import 'package:flutter/material.dart';

/// 桌面：悬停显示透明 ⋮ 按钮；移动端：长按弹出 [showMenu]（不显示按钮）。
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
  });

  final Widget child;
  final List<PopupMenuEntry<T>> Function(BuildContext context) menuItemsBuilder;
  final ValueChanged<T> onSelected;
  final bool enableLongPressMenu;
  final double buttonTop;
  final double buttonRight;
  final Color menuIconColor;

  @override
  State<HoverRevealMenuAnchor<T>> createState() => _HoverRevealMenuAnchorState<T>();
}

class _HoverRevealMenuAnchorState<T> extends State<HoverRevealMenuAnchor<T>> {
  bool _hovering = false;
  final GlobalKey _anchorKey = GlobalKey();

  bool _showHoverButton(BuildContext context) =>
      !isCompact(context);

  bool _showLongPressMenu(BuildContext context) =>
      isCompact(context) && widget.enableLongPressMenu;

  Future<void> _openMenu() async {
    final anchorContext = _anchorKey.currentContext;
    if (anchorContext == null) return;

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
      context: anchorContext,
      position: position,
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
                    iconColor: widget.menuIconColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 透明底、高对比 ⋮；圆形 [InkWell] 与波纹一致。
class RevealMenuIconButton extends StatelessWidget {
  const RevealMenuIconButton({
    super.key,
    required this.onPressed,
    this.tooltip = '更多操作',
    this.iconColor = Colors.white,
  });

  final VoidCallback onPressed;
  final String tooltip;
  final Color iconColor;

  static const _darkShadows = [
    Shadow(color: Color(0xCC000000), blurRadius: 8, offset: Offset(0, 1)),
    Shadow(color: Color(0x80000000), blurRadius: 2),
  ];

  static const _lightShadows = [
    Shadow(color: Color(0x33000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  @override
  Widget build(BuildContext context) {
    final onDark = iconColor.computeLuminance() > 0.55;
    final shadows = onDark ? _lightShadows : _darkShadows;

    return Tooltip(
      message: tooltip,
      child: Material(
        type: MaterialType.transparency,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(
              Icons.more_vert,
              size: 22,
              color: iconColor,
              shadows: shadows,
            ),
          ),
        ),
      ),
    );
  }
}
