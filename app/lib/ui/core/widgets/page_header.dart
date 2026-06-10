import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

/// 内容区顶栏（surface 底 + 底部轻阴影 + M3 排版）。
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

  static const _contentMinHeight = AppTypography.controlHeightCompact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final padding = AppSpacing.pagePadding(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: const [AppElevation.headerShadow],
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          padding.left,
          AppSpacing.md,
          padding.right,
          AppSpacing.md,
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            // IndexedStack 离屏分支在过渡帧可能得到极窄约束，跳过 actions 避免按钮被压扁。
            final showActions = constraints.maxWidth >= 64;

            final titleBlock = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _titleRow(theme: theme, scheme: scheme),
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

            if (actions.isEmpty || !showActions) return titleBlock;

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

            return ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _contentMinHeight),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(child: titleBlock),
                  ...actions,
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _titleRow({
    required ThemeData theme,
    required ColorScheme scheme,
  }) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: _contentMinHeight),
      child: Row(
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
    );
  }
}
