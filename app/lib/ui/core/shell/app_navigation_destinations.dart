import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 应用主导航目的地，与 [StatefulNavigationShell] 分支索引一致。
abstract final class AppNavigationDestinations {
  static const destinations = <AppNavigationDestination>[
    AppNavigationDestination(
      icon: LucideIcons.library,
      selectedIcon: LucideIcons.library,
      label: '项目',
    ),
    AppNavigationDestination(
      icon: LucideIcons.settings,
      selectedIcon: LucideIcons.settings,
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
