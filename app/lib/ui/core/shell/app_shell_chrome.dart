import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 应用壳层（侧栏 + inset 内容面板）共享的视觉 token。
abstract final class AppShellChrome {
  static Color windowBackground(ColorScheme scheme) => scheme.surfaceContainer;

  static Color sidebarBackground(ColorScheme scheme) => scheme.surfaceContainer;

  static Color contentBackground(ColorScheme scheme) => scheme.surface;

  /// 内容 inset 面板左缘圆角（左上 + 左下）。
  static BorderRadius get contentPanelRadius => BorderRadius.horizontal(
        left: Radius.circular(AppRadius.shellContent),
      );
}
