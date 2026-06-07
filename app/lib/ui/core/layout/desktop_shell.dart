import 'dart:io' show Platform;

import 'package:comic_book_maker/ui/core/design_system/desktop_window_caption.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/shell/app_shell_chrome.dart';
import 'package:comic_book_maker/ui/core/shell/sidebar/sidebar_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

typedef DesktopShellFrameBuilder = Widget Function(Widget child);

/// 桌面无边框壳层：侧栏同宽顶栏左区 + 窗口控件 + [VirtualWindowFrame] 拖边缩放。
///
/// [desktopWindowConfig.chromeEnabled] 为 `false` 时透传 [child]。
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
    final chromeBackground = AppShellChrome.background(scheme);
    final useSplitChrome = useAppSidebar(context);

    final captionBar = captionOverride != null
        ? SizedBox(
            key: captionSlotKey,
            height: kWindowCaptionHeight,
            child: captionOverride,
          )
        : Column(
            key: captionSlotKey,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: kWindowCaptionHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (useSplitChrome)
                      Container(
                        width: AppSidebarTheme.width,
                        decoration: AppShellChrome.captionLeadDecoration(scheme),
                        child: const DesktopShellChromeLead(),
                      ),
                    Expanded(
                      child: ColoredBox(
                        color: chromeBackground,
                        child: DesktopWindowCaption(
                          showTitle: !useSplitChrome,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppShellChrome.captionBottomBorder(scheme),
            ],
          );

    final framed = (frameBuilderOverride ?? _defaultFrameBuilder)(
      ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            captionBar,
            Expanded(child: child),
          ],
        ),
      ),
    );

    return framed;
  }

  static Widget _defaultFrameBuilder(Widget child) {
    if (!kIsWeb && Platform.isMacOS) {
      // window_manager 的 VirtualWindowFrame 在 macOS 不挂载 DragToResizeArea。
      return DragToResizeArea(child: child);
    }
    return VirtualWindowFrame(child: child);
  }
}
