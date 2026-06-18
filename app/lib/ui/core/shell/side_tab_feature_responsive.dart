import 'dart:async';

import 'package:comic_book_maker/ui/core/design_system/app_dialog.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/router/app_navigator.dart';
import 'package:comic_book_maker/ui/core/router/app_page_transitions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// [Navigator.pop] / [GoRouter.pop] 在 Dialog ↔ 全页变形时返回的哨兵，不表示用户取消。
class SideTabFeatureMorphMarker {
  const SideTabFeatureMorphMarker();
}

const sideTabFeatureMorphMarker = SideTabFeatureMorphMarker();

/// 变形目标（由 [SideTabFeatureCoordinator.scheduleMorph] 在 pop 前登记）。
enum SideTabMorphTarget { dialog, page }

/// 侧栏 Tab 功能（新建项目、项目属性）打开 / 变形会话的共享状态。
class SideTabFeatureCoordinator<T> {
  SideTabFeatureCoordinator({required this.compactPageLocation});

  final String compactPageLocation;

  final _completer = Completer<T?>();
  var tabIndex = 0;
  var _morphing = false;
  SideTabMorphTarget? _pendingMorph;
  final morphingListenable = ValueNotifier(false);
  VoidCallback? popCompactPage;

  Future<T?> get result => _completer.future;
  bool get isCompleted => _completer.isCompleted;
  bool get isMorphing => _morphing;

  void setMorphing(bool value) {
    _morphing = value;
    morphingListenable.value = value;
  }

  void scheduleMorph(SideTabMorphTarget target) => _pendingMorph = target;

  SideTabMorphTarget? takePendingMorph() {
    final target = _pendingMorph;
    _pendingMorph = null;
    return target;
  }

  void complete(T? value) {
    if (!_completer.isCompleted) {
      _completer.complete(value);
    }
  }

  static bool isMorphResult(Object? value) => value is SideTabFeatureMorphMarker;

  static SideTabFeatureCoordinator<T>? of<T>(BuildContext context) {
    if (GoRouter.maybeOf(context) == null) return null;
    final extra = GoRouterState.of(context).extra;
    return extra is SideTabFeatureCoordinator<T> ? extra : null;
  }
}

/// 打开 / 关闭侧栏 Tab 功能时重置或清理关联状态（如新建项目 session）。
class SideTabFeatureSessionHooks {
  const SideTabFeatureSessionHooks({
    required this.onOpen,
    required this.onClose,
  });

  final void Function(ProviderContainer container) onOpen;
  final void Function(ProviderContainer container) onClose;
}

/// 窄屏全页形态下由 [openSideTabFeature] 挂载：在 DesktopShell 断点重建导致
/// [SideTabFeaturePagePresentation] 子树销毁时，仍能可靠触发全页 → 对话框变形。
class _PageToDialogMorphObserver with WidgetsBindingObserver {
  _PageToDialogMorphObserver({required this.coordinator});

  final SideTabFeatureCoordinator<dynamic> coordinator;
  var _wasCompact = true;
  var _morphing = false;

  void attach() {
    final ctx = rootNavigatorKey.currentContext;
    _wasCompact =
        ctx != null && ctx.mounted && isCompactForSideTabMorph(ctx);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _evaluate());
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      _wasCompact = isCompactForSideTabMorph(ctx);
    }
  }

  @override
  void didChangeMetrics() => _evaluate();

  Future<void> _evaluate() async {
    if (_morphing || coordinator.isMorphing || coordinator.isCompleted) {
      return;
    }
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    final compact = isCompactForSideTabMorph(ctx);
    final shouldMorph = _wasCompact && !compact;
    _wasCompact = compact;
    if (!shouldMorph) return;

    _morphing = true;
    coordinator.scheduleMorph(SideTabMorphTarget.dialog);
    coordinator.setMorphing(true);
    // 须在 DesktopShell 断点重建前立刻 pop；延迟后再 pop 会因路由栈失效而无效。
    final popPage = coordinator.popCompactPage;
    if (popPage != null) {
      popPage();
    } else {
      final popContext = rootNavigatorKey.currentContext;
      if (popContext != null && popContext.mounted) {
        final router = GoRouter.of(popContext);
        if (router.canPop()) router.pop();
      }
    }
    await Future<void>.delayed(AppPageTransitions.fadeDuration);
    coordinator.setMorphing(false);
    _morphing = false;
  }
}

enum _SideTabPresentationMode { dialog, page }

BuildContext _hostContext(BuildContext fallback) {
  final root = rootNavigatorKey.currentContext;
  if (root != null && root.mounted) return root;
  return fallback;
}

Future<void> _waitForPresentationSettle() async {
  await WidgetsBinding.instance.endOfFrame;
}

bool _shouldMorphTo(
  SideTabFeatureCoordinator<dynamic> coordinator,
  SideTabMorphTarget target,
  Object? popResult,
) {
  return coordinator.takePendingMorph() == target ||
      (target == SideTabMorphTarget.page &&
          SideTabFeatureCoordinator.isMorphResult(popResult));
}

/// 统一入口：按断点选择初始形态，并在窗口缩放时双向变形（200ms 交叉淡入淡出）。
Future<T?> openSideTabFeature<T>({
  required BuildContext context,
  required Widget Function(
    BuildContext dialogContext,
    SideTabFeatureCoordinator<T> coordinator,
  )
      dialogBuilder,
  required String compactPageLocation,
  SideTabFeatureSessionHooks? session,
}) async {
  final container = ProviderScope.containerOf(context);
  session?.onOpen(container);

  final coordinator = SideTabFeatureCoordinator<T>(
    compactPageLocation: compactPageLocation,
  );

  try {
    var mode = isCompact(context)
        ? _SideTabPresentationMode.page
        : _SideTabPresentationMode.dialog;

    T? result;
    while (!coordinator.isCompleted) {
      if (mode == _SideTabPresentationMode.dialog) {
        final hostContext = _hostContext(context);
        if (!hostContext.mounted) break;

        final popResult = await _showMorphableDialog(
          context: hostContext,
          coordinator: coordinator,
          dialogBuilder: dialogBuilder,
        );
        if (coordinator.isCompleted) break;
        if (_shouldMorphTo(coordinator, SideTabMorphTarget.page, popResult)) {
          await _waitForPresentationSettle();
          mode = _SideTabPresentationMode.page;
          continue;
        }
        result = popResult as T?;
        coordinator.complete(result);
        break;
      } else {
        final hostContext = _hostContext(context);
        if (!hostContext.mounted) break;

        final morphObserver = desktopWindowConfig.chromeEnabled
            ? _PageToDialogMorphObserver(coordinator: coordinator)
            : null;
        morphObserver?.attach();
        Object? popResult;
        try {
          popResult = await GoRouter.of(hostContext).push<Object?>(
            coordinator.compactPageLocation,
            extra: coordinator,
          );
        } finally {
          morphObserver?.detach();
        }
        if (coordinator.isCompleted) break;
        if (_shouldMorphTo(coordinator, SideTabMorphTarget.dialog, popResult)) {
          await _waitForPresentationSettle();
          mode = _SideTabPresentationMode.dialog;
          continue;
        }
        result = popResult as T?;
        coordinator.complete(result);
        break;
      }
    }

    return coordinator.isCompleted ? await coordinator.result : result;
  } finally {
    session?.onClose(container);
  }
}

Future<Object?> _showMorphableDialog<T>({
  required BuildContext context,
  required SideTabFeatureCoordinator<T> coordinator,
  required Widget Function(
    BuildContext dialogContext,
    SideTabFeatureCoordinator<T> coordinator,
  )
      dialogBuilder,
}) {
  return showDialog<Object?>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => SideTabFeatureDialogPresentation(
      coordinator: coordinator,
      child: AppFeatureDialogFrame(
        child: dialogBuilder(dialogContext, coordinator),
      ),
    ),
  );
}

/// 监听窗口 / 布局断点变化；由 Dialog / Page presentation 持有。
class _SideTabBreakpointListener with WidgetsBindingObserver {
  _SideTabBreakpointListener({
    required this.isMounted,
    required this.context,
    required this.coordinator,
    required this.expectCompact,
    required this.onShrinkToCompact,
    required this.onGrowToWide,
  });

  final bool Function() isMounted;
  final BuildContext Function() context;
  final SideTabFeatureCoordinator<dynamic> coordinator;
  final bool expectCompact;
  final Future<void> Function() onShrinkToCompact;
  final Future<void> Function() onGrowToWide;

  bool? _wasCompact;

  void attach() {
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => evaluate());
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeMetrics() => evaluate();

  void onDependenciesChanged() => evaluate();

  void evaluate() {
    if (!isMounted()) return;
    if (coordinator.isMorphing || coordinator.isCompleted) return;

    final compact = isCompactForSideTabMorph(context());
    if (_wasCompact == null) {
      _wasCompact = compact;
      if (compact != expectCompact) {
        if (compact) {
          onShrinkToCompact();
        } else {
          onGrowToWide();
        }
      }
      return;
    }

    if (_wasCompact! && !compact) {
      onGrowToWide();
    } else if (!_wasCompact! && compact) {
      onShrinkToCompact();
    }
    _wasCompact = compact;
  }
}

/// 宽屏对话框形态：监听断点，缩窗时淡出并 morph 到全页。
class SideTabFeatureDialogPresentation extends StatefulWidget {
  const SideTabFeatureDialogPresentation({
    super.key,
    required this.coordinator,
    required this.child,
  });

  final SideTabFeatureCoordinator<dynamic> coordinator;
  final Widget child;

  @override
  State<SideTabFeatureDialogPresentation> createState() =>
      _SideTabFeatureDialogPresentationState();
}

class _SideTabFeatureDialogPresentationState
    extends State<SideTabFeatureDialogPresentation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  late final _SideTabBreakpointListener _breakpointListener;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: AppPageTransitions.fadeDuration,
      value: 1,
    );
    _breakpointListener = _SideTabBreakpointListener(
      isMounted: () => mounted,
      context: () => context,
      coordinator: widget.coordinator,
      expectCompact: false,
      onShrinkToCompact: _morphToPage,
      onGrowToWide: () async {},
    );
    _breakpointListener.attach();
  }

  @override
  void dispose() {
    widget.coordinator.setMorphing(false);
    _breakpointListener.detach();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _breakpointListener.onDependenciesChanged();
  }

  Future<void> _morphToPage() async {
    if (widget.coordinator.isMorphing) return;
    widget.coordinator.scheduleMorph(SideTabMorphTarget.page);
    widget.coordinator.setMorphing(true);
    await _fadeController.reverse();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(sideTabFeatureMorphMarker);
    widget.coordinator.setMorphing(false);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _breakpointListener.evaluate();
        });
        return FadeTransition(
          opacity: _fadeController,
          child: widget.child,
        );
      },
    );
  }
}

/// 窄屏全页形态：监听断点，拉宽时淡出并 morph 到对话框。
class SideTabFeaturePagePresentation extends StatefulWidget {
  const SideTabFeaturePagePresentation({
    super.key,
    required this.coordinator,
    required this.child,
  });

  final SideTabFeatureCoordinator<dynamic> coordinator;
  final Widget child;

  @override
  State<SideTabFeaturePagePresentation> createState() =>
      _SideTabFeaturePagePresentationState();
}

class _SideTabFeaturePagePresentationState
    extends State<SideTabFeaturePagePresentation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;
  _SideTabBreakpointListener? _breakpointListener;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: AppPageTransitions.fadeDuration,
      value: 1,
    );
    if (!desktopWindowConfig.chromeEnabled) {
      _breakpointListener = _SideTabBreakpointListener(
        isMounted: () => mounted,
        context: () => context,
        coordinator: widget.coordinator,
        expectCompact: true,
        onShrinkToCompact: () async {},
        onGrowToWide: _morphToDialog,
      )..attach();
    }
  }

  @override
  void dispose() {
    widget.coordinator.setMorphing(false);
    _breakpointListener?.detach();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _breakpointListener?.onDependenciesChanged();
  }

  Future<void> _morphToDialog() async {
    if (widget.coordinator.isMorphing) return;
    widget.coordinator.scheduleMorph(SideTabMorphTarget.dialog);
    widget.coordinator.setMorphing(true);
    await _fadeController.reverse();
    if (!mounted) return;
    context.pop();
    widget.coordinator.setMorphing(false);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.coordinator.morphingListenable,
      builder: (context, _) {
        if (widget.coordinator.isMorphing &&
            _fadeController.status != AnimationStatus.reverse &&
            _fadeController.status != AnimationStatus.dismissed) {
          _fadeController.reverse();
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _breakpointListener?.evaluate();
            });
            return FadeTransition(
              opacity: _fadeController,
              child: widget.child,
            );
          },
        );
      },
    );
  }
}
