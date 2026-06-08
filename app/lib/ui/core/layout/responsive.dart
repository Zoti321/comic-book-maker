import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

enum AppBreakpoint { compact, medium, expanded }

AppBreakpoint breakpointOf(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= AppBreakpointWidths.expanded) {
    return AppBreakpoint.expanded;
  }
  if (width >= AppBreakpointWidths.medium) {
    return AppBreakpoint.medium;
  }
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
    MediaQuery.sizeOf(context).width >= AppBreakpointWidths.medium;

/// 桌面端窗口最小尺寸（允许缩至 compact 断点以下，便于桌面调试窄屏 UI）。
const Size appDesktopMinWindowSize = Size(360, 640);

/// 内容区可用宽度（可选扣除侧栏）。
double contentWidthOf(
  BuildContext context, {
  bool subtractSidebar = true,
}) {
  final width = MediaQuery.sizeOf(context).width;
  if (subtractSidebar && useAppSidebar(context)) {
    return width - AppLayout.sidebarWidth - 1;
  }
  return width;
}

/// 内容区内边距；超宽屏时水平居中并限制最大宽度。
EdgeInsets contentPaddingOf(BuildContext context) {
  final base = AppSpacing.pagePadding(context);
  final width = contentWidthOf(context);
  if (width <= AppLayout.contentMaxWidth) return base;

  final extra = (width - AppLayout.contentMaxWidth) / 2;
  return EdgeInsets.fromLTRB(
    extra + base.left,
    base.top,
    extra + base.right,
    base.bottom,
  );
}

/// 按内容区宽度估算自适应网格列数（漫画库、缩略图等共用）。
int gridColumnsForWidth(
  double contentWidth, {
  int minColumns = 1,
  int maxColumns = 7,
}) {
  final columns = switch (contentWidth) {
    >= 1200 => 7,
    >= 960 => 6,
    >= 760 => 5,
    >= 560 => 4,
    >= 400 => 3,
    >= 280 => 2,
    _ => 1,
  };
  return columns.clamp(minColumns, maxColumns);
}

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
