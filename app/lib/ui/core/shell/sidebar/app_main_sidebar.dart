import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/shell/sidebar/sidebar.dart';
import 'package:flutter/material.dart';

/// 应用主导航侧栏（项目 / 设置）。
class AppMainSidebar extends StatelessWidget {
  const AppMainSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _items = <(IconData, IconData, String)>[
    (
      Icons.collections_bookmark_outlined,
      Icons.collections_bookmark,
      '项目',
    ),
    (
      Icons.settings_outlined,
      Icons.settings,
      '设置',
    ),
  ];

  bool _showChromeLead(BuildContext context) =>
      desktopWindowConfig.chromeEnabled && useAppSidebar(context);

  @override
  Widget build(BuildContext context) {
    final showChromeLead = _showChromeLead(context);

    return Sidebar(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!showChromeLead)
            SidebarHeader(
              child: Text(
                'Comic Book Maker',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
          SidebarContent(
            padding: EdgeInsets.fromLTRB(
              8,
              showChromeLead ? 12 : 0,
              8,
              0,
            ),
            child: SidebarGroup(
              label: '导航',
              child: SidebarMenu(
                children: [
                  for (var i = 0; i < _items.length; i++)
                    SidebarMenuItem(
                      child: SidebarMenuButton(
                        icon: Icon(
                          selectedIndex == i ? _items[i].$2 : _items[i].$1,
                        ),
                        isActive: selectedIndex == i,
                        onPressed: () => onSelect(i),
                        tooltip: _items[i].$3,
                        child: Text(_items[i].$3),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
