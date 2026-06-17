import 'dart:io' show Platform;

import 'package:comic_book_maker/ui/core/design_system/desktop_window_caption.dart';
import 'package:comic_book_maker/ui/core/shell/app_shell_chrome.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 侧栏顶区：拖拽；macOS 交通灯在左上。
class AppShellSidebarChromeRow extends StatelessWidget {
  const AppShellSidebarChromeRow({super.key});

  static const slotKey = Key('app-shell-sidebar-chrome-row');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = AppShellChrome.sidebarBackground(scheme);

    if (!kIsWeb && Platform.isMacOS) {
      return ColoredBox(
        color: background,
        child: SizedBox(
          key: slotKey,
          height: kWindowCaptionHeight,
          child: const DesktopWindowCaption(showTitle: false),
        ),
      );
    }

    return ColoredBox(
      color: background,
      child: SizedBox(
        key: slotKey,
        height: kWindowCaptionHeight,
        child: const DragToMoveArea(child: SizedBox.expand()),
      ),
    );
  }
}

/// 内容面板顶区：拖拽 + Win/Linux 窗口控件（右上）。
class AppShellContentChromeRow extends StatelessWidget {
  const AppShellContentChromeRow({super.key});

  static const slotKey = Key('app-shell-content-chrome-row');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = AppShellChrome.contentBackground(scheme);

    if (!kIsWeb && Platform.isMacOS) {
      return ColoredBox(
        color: background,
        child: SizedBox(
          key: slotKey,
          height: kWindowCaptionHeight,
          child: const DragToMoveArea(child: SizedBox.expand()),
        ),
      );
    }

    return ColoredBox(
      color: background,
      child: SizedBox(
        key: slotKey,
        height: kWindowCaptionHeight,
        child: const DesktopWindowCaption(showTitle: false),
      ),
    );
  }
}

/// 窄屏或全屏路由（如编辑页）使用的全宽 chrome 行。
class AppShellFullWidthChromeRow extends StatelessWidget {
  const AppShellFullWidthChromeRow({super.key});

  static const slotKey = Key('app-shell-fullwidth-chrome-row');

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = AppShellChrome.contentBackground(scheme);

    return ColoredBox(
      color: background,
      child: SizedBox(
        key: slotKey,
        height: kWindowCaptionHeight,
        child: const DesktopWindowCaption(showTitle: false),
      ),
    );
  }
}
