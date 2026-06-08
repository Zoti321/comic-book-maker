import 'dart:io';

import 'package:comic_book_maker/ui/core/design_system/hover_reveal_menu.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/theme/app_colors.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum _ProjectCardMenuAction { delete }

/// 漫画库项目卡片：封面 + 标题区；桌面悬停 ⋮，移动端长按菜单。
class ProjectCard extends StatefulWidget {
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
  var _pressedFooter = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hasCover = _hasValidCover(widget.coverThumbnailPath);
    final showHoverChrome = _hovered && !isCompact(context);
    final borderColor =
        showHoverChrome ? AppColors.outlineVariant : AppColors.outline;

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
        child: coverContent,
      );
    } else {
      // 无删除菜单时，保持封面简单，由外层统一处理点击。
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        onTapDown: (_) => setState(() => _pressedFooter = true),
        onTapUp: (_) => setState(() => _pressedFooter = false),
        onTapCancel: () => setState(() => _pressedFooter = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.smBorder,
            border: Border.all(color: borderColor),
            boxShadow: showHoverChrome
                ? const [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(AppRadius.sm),
                  ),
                  child: coverContent,
                ),
              ),
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(AppRadius.sm),
                ),
                child: _CardFooter(
                  title: widget.title,
                  subtitle: '最近打开',
                  isPressed: _pressedFooter,
                ),
              ),
            ],
          ),
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
    required this.isPressed,
  });

  final String title;
  final String subtitle;
  final bool isPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isPressed ? AppColors.surfaceLow : AppColors.surface,
      ),
      child: Padding(
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
