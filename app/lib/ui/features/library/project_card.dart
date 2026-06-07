import 'dart:io';

import 'package:comic_book_maker/ui/core/design_system/hover_reveal_menu.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:intl/intl.dart';

enum _ProjectCardMenuAction { delete }

/// 漫画库项目卡片：封面 + 标题区；桌面悬停 ⋮，移动端长按菜单。
class ProjectCard extends StatefulWidget {
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
  static const double footerHeightEstimate = 72;

  static final _updatedAtFormat = DateFormat('yyyy年MM月dd日 HH:mm');

  static String formatUpdatedAt(DateTime time) => _updatedAtFormat.format(time);

  /// 根据单列卡片宽度估算网格宽高比。
  static double gridChildAspectRatioForCellWidth(double cellWidth) {
    final coverHeight = cellWidth / coverAspectRatio;
    return cellWidth / (coverHeight + footerHeightEstimate);
  }

  @override
  State<ProjectCard> createState() => _ProjectCardState();
}

class _ProjectCardState extends State<ProjectCard> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final formatted = ProjectCard.formatUpdatedAt(widget.updatedAt);
    final hasCover = _hasValidCover(widget.coverThumbnailPath);
    final showHoverChrome = _hovered && !isCompact(context);
    final borderColor = showHoverChrome
        ? scheme.onSurfaceVariant.withValues(alpha: 0.45)
        : scheme.outline;

    Widget coverContent = hasCover
        ? _CoverImage(path: widget.coverThumbnailPath!)
        : _CoverPlaceholder(scheme: scheme);

    final menuButtonStyle = RevealMenuButtonStyle(
      iconColor: scheme.onSurface,
      backgroundColor: scheme.surface.withValues(alpha: 0.92),
    );

    if (widget.onDelete != null) {
      coverContent = HoverRevealMenuAnchor<_ProjectCardMenuAction>(
        buttonTop: 8,
        buttonRight: 8,
        menuButtonStyle: menuButtonStyle,
        onSelected: (_) => widget.onDelete!(),
        menuItemsBuilder: (context) => [
          PopupMenuItem(
            value: _ProjectCardMenuAction.delete,
            child: Row(
              children: [
                Icon(LucideIcons.trash2, size: 20, color: scheme.error),
                const SizedBox(width: 12),
                Text('删除', style: TextStyle(color: scheme.error)),
              ],
            ),
          ),
        ],
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            child: coverContent,
          ),
        ),
      );
    } else {
      coverContent = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: coverContent,
        ),
      );
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: AppRadius.lgBorder,
          border: Border.all(color: borderColor),
          boxShadow: showHoverChrome
              ? [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: coverContent),
            Material(
              color: scheme.surfaceContainerLow,
              child: InkWell(
                onTap: widget.onTap,
                child: _CardFooter(
                  title: widget.title,
                  subtitle: '${widget.activityLabel} · $formatted',
                  theme: theme,
                  scheme: scheme,
                ),
              ),
            ),
          ],
        ),
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
    required this.theme,
    required this.scheme,
  });

  final String title;
  final String subtitle;
  final ThemeData theme;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
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
        color: scheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      child: Center(
        child: Icon(
          LucideIcons.bookOpen,
          size: 32,
          color: scheme.onSurfaceVariant.withValues(alpha: 0.65),
        ),
      ),
    );
  }
}
