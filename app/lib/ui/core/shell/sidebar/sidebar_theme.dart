import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 应用壳层侧栏布局常量（色值统一走 [ThemeData.colorScheme]）。
abstract final class AppSidebarTheme {
  static const width = AppLayout.sidebarWidth;

  static const menuButtonHeight = AppTypography.controlHeight;
  static const menuButtonHeightLg = 48.0;
  static const menuButtonRadius = AppRadius.md;

  /// 导航项常态：与侧栏面板同色，避免 `transparent` 插值闪烁。
  static Color menuItemBackgroundRest(ColorScheme scheme) => scheme.surface;

  /// 导航项悬停：浅灰高亮，轻于旧版 `surfaceContainerHigh`。
  static Color menuItemBackgroundHover(ColorScheme scheme) =>
      scheme.surfaceContainer;

  /// 导航项选中：与悬停同底，靠描边与字重区分。
  static Color menuItemBackgroundActive(ColorScheme scheme) =>
      scheme.surfaceContainer;
}
