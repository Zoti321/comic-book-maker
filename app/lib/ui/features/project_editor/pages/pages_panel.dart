import 'dart:io';

import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:comic_book_maker/ui/core/widgets/app_surface_ink_well.dart';
import 'package:comic_book_maker/ui/features/project_editor/pages/page_thumbnail_hover_menu.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

const _thumbAspectRatio = 3 / 4;
const _gridSpacing = AppSpacing.sm + 4; // 12

/// 缩略图统一 overflow 菜单项（所有页面操作经此入口）。
enum PageThumbnailAction {
  view,
  replace,
  setCover,
  moveEarlier,
  moveLater,
  delete,
}

/// 按可用宽度计算缩略图网格列数（2–8 列；单格最小约 96px 宽）。
int pageThumbnailCrossAxisCount(double availableWidth) {
  const minThumb = 96.0;
  if (availableWidth <= 0) return 2;

  final columns = ((availableWidth + _gridSpacing) / (minThumb + _gridSpacing))
      .floor();
  return columns.clamp(2, 8);
}

/// 单格布局尺寸（逻辑像素）。
class PageThumbnailTileSize {
  const PageThumbnailTileSize({required this.width, required this.height});

  final double width;
  final double height;
}

/// 由网格可用宽度推算单格宽高（与 [PageThumbnailGrid] 的 [SliverGrid] 一致）。
PageThumbnailTileSize pageThumbnailTileSize(double availableWidth) {
  final crossAxisCount = pageThumbnailCrossAxisCount(availableWidth);
  final tileWidth =
      (availableWidth - (crossAxisCount - 1) * _gridSpacing) / crossAxisCount;
  final tileHeight = tileWidth / _thumbAspectRatio;
  return PageThumbnailTileSize(width: tileWidth, height: tileHeight);
}

/// 解码缓存像素尺寸（物理像素，供 [Image.cacheWidth] / [cacheHeight]）。
class PageThumbnailCacheSize {
  const PageThumbnailCacheSize({required this.width, required this.height});

  final int width;
  final int height;
}

PageThumbnailCacheSize pageThumbnailCacheSize({
  required double tileWidth,
  required double tileHeight,
  required double devicePixelRatio,
}) {
  return PageThumbnailCacheSize(
    width: (tileWidth * devicePixelRatio).ceil(),
    height: (tileHeight * devicePixelRatio).ceil(),
  );
}

/// 图片 Tab：SliverGrid 展示有序 Page 缩略图。
class PageThumbnailGrid extends StatelessWidget {
  const PageThumbnailGrid({
    super.key,
    required this.pages,
    required this.coverPageIndex,
    required this.onAdd,
    required this.onReplace,
    required this.onDelete,
    required this.onSetCover,
    required this.onViewOriginal,
    required this.onMoveEarlier,
    required this.onMoveLater,
  });

  final List<PageSummary> pages;
  final int coverPageIndex;
  final VoidCallback onAdd;
  final ValueChanged<PageSummary> onReplace;
  final ValueChanged<PageSummary> onDelete;
  final ValueChanged<PageSummary> onSetCover;
  final ValueChanged<PageSummary> onViewOriginal;
  final ValueChanged<PageSummary> onMoveEarlier;
  final ValueChanged<PageSummary> onMoveLater;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sorted = List<PageSummary>.from(pages)
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount =
            pageThumbnailCrossAxisCount(constraints.maxWidth);
        final tileSize = pageThumbnailTileSize(constraints.maxWidth);
        final cacheSize = pageThumbnailCacheSize(
          tileWidth: tileSize.width,
          tileHeight: tileSize.height,
          devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
        );

        return CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Text(
                  '${pages.length} 页',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
            SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                mainAxisSpacing: _gridSpacing,
                crossAxisSpacing: _gridSpacing,
                childAspectRatio: _thumbAspectRatio,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  if (index < sorted.length) {
                    final page = sorted[index];
                    return _PageThumbnailTile(
                      page: page,
                      cacheWidth: cacheSize.width,
                      cacheHeight: cacheSize.height,
                      isCover: page.sortIndex == coverPageIndex,
                      canMoveEarlier: index > 0,
                      canMoveLater: index < sorted.length - 1,
                      onViewOriginal: () => onViewOriginal(page),
                      onAction: (action) => _dispatchAction(
                        action,
                        page,
                        onReplace: onReplace,
                        onDelete: onDelete,
                        onSetCover: onSetCover,
                        onViewOriginal: onViewOriginal,
                        onMoveEarlier: onMoveEarlier,
                        onMoveLater: onMoveLater,
                      ),
                    );
                  }
                  return _AddPageTile(onAdd: onAdd);
                },
                childCount: sorted.length + 1,
              ),
            ),
          ],
        );
      },
    );
  }
}

void _dispatchAction(
  PageThumbnailAction action,
  PageSummary page, {
  required ValueChanged<PageSummary> onReplace,
  required ValueChanged<PageSummary> onDelete,
  required ValueChanged<PageSummary> onSetCover,
  required ValueChanged<PageSummary> onViewOriginal,
  required ValueChanged<PageSummary> onMoveEarlier,
  required ValueChanged<PageSummary> onMoveLater,
}) {
  switch (action) {
    case PageThumbnailAction.view:
      onViewOriginal(page);
    case PageThumbnailAction.replace:
      onReplace(page);
    case PageThumbnailAction.setCover:
      onSetCover(page);
    case PageThumbnailAction.moveEarlier:
      onMoveEarlier(page);
    case PageThumbnailAction.moveLater:
      onMoveLater(page);
    case PageThumbnailAction.delete:
      onDelete(page);
  }
}

class _AddPageTile extends StatelessWidget {
  const _AddPageTile({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      clipBehavior: Clip.antiAlias,
      child: AppSurfaceInkWell(
        preset: AppSurfaceInkPreset.gridTile,
        onTap: onAdd,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.imagePlus,
              size: 28,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(height: 8),
            Text(
              '添加页面',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageThumbnailTile extends StatelessWidget {
  const _PageThumbnailTile({
    required this.page,
    required this.cacheWidth,
    required this.cacheHeight,
    required this.isCover,
    required this.canMoveEarlier,
    required this.canMoveLater,
    required this.onViewOriginal,
    required this.onAction,
  });

  final PageSummary page;
  final int cacheWidth;
  final int cacheHeight;
  final bool isCover;
  final bool canMoveEarlier;
  final bool canMoveLater;
  final VoidCallback onViewOriginal;
  final ValueChanged<PageThumbnailAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return RepaintBoundary(
      child: Material(
        color: scheme.surface,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
        clipBehavior: Clip.antiAlias,
        child: PageThumbnailHoverMenu<PageThumbnailAction>(
          onSelected: onAction,
          menuActionsBuilder: (context) => _pageThumbnailMenuActions(
            context: context,
            isCover: isCover,
            canMoveEarlier: canMoveEarlier,
            canMoveLater: canMoveLater,
          ),
          child: AppSurfaceInkWell(
            preset: AppSurfaceInkPreset.gridTile,
            onTap: onViewOriginal,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _PageThumbnailImage(
                  page: page,
                  cacheWidth: cacheWidth,
                  cacheHeight: cacheHeight,
                ),
                Positioned(
                  left: 6,
                  bottom: 6,
                  child: _PageIndexChip(index: page.sortIndex + 1),
                ),
                if (isCover)
                  const Positioned(
                    left: 6,
                    top: 6,
                    child: _CoverChip(),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<PageThumbnailMenuAction<PageThumbnailAction>> _pageThumbnailMenuActions({
  required BuildContext context,
  required bool isCover,
  required bool canMoveEarlier,
  required bool canMoveLater,
}) {
  final scheme = Theme.of(context).colorScheme;

  return [
    const PageThumbnailMenuAction(
      value: PageThumbnailAction.view,
      icon: Icons.zoom_in,
      label: '查看原图',
    ),
    const PageThumbnailMenuAction(
      value: PageThumbnailAction.replace,
      icon: Icons.swap_horiz,
      label: '替换图片',
    ),
    if (!isCover)
      const PageThumbnailMenuAction(
        value: PageThumbnailAction.setCover,
        icon: Icons.bookmark_border,
        label: '设为封面',
      ),
    if (canMoveEarlier)
      const PageThumbnailMenuAction(
        value: PageThumbnailAction.moveEarlier,
        icon: Icons.arrow_back,
        label: '前移',
      ),
    if (canMoveLater)
      const PageThumbnailMenuAction(
        value: PageThumbnailAction.moveLater,
        icon: Icons.arrow_forward,
        label: '后移',
      ),
    PageThumbnailMenuAction(
      value: PageThumbnailAction.delete,
      icon: Icons.delete_outline,
      label: '删除',
      foregroundColor: scheme.error,
    ),
  ];
}

class _PageIndexChip extends StatelessWidget {
  const _PageIndexChip({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          '$index',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class _CoverChip extends StatelessWidget {
  const _CoverChip();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.primaryContainer,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.bookmark_outline,
              size: 14,
              color: scheme.onPrimaryContainer,
            ),
            const SizedBox(width: 4),
            Text(
              '封面',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PageThumbnailImage extends StatelessWidget {
  const _PageThumbnailImage({
    required this.page,
    required this.cacheWidth,
    required this.cacheHeight,
  });

  final PageSummary page;
  final int cacheWidth;
  final int cacheHeight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ColoredBox(
      color: scheme.surfaceContainer,
      child: Image.file(
        File(page.absolutePath),
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        gaplessPlayback: true,
        cacheWidth: cacheWidth,
        cacheHeight: cacheHeight,
        errorBuilder: (_, _, _) => ColoredBox(
          color: scheme.surfaceContainer,
          child: Center(
            child: Icon(
              LucideIcons.imageOff,
              size: 28,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

