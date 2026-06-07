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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Sidebar(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SidebarHeader(
            child: Text(
              'Comic Book Maker',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
          ),
          SidebarContent(
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
