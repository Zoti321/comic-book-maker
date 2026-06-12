import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_state.dart';
import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/core/design_system/design_system.dart';
import 'package:comic_book_maker/domain/use_cases/page_import_rules.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_settings_bar.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Project 编辑页顶栏：返回 + 导出 / 追加导入。
class ProjectEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProjectEditorAppBar({
    super.key,
    required this.workspace,
    required this.onExport,
    required this.onAppendImport,
    required this.onBack,
  });

  final ProjectWorkspaceState workspace;
  final VoidCallback onExport;
  final VoidCallback onAppendImport;
  final VoidCallback onBack;

  static const toolbarPreferredSize = Size.fromHeight(kToolbarHeight + 1);

  @override
  Size get preferredSize => toolbarPreferredSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final exportFormat =
        workspace.settings?.exportFormat ?? ExportFormatFrb.comicArchive;
    final useWideActions = !isCompact(context);

    return AppBar(
      surfaceTintColor: Colors.transparent,
      leadingWidth: 48,
      leading: AppIconButton(
        size: AppButtonSize.sm,
        radius: AppButtonRadius.circle,
        metrics: const AppButtonMetrics(iconSize: 18),
        icon: const Icon(LucideIcons.arrowLeft),
        onPressed: onBack,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workspace.project.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          if (workspace.pages.isNotEmpty)
            Text(
              '${workspace.pages.length} 页',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      actions: [
        _ExportButton(
          workspace: workspace,
          exportFormat: exportFormat,
          showLabel: useWideActions,
          onPressed: onExport,
        ),
        const SizedBox(width: 4),
        _AppendImportButton(
          workspace: workspace,
          showLabel: useWideActions,
          onPressed: onAppendImport,
        ),
        const SizedBox(width: 8),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(height: 1, color: scheme.outline),
      ),
    );
  }
}

class _AppendImportButton extends StatelessWidget {
  const _AppendImportButton({
    required this.workspace,
    required this.showLabel,
    required this.onPressed,
  });

  final ProjectWorkspaceState workspace;
  final bool showLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final kind =
        workspace.settings?.inferredImportKind ?? InferredImportKindFrb.images;
    final label = appendImportActionLabel(kind);
    final enabled = workspace.canAppendImport;
    final disabledTooltip = !enabled
        ? appendImportBlockedReason(kind).isNotEmpty
            ? appendImportBlockedReason(kind)
            : '当前无法追加导入'
        : null;

    final button = AppButton(
      variant: AppButtonVariant.secondary,
      onPressed: enabled ? onPressed : null,
      icon: const Icon(LucideIcons.download, size: 18),
      child: Text(label),
    );

    if (showLabel) {
      if (disabledTooltip != null) {
        return Tooltip(message: disabledTooltip, child: button);
      }
      return button;
    }

    return AppIconButton(
      variant: AppButtonVariant.secondary,
      tooltip: enabled ? label : null,
      disabledTooltip: disabledTooltip,
      onPressed: enabled ? onPressed : null,
      icon: const Icon(LucideIcons.download),
    );
  }
}

class _ExportButton extends StatelessWidget {
  const _ExportButton({
    required this.workspace,
    required this.exportFormat,
    required this.showLabel,
    required this.onPressed,
  });

  final ProjectWorkspaceState workspace;
  final ExportFormatFrb exportFormat;
  final bool showLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final canExport = workspace.canExport;

    final button = AppButton(
      onPressed: canExport ? onPressed : null,
      icon: const Icon(LucideIcons.upload, size: 18),
      child: const Text('导出'),
    );

    if (showLabel) {
      return button;
    }

    return AppIconButton(
      variant: AppButtonVariant.primary,
      tooltip: canExport ? '导出为 ${exportFormatLabel(exportFormat)}' : null,
      onPressed: canExport ? onPressed : null,
      icon: const Icon(LucideIcons.upload),
    );
  }
}

/// 编辑页 Tab（与 [IndexedStack] / 分段按钮顺序一致）。
enum ProjectEditorTab { images, metadata }
