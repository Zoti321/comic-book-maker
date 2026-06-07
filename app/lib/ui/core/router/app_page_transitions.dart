import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 全屏路由页面过渡（漫画库/设置 ↔ 编辑页等）。
abstract final class AppPageTransitions {
  static const fadeDuration = Duration(milliseconds: 200);
  static const fadeCurve = Curves.easeInOut;
}

/// 对称淡入淡出：push 淡入，pop 淡出；桌面与移动端通用。
CustomTransitionPage<T> fadeTransitionPage<T>({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: AppPageTransitions.fadeDuration,
    reverseTransitionDuration: AppPageTransitions.fadeDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: AppPageTransitions.fadeCurve,
          reverseCurve: AppPageTransitions.fadeCurve,
        ),
        child: child,
      );
    },
  );
}
