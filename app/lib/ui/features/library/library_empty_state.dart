import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

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
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  border: Border.all(color: scheme.outline),
                ),
                child: Icon(
                  LucideIcons.library,
                  size: 32,
                  color: scheme.onSurfaceVariant,
                ),
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
                  style: _libraryCompactFilledButtonStyle(context),
                  icon: const Icon(LucideIcons.plus, size: 16),
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

/// 顶栏与空状态共用的紧凑 FilledButton 样式（对齐原 AppButtonSize.sm）。
ButtonStyle _libraryCompactFilledButtonStyle(BuildContext context) {
  return FilledButton.styleFrom(
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    minimumSize: const Size(0, AppTypography.controlHeightCompact),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: Theme.of(context).textTheme.labelLarge,
  );
}

ButtonStyle libraryCompactFilledButtonStyle(BuildContext context) =>
    _libraryCompactFilledButtonStyle(context);
