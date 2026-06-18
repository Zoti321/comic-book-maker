import 'package:flutter/material.dart';

/// 漫画库空状态（Material 排版 + FilledButton 主操作）。
class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({
    super.key,
    required this.onCreateProject,
    this.showAction = true,
  });

  final VoidCallback onCreateProject;
  final bool showAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.folder_open_outlined,
                size: 64,
                color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
              ),
              const SizedBox(height: 20),
              Text(
                '还没有项目',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '通过新建项目向导导入图片或漫画包开始制作',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              if (showAction) ...[
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: onCreateProject,
                  icon: const Icon(Icons.add),
                  label: const Text('新建项目'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
