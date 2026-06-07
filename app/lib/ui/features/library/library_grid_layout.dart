import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:comic_book_maker/ui/features/library/project_card.dart';
import 'package:flutter/material.dart';

/// 漫画库网格间距。
const libraryGridSpacing = AppSpacing.sm + 4; // 12

/// 漫画库内容区内边距；超宽屏时水平居中并限制最大宽度。
EdgeInsets libraryContentPadding(BuildContext context) =>
    contentPaddingOf(context);

/// 漫画库网格：按内容区宽度估算列数（宽屏侧栏会占用左侧宽度）。
int libraryGridColumns(BuildContext context) {
  return gridColumnsForWidth(contentWidthOf(context));
}

/// 漫画库网格单元宽高比（与 [ProjectCard.coverAspectRatio] + 标题区高度一致）。
double libraryGridChildAspectRatio(BuildContext context) {
  final padding = libraryContentPadding(context);
  final gridPadding = padding.left + padding.right;
  final columns = libraryGridColumns(context);
  final contentWidth = contentWidthOf(context);
  final effectiveWidth = contentWidth > AppLayout.contentMaxWidth
      ? AppLayout.contentMaxWidth
      : contentWidth;
  final cellWidth =
      (effectiveWidth - gridPadding - libraryGridSpacing * (columns - 1)) /
          columns;
  return ProjectCard.gridChildAspectRatioForCellWidth(cellWidth);
}
