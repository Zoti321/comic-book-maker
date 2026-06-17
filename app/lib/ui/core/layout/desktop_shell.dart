import 'dart:io' show Platform;

import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/shell/app_shell_chrome.dart';
import 'package:comic_book_maker/ui/core/shell/app_shell_desktop_chrome.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

typedef DesktopShellFrameBuilder = Widget Function(Widget child);

/// 桌面无边框壳层：[VirtualWindowFrame] 拖边缩放。
///
/// 宽屏 split chrome 由 [AppShell] 承担；窄屏与独立路由见 [AppShellFullWidthChromeRow] /
/// [DesktopStandaloneChrome]。
class DesktopShell extends StatelessWidget {
  const DesktopShell({
    super.key,
    required this.child,
    @visibleForTesting this.captionOverride,
    @visibleForTesting this.frameBuilderOverride,
  });

  final Widget child;

  @visibleForTesting
  final Widget? captionOverride;

  @visibleForTesting
  final DesktopShellFrameBuilder? frameBuilderOverride;

  static const captionSlotKey = Key('desktop-window-caption-slot');

  @override
  Widget build(BuildContext context) {
    if (!desktopWindowConfig.chromeEnabled) {
      return child;
    }

    final scheme = Theme.of(context).colorScheme;
    Widget content = child;

    if (!useAppSidebar(context)) {
      final chrome = captionOverride != null
          ? SizedBox(
              key: captionSlotKey,
              height: kWindowCaptionHeight,
              child: captionOverride,
            )
          : const AppShellFullWidthChromeRow();

      content = ColoredBox(
        color: AppShellChrome.contentBackground(scheme),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            chrome,
            Expanded(child: child),
          ],
        ),
      );
    }

    return (frameBuilderOverride ?? _defaultFrameBuilder)(content);
  }

  static Widget _defaultFrameBuilder(Widget child) {
    if (!kIsWeb && Platform.isMacOS) {
      return DragToResizeArea(child: child);
    }
    return VirtualWindowFrame(child: child);
  }
}
