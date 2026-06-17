import 'package:flutter/material.dart';

/// 应用主导航目的地，与 [StatefulNavigationShell] 分支索引一致。
abstract final class AppNavigationDestinations {
  static const destinations = <AppNavigationDestination>[
    AppNavigationDestination(
      icon: Icons.folder_outlined,
      selectedIcon: Icons.folder,
      label: '项目',
    ),
    AppNavigationDestination(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: '设置',
    ),
  ];
}

class AppNavigationDestination {
  const AppNavigationDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}
