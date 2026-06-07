import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 控制 [AppPopupMenu] 显隐。
class AppPopupMenuController extends ChangeNotifier {
  bool menuIsShowing = false;

  void showMenu() {
    if (menuIsShowing) return;
    menuIsShowing = true;
    notifyListeners();
  }

  void hideMenu() {
    if (!menuIsShowing) return;
    menuIsShowing = false;
    notifyListeners();
  }

  void toggleMenu() {
    if (menuIsShowing) {
      hideMenu();
    } else {
      showMenu();
    }
  }
}

/// [AppPopupMenu] 展开时向子树注入；[AppIconButton] 会读取并保持 hover 打开态。
class AppPopupMenuOpenScope extends InheritedWidget {
  const AppPopupMenuOpenScope({
    super.key,
    required this.isOpen,
    required super.child,
  });

  final bool isOpen;

  static bool maybeIsOpen(BuildContext context) {
    return context
            .dependOnInheritedWidgetOfExactType<AppPopupMenuOpenScope>()
            ?.isOpen ??
        false;
  }

  @override
  bool updateShouldNotify(AppPopupMenuOpenScope oldWidget) =>
      isOpen != oldWidget.isOpen;
}

/// 锚点下方弹出的自绘菜单（左缘对齐按钮左缘、透明遮罩）。
///
/// 锚点控件（如 [AppIconButton]）应在 [onPressed] 中调用
/// [AppPopupMenuController.toggleMenu]。
class AppPopupMenu extends StatefulWidget {
  const AppPopupMenu({
    super.key,
    required this.child,
    required this.menuBuilder,
    this.controller,
    this.verticalMargin = 0,
    this.viewportPadding = 8,
  });

  final Widget child;
  final Widget Function() menuBuilder;
  final AppPopupMenuController? controller;
  final double verticalMargin;
  final double viewportPadding;

  @override
  State<AppPopupMenu> createState() => _AppPopupMenuState();
}

class _AppPopupMenuState extends State<AppPopupMenu> {
  final GlobalKey _anchorKey = GlobalKey();
  late final AppPopupMenuController _controller =
      widget.controller ?? AppPopupMenuController();
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onMenuVisibilityChanged);
  }

  @override
  void dispose() {
    _removeOverlay();
    _controller.removeListener(_onMenuVisibilityChanged);
    super.dispose();
  }

  void _onMenuVisibilityChanged() {
    if (_controller.menuIsShowing) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
    if (mounted) setState(() {});
  }

  void _showOverlay() {
    if (_overlayEntry != null) return;
    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) return;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => _AppPopupMenuOverlay(
        anchorKey: _anchorKey,
        menuBuilder: widget.menuBuilder,
        verticalMargin: widget.verticalMargin,
        viewportPadding: widget.viewportPadding,
        onDismiss: _controller.hideMenu,
      ),
    );
    overlayState.insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  Widget build(BuildContext context) {
    return AppPopupMenuOpenScope(
      isOpen: _controller.menuIsShowing,
      child: KeyedSubtree(
        key: _anchorKey,
        child: widget.child,
      ),
    );
  }
}

class _AppPopupMenuOverlay extends StatefulWidget {
  const _AppPopupMenuOverlay({
    required this.anchorKey,
    required this.menuBuilder,
    required this.verticalMargin,
    required this.viewportPadding,
    required this.onDismiss,
  });

  final GlobalKey anchorKey;
  final Widget Function() menuBuilder;
  final double verticalMargin;
  final double viewportPadding;
  final VoidCallback onDismiss;

  @override
  State<_AppPopupMenuOverlay> createState() => _AppPopupMenuOverlayState();
}

class _AppPopupMenuOverlayState extends State<_AppPopupMenuOverlay> {
  final GlobalKey _menuKey = GlobalKey();
  Offset? _menuOffset;
  var _dismissGuard = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _positionMenu();
      WidgetsBinding.instance.addPostFrameCallback((_) => _positionMenu());
    });
  }

  Rect? _globalRect(GlobalKey key, RenderBox overlayBox) {
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final topLeft = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    return topLeft & box.size;
  }

  void _positionMenu() {
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlayBox == null || !mounted) return;

    final anchorRect = _globalRect(widget.anchorKey, overlayBox);
    final menuRect = _globalRect(_menuKey, overlayBox);
    if (anchorRect == null || menuRect == null) return;

    final viewport = Offset.zero & overlayBox.size;
    final pad = widget.viewportPadding;
    final safe = Rect.fromLTRB(
      pad,
      pad,
      viewport.width - pad,
      viewport.height - pad,
    );

    var left = anchorRect.left;
    var top = anchorRect.bottom + widget.verticalMargin;

    final spaceBelow = safe.bottom - top;
    final spaceAbove = anchorRect.top - safe.top;
    if (menuRect.height > spaceBelow && menuRect.height <= spaceAbove) {
      top = anchorRect.top - widget.verticalMargin - menuRect.height;
    }

    if (left + menuRect.width > safe.right) {
      left = safe.right - menuRect.width;
    }
    if (left < safe.left) {
      left = safe.left;
    }
    if (top + menuRect.height > safe.bottom) {
      top = safe.bottom - menuRect.height;
    }
    if (top < safe.top) {
      top = safe.top;
    }

    final next = Offset(left, top);
    if (_menuOffset != next) {
      setState(() => _menuOffset = next);
    }
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (_dismissGuard) return;

    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    if (overlayBox == null) return;

    final position = event.position;
    final menuRect = _globalRect(_menuKey, overlayBox);
    if (menuRect?.contains(position) ?? false) return;

    widget.onDismiss();

    final anchorRect = _globalRect(widget.anchorKey, overlayBox);
    if (anchorRect?.contains(position) ?? false) {
      _dismissGuard = true;
      Future<void>.delayed(const Duration(milliseconds: 300)).then((_) {
        _dismissGuard = false;
      });
    }
  }

  Offset? _anchorAlignedOffset(RenderBox overlayBox) {
    final anchorRect = _globalRect(widget.anchorKey, overlayBox);
    if (anchorRect == null) return null;
    return Offset(
      anchorRect.left,
      anchorRect.bottom + widget.verticalMargin,
    );
  }

  @override
  Widget build(BuildContext context) {
    final overlayBox =
        Overlay.of(context).context.findRenderObject() as RenderBox?;
    final menuOffset = _menuOffset ??
        (overlayBox == null ? null : _anchorAlignedOffset(overlayBox));

    return Shortcuts(
      shortcuts: const {
        SingleActivator(LogicalKeyboardKey.escape): _DismissPopupMenuIntent(),
      },
      child: Actions(
        actions: {
          _DismissPopupMenuIntent: CallbackAction<_DismissPopupMenuIntent>(
            onInvoke: (_) {
              widget.onDismiss();
              return null;
            },
          ),
        },
        child: Focus(
          autofocus: true,
          child: Stack(
            children: [
              Positioned.fill(
                child: Listener(
                  behavior: HitTestBehavior.translucent,
                  onPointerDown: _handlePointerDown,
                  child: const ColoredBox(color: Colors.transparent),
                ),
              ),
              Positioned(
                left: menuOffset?.dx ?? 0,
                top: menuOffset?.dy ?? 0,
                child: KeyedSubtree(
                  key: _menuKey,
                  child: widget.menuBuilder(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DismissPopupMenuIntent extends Intent {
  const _DismissPopupMenuIntent();
}
