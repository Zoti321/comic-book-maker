import 'package:comic_book_maker/ui/core/theme/app_motion.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 全屏路由页面过渡（漫画库/设置 ↔ 编辑页等）。
abstract final class AppPageTransitions {
  static Duration get fadeDuration => AppDurations.pageTransition;

  static Curve get fadeCurve => AppCurves.standard;
}

/// 对称淡入淡出：push 淡入，pop 淡出；桌面与移动端通用。
CustomTransitionPage<T> fadeTransitionPage<T>({
  required BuildContext context,
  required LocalKey key,
  required Widget child,
}) {
  final transitionDuration = AppMotion.pageTransitionDuration(context);

  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: transitionDuration,
    reverseTransitionDuration: transitionDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: AppMotion.curvedAnimation(
          context,
          parent: animation,
          curve: AppCurves.standard,
        ),
        child: child,
      );
    },
  );
}
