import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 对话框内侧栏 Tab + 内容区（新建向导 / 项目属性等共用）。
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
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final useCompactTabs = constraints.maxWidth < 560;
        final shellHeight = useCompactTabs ? 400.0 : 440.0;

        if (useCompactTabs) {
          return SizedBox(
            width: double.maxFinite,
            height: shellHeight,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.hardEdge,
                  child: Row(
                    children: [
                      for (var i = 0; i < tabs.length; i++) ...[
                        if (i > 0) const SizedBox(width: 8),
                        _SideTabChip(
                          tab: tabs[i],
                          selected: selectedIndex == i,
                          onTap: () => onTabSelected(i),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Divider(height: 1, color: scheme.outline),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: child,
                  ),
                ),
              ],
            ),
          );
        }

        return SizedBox(
          width: double.maxFinite,
          height: shellHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                onDestinationSelected: onTabSelected,
                labelType: NavigationRailLabelType.all,
                minWidth: 96,
                backgroundColor: scheme.surface,
                indicatorColor: scheme.surfaceContainerHighest,
                useIndicator: true,
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
                color: scheme.outline,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
                    AppSpacing.sm,
                    AppSpacing.sm,
                  ),
                  child: child,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SideTabChip extends StatelessWidget {
  const _SideTabChip({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final SideTabDialogTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FilterChip(
      avatar: Icon(
        tab.icon,
        size: 18,
        color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
      ),
      label: Text(tab.label),
      selected: selected,
      onSelected: (_) => onTap(),
      showCheckmark: false,
      selectedColor: scheme.surfaceContainerHighest,
      labelStyle: TextStyle(
        color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(
        color: selected
            ? scheme.onSurfaceVariant.withValues(alpha: 0.45)
            : scheme.outline,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.mdBorder,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
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
