import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

export 'app_motion_effects.dart';

/// 全 app 动画门禁与时长/曲线 helper（尊重 [MediaQuery.disableAnimations]）。
abstract final class AppMotion {
  static bool enabled(BuildContext context) {
    return !MediaQuery.disableAnimationsOf(context);
  }

  /// [whenEnabled] 在动效开启时返回；否则 [Duration.zero]。
  static Duration duration(BuildContext context, Duration whenEnabled) {
    return enabled(context) ? whenEnabled : Duration.zero;
  }

  static Duration pageTransitionDuration(BuildContext context) {
    return duration(context, AppDurations.pageTransition);
  }

  static Duration staggerDelayForIndex(BuildContext context, int index) {
    if (!enabled(context) || index <= 0) {
      return Duration.zero;
    }
    return Duration(
      milliseconds: AppDurations.staggerItemDelay.inMilliseconds * index,
    );
  }

  static Animation<double> curvedAnimation(
    BuildContext context, {
    required Animation<double> parent,
    Curve curve = AppCurves.standard,
    Curve? reverseCurve,
  }) {
    return CurvedAnimation(
      parent: parent,
      curve: curve,
      reverseCurve: reverseCurve ?? curve,
    );
  }
}
