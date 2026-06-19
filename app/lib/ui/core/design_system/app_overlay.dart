import 'package:comic_book_maker/ui/core/theme/app_overlay_transitions.dart';
import 'package:flutter/material.dart';

/// 统一 scale+fade 入场的 Dialog（AlertDialog、AppDialog、SideTab 壳等）。
Future<T?> showAppOverlayDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  Color? barrierColor,
  String? barrierLabel,
  RouteSettings? routeSettings,
  Offset? anchorPoint,
  bool? requestFocus,
}) {
  final theme = Theme.of(context);
  final localizations = MaterialLocalizations.of(context);

  return showGeneralDialog<T>(
    context: context,
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      return builder(dialogContext);
    },
    transitionBuilder: AppOverlayTransitions.dialogTransitionBuilder,
    transitionDuration: AppOverlayTransitions.transitionDuration(context),
    barrierDismissible: barrierDismissible,
    barrierColor: barrierColor ??
        theme.dialogTheme.barrierColor ??
        Colors.black54,
    barrierLabel: barrierLabel ?? localizations.modalBarrierDismissLabel,
    useRootNavigator: useRootNavigator,
    routeSettings: routeSettings,
    anchorPoint: anchorPoint,
    requestFocus: requestFocus,
  );
}

/// [RawDialogRoute] 路径的统一 scale+fade（阻塞 loading 等需 push/removeRoute 的场景）。
RawDialogRoute<T> appOverlayDialogRoute<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  bool useSafeArea = true,
  RouteSettings? settings,
  Offset? anchorPoint,
}) {
  final duration = AppOverlayTransitions.transitionDuration(context);
  final localizations = MaterialLocalizations.of(context);

  return RawDialogRoute<T>(
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      final pageChild = Builder(builder: builder);
      return useSafeArea ? SafeArea(child: pageChild) : pageChild;
    },
    barrierDismissible: barrierDismissible,
    barrierLabel: localizations.modalBarrierDismissLabel,
    barrierColor: Theme.of(context).dialogTheme.barrierColor ?? Colors.black54,
    transitionDuration: duration,
    transitionBuilder: AppOverlayTransitions.dialogTransitionBuilder,
    settings: settings,
    anchorPoint: anchorPoint,
  );
}
