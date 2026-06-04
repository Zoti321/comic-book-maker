import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/shell/sidebar/sidebar_theme.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:comic_book_maker/ui/features/library/project_card.dart';
import 'package:flutter/material.dart';

/// 漫画库网格：按内容区宽度估算列数（宽屏侧栏会占用左侧宽度）。
int libraryGridColumns(BuildContext context) {
  final width = _libraryContentWidth(context);
  if (width >= 1200) return 7;
  if (width >= 960) return 6;
  if (width >= 760) return 5;
  if (width >= 560) return 4;
  if (width >= 400) return 3;
  if (width >= 280) return 2;
  return 1;
}

double _libraryContentWidth(BuildContext context) {
  final width = MediaQuery.sizeOf(context).width;
  if (useAppSidebar(context)) {
    return width - AppSidebarTheme.width - 1;
  }
  return width;
}

/// 漫画库网格单元宽高比（与 [ProjectCard.coverAspectRatio] + 标题区高度一致）。
double libraryGridChildAspectRatio(BuildContext context) {
  final padding = AppSpacing.pagePadding(context);
  final gridPadding = padding.left + padding.right;
  const spacing = 12.0;
  final columns = libraryGridColumns(context);
  final contentWidth = _libraryContentWidth(context);
  final cellWidth =
      (contentWidth - gridPadding - spacing * (columns - 1)) / columns;
  return ProjectCard.gridChildAspectRatioForCellWidth(cellWidth);
}
