import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/shell/app_shell_chrome.dart';
import 'package:comic_book_maker/ui/core/shell/app_shell_desktop_chrome.dart';
import 'package:flutter/material.dart';

/// 非 [AppShell] 路由（如项目编辑页）在桌面 chrome 启用时的全宽顶栏包装。
///
/// 窄屏时 [DesktopShell] 已提供全宽 chrome，此处不再重复添加。
class DesktopStandaloneChrome extends StatelessWidget {
  const DesktopStandaloneChrome({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!desktopWindowConfig.chromeEnabled) {
      return child;
    }

    if (!useAppSidebar(context)) {
      return child;
    }

    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: AppShellChrome.contentBackground(scheme),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AppShellFullWidthChromeRow(),
          Expanded(child: child),
        ],
      ),
    );
  }
}
