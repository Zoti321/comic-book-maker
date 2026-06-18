import 'package:flutter/material.dart';

/// 响应式断点宽度（与 [breakpointOf] 一致）。
abstract final class AppBreakpointWidths {
  static const medium = 720.0;
  static const expanded = 1200.0;
}

/// 布局常量（侧栏宽度、内容区最大宽度等）。
abstract final class AppLayout {
  static const sidebarWidth = 80.0;
  static const contentMaxWidth = 1280.0;

  /// 侧栏 Tab 功能对话框内左侧导航宽度。
  static const sideTabDialogNavWidth = 112.0;

  /// 侧栏 Tab 对话框内容区最小高度（M3 内容驱动 + 下限）。
  static const sideTabDialogMinHeight = 320.0;

  /// 对话框相对视口上下的总留白（用于 [maxHeight]）。
  static const dialogViewportMargin = 48.0;
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

  /// 壳层内容 inset 面板左缘圆角。
  static const shellContent = 28.0;

  /// 导航图标胶囊全圆角（极大半径即可）。
  static const pill = 999.0;

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

  /// M3 Outlined 表单字段目标高度（`TextFormField` / `AppDropdownMenu`）。
  static const controlHeightForm = 56.0;
}

/// 时长 token（动画、tooltip 等）。
abstract final class AppDurations {
  /// 全局 tooltip 悬停后出现延迟（见 [AppTheme.light] `tooltipTheme`）。
  static const tooltipWait = Duration(seconds: 1);
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
