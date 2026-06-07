import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 桌面无边框窗口顶栏：应用名、拖拽区、最小化 / 最大化 / 关闭。
///
/// 职责仅限窗口 chrome，不合并业务 [AppBar]。
class DesktopWindowCaption extends StatelessWidget {
  const DesktopWindowCaption({
    super.key,
    this.title = 'Comic Book Maker',
  });

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WindowCaption(
      brightness: theme.brightness,
      backgroundColor: colorScheme.surfaceContainerLow,
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
        ),
      ),
    );
  }
}
