import 'package:comic_book_maker/ui/core/shell/app_shell_chrome.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 桌面无边框窗口顶栏：拖拽区 + 最小化 / 最大化 / 关闭。
///
/// 宽屏且存在侧栏时，应用名由 [DesktopShellChromeLead] 展示，此处仅保留窗口控件。
class DesktopWindowCaption extends StatelessWidget {
  const DesktopWindowCaption({
    super.key,
    this.title = 'Comic Book Maker',
    this.showTitle = true,
  });

  final String title;
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final chromeBackground = AppShellChrome.background(colorScheme);

    return WindowCaption(
      brightness: theme.brightness,
      backgroundColor: chromeBackground,
      title: showTitle
          ? Text(
              title,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}

/// 与侧栏同宽的标题栏左区：应用名 + 拖拽区。
class DesktopShellChromeLead extends StatelessWidget {
  const DesktopShellChromeLead({
    super.key,
    this.title = 'Comic Book Maker',
  });

  final String title;

  static const keySlot = Key('desktop-shell-chrome-lead');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DragToMoveArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            title,
            key: keySlot,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}
