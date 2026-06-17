import 'package:comic_book_maker/ui/core/shell/app_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 桌面无边框窗口顶栏：拖拽区 + 最小化 / 最大化 / 关闭（无应用标题）。
class DesktopWindowCaption extends StatelessWidget {
  const DesktopWindowCaption({
    super.key,
    this.showTitle = false,
  });

  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chromeBackground = AppShellChrome.contentBackground(colorScheme);

    return WindowCaption(
      brightness: theme.brightness,
      backgroundColor: chromeBackground,
      title: const SizedBox.shrink(),
    );
  }
}
