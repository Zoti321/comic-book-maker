import 'package:comic_book_maker/ui/core/theme/app_motion.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// Stagger 入场 slide 位移（像素）。
abstract final class AppMotionStagger {
  static const slidePixels = 8.0;
}

extension AppMotionStaggerEntrance on Widget {
  /// 列表/网格项 stagger 入场；[play] 为 false 或动效关闭时不包装动画。
  Widget staggerEntrance(
    BuildContext context, {
    required int index,
    required bool play,
  }) {
    if (!play || !AppMotion.enabled(context)) {
      return this;
    }

    final duration = AppMotion.duration(context, AppDurations.motionNormal);
    final delay = AppMotion.staggerDelayForIndex(context, index);

    return animate()
        .fadeIn(
          delay: delay,
          duration: duration,
          curve: AppCurves.enter,
        )
        .moveY(
          delay: delay,
          begin: AppMotionStagger.slidePixels,
          end: 0,
          duration: duration,
          curve: AppCurves.enter,
        );
  }

  /// 单段 fade 入场（空态副文案等）。
  Widget fadeEntrance(
    BuildContext context, {
    Duration? delay,
    Duration? duration,
  }) {
    if (!AppMotion.enabled(context)) {
      return this;
    }

    return animate().fadeIn(
      delay: delay ?? Duration.zero,
      duration: duration ?? AppMotion.duration(context, AppDurations.motionNormal),
      curve: AppCurves.enter,
    );
  }
}
