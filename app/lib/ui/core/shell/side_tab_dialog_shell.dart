import 'package:comic_book_maker/ui/core/theme/app_colors.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 侧栏 Tab 功能对话框在窄屏下切换为 header Tab 的宽度断点。
const sideTabDialogCompactBreakpoint = 560.0;

/// 对话框内侧栏 Tab + 内容区（新建向导 / 项目属性等共用）。
class SideTabDialogShell extends StatelessWidget {
  const SideTabDialogShell({
    super.key,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.tabs,
    required this.child,
    this.height,
    this.showSideTabs = true,
  });

  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final List<SideTabDialogTab> tabs;
  final Widget child;

  /// 外壳高度；未设时按宽度选用 400 / 440，并在父级有界时不超过可用高度。
  final double? height;

  /// 窄屏 header Tab 模式下为 `false`，仅渲染内容区。
  final bool showSideTabs;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final preferredHeight = constraints.maxWidth < sideTabDialogCompactBreakpoint
            ? 400.0
            : 440.0;
        final shellHeight = height ??
            (constraints.hasBoundedHeight
                ? constraints.maxHeight.clamp(240.0, preferredHeight)
                : preferredHeight);

        if (!showSideTabs) {
          return SizedBox(
            width: double.maxFinite,
            height: shellHeight,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: child,
            ),
          );
        }

        return SizedBox(
          width: double.maxFinite,
          height: shellHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 112,
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
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: scheme.outline,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
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

/// 窄屏对话框 header 内横排 Tab（仅文字 + 底部指示条）。
class SideTabDialogHeaderTabs extends StatelessWidget {
  const SideTabDialogHeaderTabs({
    super.key,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
  });

  final List<SideTabDialogTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < tabs.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.xs),
          _SideTabHeaderTabItem(
            label: tabs[i].label,
            selected: selectedIndex == i,
            onTap: () => onTabSelected(i),
          ),
        ],
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
    final foreground =
        widget.selected ? AppColors.primary : theme.colorScheme.onSurfaceVariant;
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
          color: _hovered ? AppColors.surfaceContainer : null,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (widget.selected)
                const Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 3,
                    height: double.infinity,
                    child: ColoredBox(color: AppColors.primary),
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

class _SideTabHeaderTabItem extends StatefulWidget {
  const _SideTabHeaderTabItem({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  State<_SideTabHeaderTabItem> createState() => _SideTabHeaderTabItemState();
}

class _SideTabHeaderTabItemState extends State<_SideTabHeaderTabItem> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final foreground =
        widget.selected ? AppColors.primary : theme.colorScheme.onSurfaceVariant;
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
          padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
          decoration: BoxDecoration(
            color: _hovered ? AppColors.surfaceContainer : null,
            border: Border(
              bottom: BorderSide(
                color: widget.selected ? AppColors.primary : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(widget.label, style: textStyle),
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
