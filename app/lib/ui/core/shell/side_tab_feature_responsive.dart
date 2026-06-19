import 'dart:async';

import 'package:comic_book_maker/ui/core/design_system/app_dialog.dart';
import 'package:comic_book_maker/ui/core/design_system/app_overlay.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/router/app_navigator.dart';
import 'package:comic_book_maker/ui/core/router/app_page_transitions.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_feature_coordinator.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_feature_session.dart';
import 'package:comic_book_maker/ui/core/theme/app_motion.dart';
import 'package:comic_book_maker/ui/core/theme/app_overlay_transitions.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

export 'side_tab_feature_coordinator.dart';
export 'side_tab_feature_session.dart';

/// 单次 [openSideTabFeature] 会话内的变形引擎：断点策略、pop 时机、淡出协调。
class SideTabMorphSession
    with WidgetsBindingObserver
    implements SideTabMorphSessionHandle {
  SideTabMorphSession(this.coordinator);

  final SideTabFeatureCoordinator<dynamic> coordinator;

  SideTabMorphForm? _form;
  bool? _wasCompact;
  var _running = false;

  VoidCallback? _popPage;
  Future<void> Function()? _popDialog;

  @override
  void bindPagePop(VoidCallback pop) => _popPage = pop;

  @override
  void bindDialogPop(Future<void> Function() pop) => _popDialog = pop;

  @override
  void watch(SideTabMorphForm form) {
    _form = form;
    final ctx = rootNavigatorKey.currentContext;
    _wasCompact =
        ctx != null && ctx.mounted && isCompactForSideTabMorph(ctx);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => evaluate());
  }

  @override
  void unwatch() {
    WidgetsBinding.instance.removeObserver(this);
    final ctx = rootNavigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      _wasCompact = isCompactForSideTabMorph(ctx);
    }
    _form = null;
    _popPage = null;
    _popDialog = null;
  }

  @override
  void didChangeMetrics() => evaluate();

  @override
  void evaluate() {
    final form = _form;
    if (form == null ||
        _running ||
        coordinator.isMorphing ||
        coordinator.isCompleted) {
      return;
    }

    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;

    final compact = isCompactForSideTabMorph(ctx);
    final expectCompact = form == SideTabMorphForm.page;

    if (_wasCompact == null) {
      _wasCompact = compact;
      if (compact != expectCompact) {
        unawaited(_runMorph(
          compact ? SideTabMorphTarget.page : SideTabMorphTarget.dialog,
        ));
      }
      return;
    }

    if (_wasCompact! && !compact && form == SideTabMorphForm.page) {
      unawaited(_runMorph(SideTabMorphTarget.dialog));
    } else if (!_wasCompact! && compact && form == SideTabMorphForm.dialog) {
      unawaited(_runMorph(SideTabMorphTarget.page));
    }
    _wasCompact = compact;
  }

  Future<void> _runMorph(SideTabMorphTarget target) async {
    if (_running || coordinator.isMorphing || coordinator.isCompleted) return;
    _running = true;
    coordinator.scheduleMorph(target);
    coordinator.setMorphing(true);

    if (target == SideTabMorphTarget.dialog) {
      // 须在 DesktopShell 断点重建前立刻 pop；延迟后再 pop 会因路由栈失效而无效。
      if (_popPage != null) {
        _popPage!();
      } else {
        _fallbackPopPage();
      }
      await Future<void>.delayed(_morphSettleDuration());
    } else {
      // dialog → page：与上对称，先 pop 再延迟；overlay 路由自行 scale+fade 退场。
      // 不可先 await fadeOut——缩放触发的壳层重建会使 Presentation 卸载，bind 的 pop 静默失效。
      await (_popDialog?.call() ?? _fallbackPopDialog());
      await Future<void>.delayed(_morphSettleDuration());
    }

    coordinator.setMorphing(false);
    _running = false;
  }

  void _fallbackPopPage() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    final router = GoRouter.of(ctx);
    if (router.canPop()) router.pop();
  }

  Future<void> _fallbackPopDialog() async {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) return;
    Navigator.of(ctx, rootNavigator: true).pop(sideTabFeatureMorphMarker);
  }

  Duration _morphSettleDuration() {
    final ctx = rootNavigatorKey.currentContext;
    if (ctx == null || !ctx.mounted) {
      return AppPageTransitions.fadeDuration;
    }
    final overlay = AppOverlayTransitions.transitionDuration(ctx);
    final page = AppMotion.pageTransitionDuration(ctx);
    return overlay > page ? overlay : page;
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
  SideTabFeatureSession? session,
}) async {
  final container = ProviderScope.containerOf(context);
  session?.onOpen(container);

  final coordinator = SideTabFeatureCoordinator<T>(
    compactPageLocation: compactPageLocation,
  );
  final morphSession = SideTabMorphSession(coordinator);
  coordinator.morphSession = morphSession;
  container.read(sideTabMorphCoordinatorProvider.notifier).bind(coordinator);

  try {
    var mode = isCompact(context)
        ? _SideTabPresentationMode.page
        : _SideTabPresentationMode.dialog;

    T? result;
    while (!coordinator.isCompleted) {
      if (mode == _SideTabPresentationMode.dialog) {
        final hostContext = _hostContext(context);
        if (!hostContext.mounted) break;

        morphSession.watch(SideTabMorphForm.dialog);
        Object? popResult;
        try {
          popResult = await _showMorphableDialog(
            context: hostContext,
            coordinator: coordinator,
            dialogBuilder: dialogBuilder,
          );
        } finally {
          morphSession.unwatch();
        }
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

        morphSession.watch(SideTabMorphForm.page);
        Object? popResult;
        try {
          popResult = await GoRouter.of(hostContext).push<Object?>(
            coordinator.compactPageLocation,
          );
        } finally {
          morphSession.unwatch();
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
    coordinator.morphSession = null;
    container.read(sideTabMorphCoordinatorProvider.notifier).clear();
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
  return showAppOverlayDialog<Object?>(
    context: context,
    useRootNavigator: true,
    builder: (dialogContext) => AppFeatureDialogFrame(
      child: dialogBuilder(dialogContext, coordinator),
    ),
  );
}

/// 变形淡出包装；断点监听由 [SideTabMorphSession] 负责。
class SideTabMorphPresentation extends StatefulWidget {
  const SideTabMorphPresentation({
    super.key,
    required this.coordinator,
    required this.form,
    required this.child,
  });

  final SideTabFeatureCoordinator<dynamic> coordinator;
  final SideTabMorphForm form;
  final Widget child;

  @override
  State<SideTabMorphPresentation> createState() =>
      _SideTabMorphPresentationState();
}

class _SideTabMorphPresentationState extends State<SideTabMorphPresentation>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: AppPageTransitions.fadeDuration,
      value: 1,
    );
    widget.coordinator.morphingListenable.addListener(_onMorphingChanged);
    _bindPopToSession();
  }

  @override
  void dispose() {
    widget.coordinator.morphingListenable.removeListener(_onMorphingChanged);
    _fadeController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    widget.coordinator.morphSession?.evaluate();
  }

  void _onMorphingChanged() {
    if (widget.form != SideTabMorphForm.page) return;
    if (!widget.coordinator.isMorphing) return;
    if (_fadeController.status == AnimationStatus.reverse ||
        _fadeController.status == AnimationStatus.dismissed) {
      return;
    }
    _fadeController.reverse();
  }

  void _bindPopToSession() {
    final session = widget.coordinator.morphSession;
    if (session == null) return;

    if (widget.form == SideTabMorphForm.page) {
      session.bindPagePop(() {
        if (!mounted) return;
        context.pop();
      });
    } else {
      session.bindDialogPop(() async {
        final ctx = rootNavigatorKey.currentContext;
        if (ctx == null || !ctx.mounted) return;
        Navigator.of(ctx, rootNavigator: true)
            .pop(sideTabFeatureMorphMarker);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.coordinator.morphSession?.evaluate();
    });
    return FadeTransition(
      opacity: _fadeController,
      child: widget.child,
    );
  }
}
