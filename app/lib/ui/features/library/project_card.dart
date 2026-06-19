import 'dart:io';

import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:comic_book_maker/ui/core/widgets/app_surface_ink_well.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// 漫画库项目卡片：M3 Elevated [Card] + 封面区 overflow 菜单。
class ProjectCard extends HookWidget {
  const ProjectCard({
    super.key,
    required this.title,
    required this.onTap,
    this.onDelete,
    this.coverThumbnailPath,
  });

  final String title;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final String? coverThumbnailPath;

  /// 封面宽高比。
  static const double coverAspectRatio = 3 / 4;

  /// 标题区预估高度，用于计算网格 [childAspectRatio]（单行标题 + 状态标签）。
  static const double footerHeightEstimate = 56;

  static const _restElevation = 1.0;
  static const _hoverElevation = 2.0;
  static const _menuMinWidth = 200.0;

  static final _cardShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.lg),
  );

  static final _cardMenuStyle = MenuStyle(
    minimumSize: WidgetStatePropertyAll(Size(_menuMinWidth, 0)),
  );

  static final _overflowIconButtonStyle = IconButton.styleFrom(
    shape: const CircleBorder(),
    visualDensity: VisualDensity.compact,
  );

  /// 根据单列卡片宽度估算网格宽高比。
  static double gridChildAspectRatioForCellWidth(double cellWidth) {
    final coverHeight = cellWidth / coverAspectRatio;
    return cellWidth / (coverHeight + footerHeightEstimate);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final compact = isCompact(context);
    final hovered = useState(false);
    final menuController = useMemoized(MenuController.new);
    final hasCover = _hasValidCover(coverThumbnailPath);
    final showMenuButton = onDelete != null && hovered.value && !compact;

    final elevation = hovered.value && !compact
        ? _hoverElevation
        : _restElevation;

    final deleteMenuItem = MenuItemButton(
      style: MenuItemButton.styleFrom(
        minimumSize: const Size(_menuMinWidth, 48),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      ),
      onPressed: () {
        menuController.close();
        onDelete?.call();
      },
      child: Row(
        children: [
          Icon(Icons.delete_outline, size: 20, color: scheme.error),
          const SizedBox(width: AppSpacing.sm),
          Text('删除', style: TextStyle(color: scheme.error)),
        ],
      ),
    );

    final coverContent = hasCover
        ? _CoverImage(path: coverThumbnailPath!)
        : _CoverPlaceholder(scheme: scheme);

    return MouseRegion(
      onEnter: (_) => hovered.value = true,
      onExit: (_) => hovered.value = false,
      cursor: SystemMouseCursors.click,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: elevation,
        shadowColor: scheme.shadow,
        surfaceTintColor: Colors.transparent,
        margin: EdgeInsets.zero,
        color: scheme.surface,
        shape: _cardShape,
        child: Stack(
          children: [
            Positioned.fill(
              child: AppSurfaceInkWell(
                preset: AppSurfaceInkPreset.libraryCard,
                onTap: onTap,
                onLongPress: onDelete != null && compact
                    ? () => _showCompactDeleteMenu(context)
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(child: coverContent),
                    _CardFooter(
                      title: title,
                      subtitle: '最近打开',
                    ),
                  ],
                ),
              ),
            ),
            if (onDelete != null && !compact)
              Positioned(
                top: 4,
                right: 4,
                child: IgnorePointer(
                  ignoring: !showMenuButton,
                  child: Opacity(
                    opacity: showMenuButton ? 1 : 0,
                    child: MenuAnchor(
                      controller: menuController,
                      style: _cardMenuStyle,
                      menuChildren: [deleteMenuItem],
                      builder: (context, controller, child) {
                        return IconButton(
                          icon: const Icon(Icons.more_vert),
                          tooltip: '更多',
                          style: _overflowIconButtonStyle,
                          onPressed: () {
                            if (controller.isOpen) {
                              controller.close();
                            } else {
                              controller.open();
                            }
                          },
                        );
                      },
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showCompactDeleteMenu(BuildContext context) async {
    if (onDelete == null) return;

    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;

    final overlay =
        Overlay.of(context).context.findRenderObject() as RenderBox;
    final topRight = box.localToGlobal(
      Offset(box.size.width, 0),
      ancestor: overlay,
    );
    final position = RelativeRect.fromLTRB(
      topRight.dx,
      topRight.dy,
      overlay.size.width - topRight.dx,
      overlay.size.height - topRight.dy,
    );

    await showMenu<void>(
      context: context,
      position: position,
      constraints: const BoxConstraints(minWidth: _menuMinWidth),
      items: [
        PopupMenuItem<void>(
          onTap: onDelete,
          child: Row(
            children: [
              Icon(
                Icons.delete_outline,
                size: 20,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                '删除',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  bool _hasValidCover(String? path) {
    if (path == null || path.isEmpty) return false;
    return File(path).existsSync();
  }
}

class _CardFooter extends StatelessWidget {
  const _CardFooter({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: title,
            waitDuration: const Duration(milliseconds: 400),
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Image.file(
      File(path),
      fit: BoxFit.cover,
      alignment: Alignment.center,
      filterQuality: FilterQuality.medium,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => _CoverPlaceholder(scheme: scheme),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(
          Icons.image_outlined,
          size: 32,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}
