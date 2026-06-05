import 'package:flutter/material.dart';

enum AppBreakpoint { compact, medium, expanded }

AppBreakpoint breakpointOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 1200) return AppBreakpoint.expanded;
  if (width >= 720) return AppBreakpoint.medium;
  return AppBreakpoint.compact;
}

bool isCompact(BuildContext context) =>
    breakpointOf(context) == AppBreakpoint.compact;

bool isExpanded(BuildContext context) =>
    breakpointOf(context) == AppBreakpoint.expanded;

/// 主界面宽屏：左侧导航栏 + 右侧内容区。
bool useAppSidebar(BuildContext context) =>
    breakpointOf(context) != AppBreakpoint.compact;

bool editorUsePageSidebar(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= 720;

/// 桌面端窗口最小尺寸（侧栏 256px + 内容区，避免工具栏与侧边 Tab 对话框溢出）。
const Size appDesktopMinWindowSize = Size(800, 600);

/// 侧边 Tab 功能对话框最大宽度（与 [appSheetMaxWidth + 40] 对齐的紧凑默认值）。
double sideTabFeatureDialogMaxWidth(BuildContext context) {
  return switch (breakpointOf(context)) {
    AppBreakpoint.expanded => 800,
    AppBreakpoint.medium => 680,
    AppBreakpoint.compact => 520,
  };
}

class ResponsiveFormGrid extends StatelessWidget {
  const ResponsiveFormGrid({
    super.key,
    required this.children,
    this.spacing = 16,
  });

  final List<Widget> children;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 480 ? 2 : 1;

        if (columns == 1) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: spacing),
                children[i],
              ],
            ],
          );
        }

        final itemWidth = (constraints.maxWidth - spacing) / 2;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }
}
