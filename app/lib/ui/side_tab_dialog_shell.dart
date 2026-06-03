import 'package:flutter/material.dart';

/// 对话框内左侧纵向 Tab + 右侧内容区（Komga「编辑库」式布局）。
class SideTabDialogShell extends StatelessWidget {
  const SideTabDialogShell({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.tabs,
    required this.child,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<SideTabDialogTab> tabs;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.maxFinite,
      height: 440,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: onTabSelected,
            labelType: NavigationRailLabelType.all,
            minWidth: 96,
            destinations: [
              for (final tab in tabs)
                NavigationRailDestination(
                  icon: Icon(tab.icon),
                  selectedIcon: Icon(tab.icon),
                  label: Text(tab.label),
                ),
            ],
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: theme.dividerColor,
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}

class SideTabDialogTab {
  const SideTabDialogTab({
    required this.label,
    required this.icon,
  });

  final String label;
  final IconData icon;
}
