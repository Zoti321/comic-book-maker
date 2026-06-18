import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 缩略图 overflow 菜单项描述（宽屏 [MenuAnchor] / 窄屏 [showMenu] 共用）。
class PageThumbnailMenuAction<T> {
  const PageThumbnailMenuAction({
    required this.value,
    required this.icon,
    required this.label,
    this.foregroundColor,
  });

  final T value;
  final IconData icon;
  final String label;
  final Color? foregroundColor;
}

/// 桌面 hover 显示 [Icons.more_vert] + [MenuAnchor]；窄屏长按 [showMenu]。
class PageThumbnailHoverMenu<T> extends StatefulWidget {
  const PageThumbnailHoverMenu({
    super.key,
    required this.child,
    required this.menuActionsBuilder,
    required this.onSelected,
    this.buttonTop = 4,
    this.buttonRight = 4,
  });

  final Widget child;
  final List<PageThumbnailMenuAction<T>> Function(BuildContext context)
      menuActionsBuilder;
  final ValueChanged<T> onSelected;
  final double buttonTop;
  final double buttonRight;

  static const menuMinWidth = 200.0;
  static const menuItemHeight = 48.0;

  static final overflowIconButtonStyle = IconButton.styleFrom(
    shape: const CircleBorder(),
    visualDensity: VisualDensity.compact,
  );

  static final menuStyle = MenuStyle(
    minimumSize: WidgetStatePropertyAll(Size(menuMinWidth, 0)),
  );

  @override
  State<PageThumbnailHoverMenu<T>> createState() =>
      _PageThumbnailHoverMenuState<T>();
}

class _PageThumbnailHoverMenuState<T> extends State<PageThumbnailHoverMenu<T>> {
  bool _hovering = false;
  final GlobalKey _anchorKey = GlobalKey();
  final MenuController _menuController = MenuController();

  Future<void> _openCompactMenu() async {
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

    final actions = widget.menuActionsBuilder(anchorContext);
    final selected = await showMenu<T>(
      context: anchorContext,
      position: position,
      constraints: const BoxConstraints(
        minWidth: PageThumbnailHoverMenu.menuMinWidth,
      ),
      items: actions
          .map(
            (action) => PopupMenuItem<T>(
              value: action.value,
              height: PageThumbnailHoverMenu.menuItemHeight,
              child: _ThumbnailMenuRow<T>(action: action),
            ),
          )
          .toList(),
    );

    if (selected != null && mounted) {
      widget.onSelected(selected);
    }
  }

  List<Widget> _menuChildren(BuildContext context) {
    final actions = widget.menuActionsBuilder(context);
    return actions
        .map(
          (action) => MenuItemButton(
            style: MenuItemButton.styleFrom(
              minimumSize: const Size(
                PageThumbnailHoverMenu.menuMinWidth,
                PageThumbnailHoverMenu.menuItemHeight,
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            onPressed: () {
              _menuController.close();
              widget.onSelected(action.value);
            },
            child: _ThumbnailMenuRow<T>(action: action),
          ),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final showHoverButton = !isCompact(context);
    final longPress = isCompact(context);

    return KeyedSubtree(
      key: _anchorKey,
      child: MouseRegion(
        onEnter: showHoverButton ? (_) => setState(() => _hovering = true) : null,
        onExit: showHoverButton ? (_) => setState(() => _hovering = false) : null,
        child: GestureDetector(
          onLongPress: longPress ? _openCompactMenu : null,
          behavior: HitTestBehavior.deferToChild,
          child: Stack(
            clipBehavior: Clip.none,
            fit: StackFit.passthrough,
            children: [
              widget.child,
              if (showHoverButton && _hovering)
                Positioned(
                  top: widget.buttonTop,
                  right: widget.buttonRight,
                  child: MenuAnchor(
                    controller: _menuController,
                    style: PageThumbnailHoverMenu.menuStyle,
                    menuChildren: _menuChildren(context),
                    builder: (context, controller, child) {
                      return IconButton(
                        icon: const Icon(Icons.more_vert),
                        tooltip: '更多',
                        style: PageThumbnailHoverMenu.overflowIconButtonStyle,
                        onPressed: () {
                          if (controller.isOpen) {
                            controller.close();
                          } else {
                            controller.open();
                          }
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThumbnailMenuRow<T> extends StatelessWidget {
  const _ThumbnailMenuRow({required this.action});

  final PageThumbnailMenuAction<T> action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = action.foregroundColor ?? scheme.onSurface;

    return Row(
      children: [
        Icon(action.icon, size: 20, color: color),
        const SizedBox(width: AppSpacing.sm),
        Text(action.label, style: TextStyle(color: color)),
      ],
    );
  }
}
