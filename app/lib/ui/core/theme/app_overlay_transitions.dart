import 'package:comic_book_maker/ui/core/theme/app_motion.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Dialog / BottomSheet 浮层 scale+fade 过渡参数。
abstract final class AppMotionOverlay {
  static const scaleBegin = 0.96;
}

/// Dialog 与 BottomSheet 统一入场/退场（scale + fade）。
abstract final class AppOverlayTransitions {
  static Duration transitionDuration(BuildContext context) {
    return AppMotion.duration(context, AppDurations.motionNormal);
  }

  static Widget dialogTransitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _scaleFadeTransition(
      context: context,
      animation: animation,
      alignment: Alignment.center,
      child: child,
    );
  }

  static Widget sheetTransitionBuilder(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return _scaleFadeTransition(
      context: context,
      animation: animation,
      alignment: Alignment.bottomCenter,
      child: child,
    );
  }

  static Widget _scaleFadeTransition({
    required BuildContext context,
    required Animation<double> animation,
    required Alignment alignment,
    required Widget child,
  }) {
    if (!AppMotion.enabled(context)) {
      return child;
    }

    final curved = AppMotion.curvedAnimation(
      context,
      parent: animation,
      curve: AppCurves.enter,
      reverseCurve: AppCurves.exit,
    );
    final scale = Tween<double>(
      begin: AppMotionOverlay.scaleBegin,
      end: 1,
    ).animate(curved);

    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        alignment: alignment,
        scale: scale,
        child: child,
      ),
    );
  }
}
