import 'package:comic_book_maker/ui/layout/responsive.dart';
import 'package:comic_book_maker/ui/shell/sidebar/app_main_sidebar.dart';
import 'package:comic_book_maker/ui/shell/sidebar/mobile_app_nav.dart';
import 'package:comic_book_maker/ui/shell/sidebar/sidebar.dart';
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
    final useSidebar = useAppSidebar(context);
    final selectedIndex = navigationShell.currentIndex;

    // 壳层页面（漫画库 / 设置）无自带 Scaffold；需此处提供以便 SnackBar 等反馈。
    final shellBody = Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: SidebarInset(child: shellBody)),
        MobileAppNav(
          selectedIndex: selectedIndex,
          onSelect: _goBranch,
        ),
      ],
    );
  }
}
