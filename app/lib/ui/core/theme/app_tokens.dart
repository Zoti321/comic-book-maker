import 'package:flutter/material.dart';

/// 间距、圆角、排版等设计 token（与 [AppTheme.light] 配套）。
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= 1200) return const EdgeInsets.all(xl);
    if (width >= 720) return const EdgeInsets.all(lg);
    return const EdgeInsets.all(md);
  }
}

abstract final class AppRadius {
  static const sm = 6.0;
  static const md = 8.0;
  static const lg = 12.0;
  static const xl = 16.0;

  static BorderRadius get smBorder => BorderRadius.circular(sm);
  static BorderRadius get mdBorder => BorderRadius.circular(md);
  static BorderRadius get lgBorder => BorderRadius.circular(lg);
}

abstract final class AppTypography {
  static const titleLargeSize = 20.0;
  static const titleMediumSize = 16.0;
  static const bodySize = 14.0;
  static const labelSize = 12.0;

  static const controlHeight = 36.0;
  static const controlHeightCompact = 32.0;
}
