import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:comic_book_maker/ui/features/library/project_card.dart';
import 'package:flutter/material.dart';

/// 漫画库网格间距。
const libraryGridSpacing = AppSpacing.sm + 4; // 12

/// 单列卡片最大宽度；列数由 [SliverGridDelegateWithMaxCrossAxisExtent] 自动推算。
const libraryCardMaxExtent = 180.0;

/// 漫画库内容区内边距（与设置页 [PageHeader] 一致，仅用 [AppSpacing.pagePadding]）。
EdgeInsets libraryContentPadding(BuildContext context) =>
    AppSpacing.pagePadding(context);

/// 漫画库网格单元宽高比（按 [libraryCardMaxExtent] 估算封面 + 标题区高度）。
double libraryGridChildAspectRatio() =>
    ProjectCard.gridChildAspectRatioForCellWidth(libraryCardMaxExtent);
