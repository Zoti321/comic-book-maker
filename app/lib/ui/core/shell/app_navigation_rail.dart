import 'package:comic_book_maker/ui/core/shell/app_navigation_destinations.dart';
import 'package:comic_book_maker/ui/core/shell/app_shell_chrome.dart';
import 'package:comic_book_maker/ui/core/shell/app_shell_desktop_chrome.dart';
import 'package:comic_book_maker/ui/core/shell/sidebar/sidebar_theme.dart';
import 'package:flutter/material.dart';

/// 宽屏主导航 [NavigationRail]（图标在上、标签在下）。
class AppNavigationRail extends StatelessWidget {
  const AppNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.showDesktopChrome = false,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool showDesktopChrome;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: AppShellChrome.sidebarBackground(scheme),
      child: SizedBox(
        width: AppSidebarTheme.width,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDesktopChrome) const AppShellSidebarChromeRow(),
            Expanded(
              child: SafeArea(
                top: !showDesktopChrome,
                child: NavigationRail(
                  extended: false,
                  labelType: NavigationRailLabelType.all,
                  backgroundColor: Colors.transparent,
                  selectedIndex: selectedIndex,
                  onDestinationSelected: onDestinationSelected,
                  destinations: [
                    for (final destination
                        in AppNavigationDestinations.destinations)
                      NavigationRailDestination(
                        icon: Icon(destination.icon),
                        selectedIcon: Icon(destination.selectedIcon),
                        label: Text(destination.label),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
