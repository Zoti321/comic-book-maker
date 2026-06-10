import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/shell/sidebar/sidebar.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 应用主导航侧栏（项目 / 设置）。
class AppMainSidebar extends StatelessWidget {
  const AppMainSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _items = <(IconData, String)>[
    (LucideIcons.library, '项目'),
    (LucideIcons.settings, '设置'),
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
              child: SidebarMenu(
                children: [
                  for (var i = 0; i < _items.length; i++)
                    SidebarMenuItem(
                      child: SidebarMenuButton(
                        icon: Icon(_items[i].$1),
                        isActive: selectedIndex == i,
                        onPressed: () => onSelect(i),
                        tooltip: _items[i].$2,
                        showTooltip: false,
                        child: Text(_items[i].$2),
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
