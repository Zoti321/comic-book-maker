import 'dart:io';

import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/core/design_system/design_system.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

const _thumbAspectRatio = 2 / 3;
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

/// 按可用宽度计算缩略图边长（自适应列数）。
double pageThumbnailWidthFor(double availableWidth) {
  const minThumb = 96.0;
  const maxThumb = 128.0;
  if (availableWidth <= 0) return maxThumb;

  var columns = ((availableWidth + _gridSpacing) / (minThumb + _gridSpacing))
      .floor();
  columns = columns.clamp(2, 8);
  final width =
      (availableWidth - _gridSpacing * (columns - 1)) / columns;
  return width.clamp(minThumb, maxThumb);
}

/// 图片 Tab：Wrap 网格展示有序 Page 缩略图。
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
        final thumbWidth = pageThumbnailWidthFor(constraints.maxWidth);

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
            SliverToBoxAdapter(
              child: Wrap(
                spacing: _gridSpacing,
                runSpacing: _gridSpacing,
                children: [
                  for (var i = 0; i < sorted.length; i++)
                    _PageThumbnailTile(
                      page: sorted[i],
                      thumbWidth: thumbWidth,
                      isCover: sorted[i].sortIndex == coverPageIndex,
                      canMoveEarlier: i > 0,
                      canMoveLater: i < sorted.length - 1,
                      onViewOriginal: () => onViewOriginal(sorted[i]),
                      onAction: (action) => _dispatchAction(
                        action,
                        sorted[i],
                        onReplace: onReplace,
                        onDelete: onDelete,
                        onSetCover: onSetCover,
                        onViewOriginal: onViewOriginal,
                        onMoveEarlier: onMoveEarlier,
                        onMoveLater: onMoveLater,
                      ),
                    ),
                  _AddPageTile(
                    thumbWidth: thumbWidth,
                    onAdd: onAdd,
                  ),
                ],
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
  const _AddPageTile({
    required this.thumbWidth,
    required this.onAdd,
  });

  final double thumbWidth;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final thumbHeight = thumbWidth / _thumbAspectRatio;

    return SizedBox(
      width: thumbWidth,
      height: thumbHeight,
      child: Material(
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgBorder,
          side: BorderSide(color: scheme.outline),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onAdd,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_photo_alternate_outlined,
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
      ),
    );
  }
}

class _PageThumbnailTile extends StatelessWidget {
  const _PageThumbnailTile({
    required this.page,
    required this.thumbWidth,
    required this.isCover,
    required this.canMoveEarlier,
    required this.canMoveLater,
    required this.onViewOriginal,
    required this.onAction,
  });

  final PageSummary page;
  final double thumbWidth;
  final bool isCover;
  final bool canMoveEarlier;
  final bool canMoveLater;
  final VoidCallback onViewOriginal;
  final ValueChanged<PageThumbnailAction> onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final thumbHeight = thumbWidth / _thumbAspectRatio;
    final menuButtonStyle = RevealMenuButtonStyle(
      iconColor: scheme.onSurface,
      backgroundColor: scheme.surface.withValues(alpha: 0.92),
    );

    return SizedBox(
      width: thumbWidth,
      child: Material(
        color: scheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.lgBorder,
          side: BorderSide(
            color: isCover
                ? scheme.onSurface
                : scheme.outline,
            width: isCover ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: HoverRevealMenuAnchor<PageThumbnailAction>(
          buttonTop: 6,
          buttonRight: 6,
          menuButtonStyle: menuButtonStyle,
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
              children: [
                SizedBox(
                  width: thumbWidth,
                  height: thumbHeight,
                  child: _PageThumbnailImage(page: page),
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
                      icon: Icons.bookmark_outline,
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
      icon: Icons.zoom_in_outlined,
      label: '查看原图',
      value: PageThumbnailAction.view,
    ),
    _menuRow(
      icon: Icons.swap_horiz_outlined,
      label: '替换图片',
      value: PageThumbnailAction.replace,
    ),
    if (!isCover)
      _menuRow(
        icon: Icons.bookmark_outline,
        label: '设为封面',
        value: PageThumbnailAction.setCover,
      ),
    if (canMoveEarlier)
      _menuRow(
        icon: Icons.arrow_back_outlined,
        label: '前移',
        value: PageThumbnailAction.moveEarlier,
      ),
    if (canMoveLater)
      _menuRow(
        icon: Icons.arrow_forward_outlined,
        label: '后移',
        value: PageThumbnailAction.moveLater,
      ),
    const PopupMenuDivider(),
    _menuRow(
      icon: Icons.delete_outline,
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
    child: Row(
      children: [
        Icon(icon, size: 20, color: foregroundColor),
        const SizedBox(width: 12),
        Text(
          label,
          style: foregroundColor != null ? TextStyle(color: foregroundColor) : null,
        ),
      ],
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
  const _PageThumbnailImage({required this.page});

  final PageSummary page;

  @override
  Widget build(BuildContext context) {
    return Image.file(
      File(page.absolutePath),
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainer,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            size: 28,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

Future<void> showPageImageViewer(
  BuildContext context,
  PageSummary page,
) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (context) => Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            minScale: 0.5,
            maxScale: 5,
            child: Center(
              child: Image.file(
                File(page.absolutePath),
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.broken_image_outlined,
                  color: Colors.white54,
                  size: 64,
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: AppIconButton(
                  variant: AppIconButtonVariant.tonal,
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  tooltip: '关闭',
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '第 ${page.sortIndex + 1} 页',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white70,
                      ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
