import 'dart:io';

import 'package:comic_book_maker/ui/design_system/hover_reveal_menu.dart';
import 'package:comic_book_maker/ui/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

enum _ProjectCardMenuAction { delete }

/// 漫画库项目卡片：封面菜单 — 桌面悬停 ⋮，移动端长按菜单。
class ProjectCard extends StatelessWidget {
  const ProjectCard({
    super.key,
    required this.title,
    required this.updatedAt,
    required this.onTap,
    this.onDelete,
    this.coverThumbnailPath,
    this.activityLabel = '更新于',
  });

  final String title;
  final DateTime updatedAt;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final String? coverThumbnailPath;
  final String activityLabel;

  /// 封面宽高比（漫画常见 2:3）。
  static const double coverAspectRatio = 2 / 3;

  /// 标题区预估高度，用于计算网格 [childAspectRatio]（含内边距，略留余量防亚像素溢出）。
  static const double footerHeightEstimate = 68;

  static final _updatedAtFormat = DateFormat('yyyy年MM月dd日 HH:mm');

  static String formatUpdatedAt(DateTime time) => _updatedAtFormat.format(time);

  /// 根据单列卡片宽度估算网格宽高比。
  static double gridChildAspectRatioForCellWidth(double cellWidth) {
    final coverHeight = cellWidth / coverAspectRatio;
    return cellWidth / (coverHeight + footerHeightEstimate);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final formatted = formatUpdatedAt(updatedAt);
    final hasCover = _hasValidCover(coverThumbnailPath);
    final radius = AppRadius.lgBorder;
    final shape = RoundedRectangleBorder(
      borderRadius: radius,
      side: BorderSide(color: scheme.outline),
    );

    Widget coverContent = hasCover
        ? _CoverImage(path: coverThumbnailPath!)
        : _CoverPlaceholder(scheme: scheme);

    if (onDelete != null) {
      coverContent = HoverRevealMenuAnchor<_ProjectCardMenuAction>(
        buttonTop: 6,
        buttonRight: 6,
        menuIconColor: hasCover ? Colors.white : scheme.onSurface,
        onSelected: (_) => onDelete!(),
        menuItemsBuilder: (context) => [
          PopupMenuItem(
            value: _ProjectCardMenuAction.delete,
            child: Row(
              children: [
                Icon(Icons.delete_outline, size: 20, color: scheme.error),
                const SizedBox(width: 12),
                Text('删除', style: TextStyle(color: scheme.error)),
              ],
            ),
          ),
        ],
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: coverContent,
          ),
        ),
      );
    } else {
      coverContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: coverContent,
        ),
      );
    }

    return Material(
      color: scheme.surface,
      elevation: 0,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: coverContent),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              child: _CardFooter(
                title: title,
                subtitle: '$activityLabel · $formatted',
              ),
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
      ),
      child: Center(
        child: Icon(
          Icons.auto_stories_outlined,
          size: 36,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.7),
        ),
      ),
    );
  }
}
