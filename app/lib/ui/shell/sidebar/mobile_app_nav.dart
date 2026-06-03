import 'package:comic_book_maker/ui/shell/sidebar/sidebar_menu_button.dart';
import 'package:comic_book_maker/ui/shell/sidebar/sidebar_theme.dart';
import 'package:flutter/material.dart';

/// 窄屏底部导航（侧栏不可用时的替代）。
class MobileAppNav extends StatelessWidget {
  const MobileAppNav({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _items = <(IconData, String)>[
    (Icons.collections_bookmark_outlined, '项目'),
    (Icons.settings_outlined, '设置'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppSidebarTheme.background,
        border: Border(top: BorderSide(color: AppSidebarTheme.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Row(
            children: [
              for (var i = 0; i < _items.length; i++)
                Expanded(
                  child: SidebarMenuButton(
                    icon: Icon(_items[i].$1),
                    isActive: selectedIndex == i,
                    onPressed: () => onSelect(i),
                    child: Text(
                      _items[i].$2,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
