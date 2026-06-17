import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 缩略图网格弹出菜单行。
class PageThumbnailMenuRow extends StatelessWidget {
  const PageThumbnailMenuRow({
    super.key,
    required this.icon,
    required this.label,
    this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final Color? foregroundColor;

  static const menuItemHeight = 28.0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = foregroundColor ?? scheme.onSurface;
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          color: color,
        );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(label, style: textStyle),
        ],
      ),
    );
  }
}

/// 桌面悬停显示 ⋮；移动端长按弹出菜单。
class PageThumbnailHoverMenu<T> extends StatefulWidget {
  const PageThumbnailHoverMenu({
    super.key,
    required this.child,
    required this.menuItemsBuilder,
    required this.onSelected,
    this.buttonTop = 6,
    this.buttonRight = 6,
    this.menuButtonBackgroundColor,
    this.menuButtonIconColor,
  });

  final Widget child;
  final List<PopupMenuEntry<T>> Function(BuildContext context) menuItemsBuilder;
  final ValueChanged<T> onSelected;
  final double buttonTop;
  final double buttonRight;
  final Color? menuButtonBackgroundColor;
  final Color? menuButtonIconColor;

  @override
  State<PageThumbnailHoverMenu<T>> createState() =>
      _PageThumbnailHoverMenuState<T>();
}

class _PageThumbnailHoverMenuState<T> extends State<PageThumbnailHoverMenu<T>> {
  bool _hovering = false;
  final GlobalKey _anchorKey = GlobalKey();
  BuildContext? _menuThemeContext;

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
      items: widget.menuItemsBuilder(anchorContext),
    );

    if (selected != null && mounted) {
      widget.onSelected(selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showHover = !isCompact(context);
    final longPress = isCompact(context);
    final scheme = Theme.of(context).colorScheme;
    final iconColor = widget.menuButtonIconColor ?? scheme.onSurface;
    final bg = widget.menuButtonBackgroundColor;

    return Theme(
      data: Theme.of(context).copyWith(
        popupMenuTheme: Theme.of(context).popupMenuTheme.copyWith(
              color: scheme.surface,
              surfaceTintColor: Colors.transparent,
              textStyle: Theme.of(context).textTheme.bodySmall,
            ),
      ),
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
                        child: Material(
                          type: MaterialType.transparency,
                          shape: const CircleBorder(),
                          clipBehavior: Clip.antiAlias,
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: _openMenu,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: bg,
                                border: bg != null
                                    ? Border.all(
                                        color: scheme.outline.withValues(
                                          alpha: 0.8,
                                        ),
                                      )
                                    : null,
                                boxShadow: bg != null
                                    ? [
                                        BoxShadow(
                                          color: scheme.shadow.withValues(
                                            alpha: 0.12,
                                          ),
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
