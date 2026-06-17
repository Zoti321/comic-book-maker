import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/shell/app_navigation_destinations.dart';
import 'package:comic_book_maker/ui/core/shell/app_shell_chrome.dart';
import 'package:comic_book_maker/ui/core/shell/sidebar/sidebar_theme.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 宽屏主导航 [NavigationRail]（扩展标签，宽度与桌面标题栏左区对齐）。
class AppNavigationRail extends StatelessWidget {
  const AppNavigationRail({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  bool _showChromeLead(BuildContext context) =>
      desktopWindowConfig.chromeEnabled && useAppSidebar(context);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final showChromeLead = _showChromeLead(context);

    return Material(
      color: scheme.surface,
      child: Container(
        width: AppSidebarTheme.width,
        decoration: AppShellChrome.sidebarDecoration(scheme),
        child: SafeArea(
          top: !desktopWindowConfig.chromeEnabled,
          child: NavigationRail(
            extended: true,
            minExtendedWidth: AppLayout.sidebarWidth,
            backgroundColor: Colors.transparent,
            selectedIndex: selectedIndex,
            onDestinationSelected: onDestinationSelected,
            leading: showChromeLead
                ? null
                : Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Comic Book Maker',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.onSurface,
                            ),
                      ),
                    ),
                  ),
            destinations: [
              for (final destination in AppNavigationDestinations.destinations)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: Text(destination.label),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
