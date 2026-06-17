import 'dart:io';

import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
        side: BorderSide(color: scheme.outline),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
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
    final menuButtonStyle = (
      iconColor: scheme.onSurface,
      backgroundColor: scheme.surface.withValues(alpha: 0.92),
    );

    return RepaintBoundary(
      child: Material(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
          side: BorderSide(
            color: isCover ? scheme.onSurface : scheme.outline,
            width: isCover ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: PageThumbnailHoverMenu<PageThumbnailAction>(
          buttonTop: 6,
          buttonRight: 6,
          menuButtonIconColor: menuButtonStyle.iconColor,
          menuButtonBackgroundColor: menuButtonStyle.backgroundColor,
          onSelected: onAction,
          menuItemsBuilder: (context) => _pageThumbnailMenuItems(
            context: context,
            isCover: isCover,
            canMoveEarlier: canMoveEarlier,
            canMoveLater: canMoveLater,
          ),
          child: InkWell(
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
                  child: _Badge(
                    label: '${page.sortIndex + 1}',
                    background: scheme.surface.withValues(alpha: 0.92),
                    foreground: scheme.onSurface,
                    borderColor: scheme.outline,
                  ),
                ),
                if (isCover)
                  Positioned(
                    left: 6,
                    top: 6,
                    child: _Badge(
                      label: '封面',
                      background: scheme.inverseSurface,
                      foreground: scheme.onInverseSurface,
                      icon: LucideIcons.bookmark,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<PopupMenuEntry<PageThumbnailAction>> _pageThumbnailMenuItems({
  required BuildContext context,
  required bool isCover,
  required bool canMoveEarlier,
  required bool canMoveLater,
}) {
  final scheme = Theme.of(context).colorScheme;

  return [
    _menuRow(
      icon: LucideIcons.zoomIn,
      label: '查看原图',
      value: PageThumbnailAction.view,
    ),
    _menuRow(
      icon: LucideIcons.replace,
      label: '替换图片',
      value: PageThumbnailAction.replace,
    ),
    if (!isCover)
      _menuRow(
        icon: LucideIcons.bookmark,
        label: '设为封面',
        value: PageThumbnailAction.setCover,
      ),
    if (canMoveEarlier)
      _menuRow(
        icon: LucideIcons.arrowLeft,
        label: '前移',
        value: PageThumbnailAction.moveEarlier,
      ),
    if (canMoveLater)
      _menuRow(
        icon: LucideIcons.arrowRight,
        label: '后移',
        value: PageThumbnailAction.moveLater,
      ),
    const PopupMenuDivider(),
    _menuRow(
      icon: LucideIcons.trash2,
      label: '删除',
      value: PageThumbnailAction.delete,
      foregroundColor: scheme.error,
    ),
  ];
}

PopupMenuItem<PageThumbnailAction> _menuRow({
  required IconData icon,
  required String label,
  required PageThumbnailAction value,
  Color? foregroundColor,
}) {
  return PopupMenuItem(
    value: value,
    padding: EdgeInsets.zero,
    height: PageThumbnailMenuRow.menuItemHeight,
    child: PageThumbnailMenuRow(
      icon: icon,
      label: label,
      foregroundColor: foregroundColor,
    ),
  );
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
    this.borderColor,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppRadius.smBorder,
        border: borderColor != null
            ? Border.all(color: borderColor!)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 12, color: foreground),
              const SizedBox(width: 3),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: foreground,
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

