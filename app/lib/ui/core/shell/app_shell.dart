import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/shell/sidebar/app_main_sidebar.dart';
import 'package:comic_book_maker/ui/core/shell/sidebar/mobile_app_nav.dart';
import 'package:comic_book_maker/ui/core/shell/sidebar/sidebar.dart';
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
    final useSidebar = useAppSidebar(context);
    final selectedIndex = navigationShell.currentIndex;

    // 壳层页面（漫画库 / 设置）无自带 Scaffold；需此处提供以便 SnackBar 等反馈。
    final shellBody = Scaffold(
      backgroundColor: scheme.surface,
      body: navigationShell,
    );

    if (useSidebar) {
      return SidebarLayout(
        sidebar: AppMainSidebar(
          selectedIndex: selectedIndex,
          onSelect: _goBranch,
        ),
        child: shellBody,
      );
    }

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: shellBody),
          MobileAppNav(
            selectedIndex: selectedIndex,
            onSelect: _goBranch,
          ),
        ],
      ),
    );
  }
}
