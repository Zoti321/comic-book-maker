import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/shell/app_navigation_bar.dart';
import 'package:comic_book_maker/ui/core/shell/app_navigation_rail.dart';
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final useRail = useAppSidebar(context);
    final selectedIndex = navigationShell.currentIndex;

    if (useRail) {
      return ColoredBox(
        color: scheme.surface,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppNavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: _goBranch,
            ),
            Expanded(
              child: Scaffold(
                backgroundColor: scheme.surface,
                body: navigationShell,
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
