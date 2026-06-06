import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_state.dart';
import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/core/design_system/design_system.dart';
import 'package:comic_book_maker/domain/use_cases/page_import_rules.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_settings_bar.dart';
import 'package:flutter/material.dart';

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

  static const toolbarPreferredSize = Size.fromHeight(kToolbarHeight);

  @override
  Size get preferredSize => toolbarPreferredSize;

  @override
  Widget build(BuildContext context) {
    final exportFormat =
        workspace.settings?.exportFormat ?? ExportFormatFrb.comicArchive;
    final useWideActions = !isCompact(context);

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        tooltip: '返回漫画库',
        onPressed: onBack,
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            workspace.project.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (workspace.pages.isNotEmpty)
            Text(
              '${workspace.pages.length} 页',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final tooltip = enabled
        ? label
        : appendImportBlockedReason(kind).isNotEmpty
            ? appendImportBlockedReason(kind)
            : '当前无法追加导入';

    if (showLabel) {
      return Tooltip(
        message: tooltip,
        child: AppButton(
          variant: AppButtonVariant.outline,
          onPressed: enabled ? onPressed : null,
          icon: const Icon(Icons.download_outlined, size: 18),
          child: Text(label),
        ),
      );
    }

    return AppIconButton(
      tooltip: tooltip,
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.download_outlined),
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
    final isPdf = exportFormat == ExportFormatFrb.pdf;
    final tooltip = isPdf
        ? 'PDF Export 尚未实现'
        : '导出为 ${exportFormatLabel(exportFormat)}';

    if (showLabel) {
      return Tooltip(
        message: tooltip,
        child: AppButton(
          onPressed: workspace.canExport ? onPressed : null,
          icon: const Icon(Icons.upload_outlined, size: 18),
          child: const Text('导出'),
        ),
      );
    }

    return AppIconButton(
      variant: AppIconButtonVariant.filled,
      tooltip: tooltip,
      onPressed: workspace.canExport ? onPressed : null,
      icon: const Icon(Icons.upload_outlined),
    );
  }
}

/// 编辑页 Tab（与 [IndexedStack] / 分段按钮顺序一致）。
enum ProjectEditorTab { images, metadata }
