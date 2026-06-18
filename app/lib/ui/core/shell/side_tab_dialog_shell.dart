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
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: AppLayout.sideTabDialogNavWidth,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              for (var i = 0; i < tabs.length; i++)
                _SideTabNavItem(
                  tab: tabs[i],
                  selected: selectedIndex == i,
                  onTap: () => onTabSelected(i),
                ),
            ],
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: SingleChildScrollView(child: child),
          ),
        ),
      ],
    );
  }
}

class _SideTabNavItem extends StatefulWidget {
  const _SideTabNavItem({
    required this.tab,
    required this.selected,
    required this.onTap,
  });

  final SideTabDialogTab tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SideTabNavItem> createState() => _SideTabNavItemState();
}

class _SideTabNavItemState extends State<_SideTabNavItem> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground =
        widget.selected ? scheme.primary : scheme.onSurfaceVariant;
    final textStyle = theme.textTheme.labelLarge?.copyWith(
      color: foreground,
      fontWeight: widget.selected ? FontWeight.w600 : FontWeight.w500,
      height: 1.25,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeOut,
          height: 40,
          color: _hovered ? scheme.surfaceContainer : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.selected)
                Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 3,
                    height: double.infinity,
                    child: ColoredBox(color: scheme.primary),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 11, right: AppSpacing.sm),
                child: Row(
                  children: [
                    Icon(widget.tab.icon, size: 18, color: foreground),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        widget.tab.label,
                        style: textStyle,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
