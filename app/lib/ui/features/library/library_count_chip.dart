import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// 漫画库标题旁的项目数量 pill（仅数字）。
class LibraryCountChip extends StatelessWidget {
  const LibraryCountChip({
    super.key,
    required this.count,
  });

  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: AppRadius.mdBorder,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Text(
          '$count',
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}
