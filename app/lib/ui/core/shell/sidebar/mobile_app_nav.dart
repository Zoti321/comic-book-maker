import 'package:comic_book_maker/ui/core/shell/sidebar/sidebar_menu_button.dart';
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
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(top: BorderSide(color: scheme.outline)),
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
                    icon: Icon(
                      selectedIndex == i ? _items[i].$2 : _items[i].$1,
                    ),
                    isActive: selectedIndex == i,
                    onPressed: () => onSelect(i),
                    child: Text(
                      _items[i].$3,
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
