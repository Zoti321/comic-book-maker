import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 应用壳层导航轨道布局常量（宽度与桌面标题栏左区对齐；色值走 [ThemeData.colorScheme]）。
abstract final class AppSidebarTheme {
  static const width = AppLayout.sidebarWidth;

  static const menuButtonHeight = AppTypography.controlHeight;
  static const menuButtonHeightLg = 48.0;
  static const menuButtonRadius = AppRadius.md;

  /// 导航项常态：与侧栏/底栏面板同色，避免 `Colors.transparent` 在
  /// [AnimatedContainer] 中与 hover 色插值时中间帧发灰。见 `docs/agents/flutter-ui.md` §颜色过渡动画。
  static Color menuItemBackgroundRest(ColorScheme scheme) =>
      scheme.surfaceContainer;

  /// 导航项悬停：图标胶囊浅灰底。
  static Color menuItemBackgroundHover(ColorScheme scheme) =>
      scheme.surfaceContainerHighest;

  /// 导航项选中：图标胶囊浅蓝底。
  static Color menuItemBackgroundActive(ColorScheme scheme) =>
      scheme.secondaryContainer;
}
