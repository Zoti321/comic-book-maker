import 'package:flutter/material.dart';

/// 桌面端壳层（自定义标题栏 + 侧栏）共享的视觉 token。
abstract final class AppShellChrome {
  static Color background(ColorScheme scheme) => scheme.surface;

  static Color border(ColorScheme scheme) => scheme.outline;

  static BorderSide borderSide(ColorScheme scheme) =>
      BorderSide(color: border(scheme));

  /// 标题栏左区（与侧栏同宽）：仅 surface 底，无竖线（竖线由侧栏承担）。
  static BoxDecoration captionLeadDecoration(ColorScheme scheme) =>
      BoxDecoration(color: background(scheme));

  /// 主导航侧栏：surface 底 + 右侧 outline（从标题栏底边横线下方起笔）。
  static BoxDecoration sidebarDecoration(ColorScheme scheme) => BoxDecoration(
        color: background(scheme),
        border: Border(right: borderSide(scheme)),
      );

  /// 标题栏底部分割线（独立 1px 色块，避免被顶栏子组件背景盖住）。
  static const captionBottomBorderKey = Key('desktop-shell-caption-bottom-border');

  static Widget captionBottomBorder(ColorScheme scheme) => ColoredBox(
        key: captionBottomBorderKey,
        color: border(scheme),
        child: const SizedBox(width: double.infinity, height: 1),
      );
}
