import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// 内容区顶栏（surface 底 + 底部分割线 + M3 排版）。
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.titleTrailing,
    this.subtitle,
    this.actions = const [],
  });

  final String title;
  final Widget? titleTrailing;
  final String? subtitle;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final padding = AppSpacing.pagePadding(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: scheme.outline)),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          padding.left,
          16,
          padding.right,
          12,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (titleTrailing != null) ...[
                      const SizedBox(width: 8),
                      titleTrailing!,
                    ],
                  ],
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            );

            if (actions.isEmpty) return titleBlock;

            final stacked = constraints.maxWidth < 520;
            if (stacked) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  titleBlock,
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: actions),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: titleBlock),
                ...actions,
              ],
            );
          },
        ),
      ),
    );
  }
}
