import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/shell/app_navigation_bar.dart';
import 'package:comic_book_maker/ui/core/shell/app_navigation_rail.dart';
import 'package:comic_book_maker/ui/core/shell/app_shell_chrome.dart';
import 'package:comic_book_maker/ui/core/shell/app_shell_desktop_chrome.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  void _goBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  bool _showDesktopChrome(BuildContext context) =>
      desktopWindowConfig.chromeEnabled && useAppSidebar(context);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final useRail = useAppSidebar(context);
    final selectedIndex = navigationShell.currentIndex;
    final showChrome = _showDesktopChrome(context);

    if (useRail) {
      return ColoredBox(
        color: AppShellChrome.windowBackground(scheme),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppNavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: _goBranch,
              showDesktopChrome: showChrome,
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: AppShellChrome.contentPanelRadius,
                child: ColoredBox(
                  color: AppShellChrome.contentBackground(scheme),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showChrome) const AppShellContentChromeRow(),
                      Expanded(child: navigationShell),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: scheme.surface,
      body: navigationShell,
      bottomNavigationBar: AppNavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: _goBranch,
      ),
    );
  }
}
