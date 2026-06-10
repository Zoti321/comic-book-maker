import 'package:flutter/material.dart';

/// 响应式断点宽度（与 [breakpointOf] 一致）。
abstract final class AppBreakpointWidths {
  static const medium = 720.0;
  static const expanded = 1200.0;
}

/// 布局常量（侧栏宽度、内容区最大宽度等）。
abstract final class AppLayout {
  static const sidebarWidth = 256.0;
  static const contentMaxWidth = 1280.0;
}

/// 间距、圆角、排版等设计 token（与 [AppTheme.light] 配套）。
abstract final class AppSpacing {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;

  static EdgeInsets pagePadding(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width >= AppBreakpointWidths.expanded) {
      return const EdgeInsets.all(xl);
    }
    if (width >= AppBreakpointWidths.medium) {
      return const EdgeInsets.all(lg);
    }
    return const EdgeInsets.all(md);
  }
}

abstract final class AppRadius {
  static const sm = 4.0;
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

/// 阴影 token（贴顶栏、浮层等共用数值，按场景选用）。
abstract final class AppElevation {
  /// [PageHeader] 底部轻阴影，替代底部分割线以制造层次。
  static const headerShadow = BoxShadow(
    color: Color(0x12000000),
    blurRadius: 6,
    offset: Offset(0, 2),
  );
}
