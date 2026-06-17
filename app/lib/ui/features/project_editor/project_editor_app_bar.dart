import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_state.dart';
import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/use_cases/page_import_rules.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:comic_book_maker/ui/core/widgets/ellipsis_tooltip_text.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_settings_bar.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Project 编辑页顶栏：返回 + 项目标题 / 页数 + 导出 / 追加导入。
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
    final pageCount = workspace.pages.length;

    return AppBar(
      surfaceTintColor: Colors.transparent,
      leadingWidth: 48,
      leading: IconButton(
        onPressed: onBack,
        icon: const Icon(LucideIcons.arrowLeft, size: 18),
        style: IconButton.styleFrom(
          visualDensity: VisualDensity.compact,
        ),
      ),
      title: Row(
        children: [
          Expanded(
            child: EllipsisTooltipText(
              text: workspace.project.title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (pageCount > 0) ...[
            const SizedBox(width: 8),
            Text(
              '$pageCount 页',
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
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

ButtonStyle _compactFilledButtonStyle(BuildContext context) {
  return FilledButton.styleFrom(
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    minimumSize: const Size(0, AppTypography.controlHeightCompact),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: Theme.of(context).textTheme.labelLarge,
  );
}

ButtonStyle _compactOutlinedButtonStyle(BuildContext context) {
  return OutlinedButton.styleFrom(
    visualDensity: VisualDensity.compact,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    minimumSize: const Size(0, AppTypography.controlHeightCompact),
    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    textStyle: Theme.of(context).textTheme.labelLarge,
  );
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

    if (showLabel) {
      final button = OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        style: _compactOutlinedButtonStyle(context),
        icon: const Icon(LucideIcons.download, size: 18),
        label: Text(label),
      );
      if (disabledTooltip != null) {
        return Tooltip(message: disabledTooltip, child: button);
      }
      return button;
    }

    final iconButton = IconButton(
      onPressed: enabled ? onPressed : null,
      icon: const Icon(LucideIcons.download),
      style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
    );
    if (disabledTooltip != null) {
      return Tooltip(message: disabledTooltip, child: iconButton);
    }
    if (enabled) {
      return Tooltip(message: label, child: iconButton);
    }
    return iconButton;
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

    if (showLabel) {
      return FilledButton.icon(
        onPressed: canExport ? onPressed : null,
        style: _compactFilledButtonStyle(context),
        icon: const Icon(LucideIcons.upload, size: 18),
        label: const Text('导出'),
      );
    }

    final iconButton = IconButton.filled(
      onPressed: canExport ? onPressed : null,
      icon: const Icon(LucideIcons.upload),
      style: IconButton.styleFrom(visualDensity: VisualDensity.compact),
    );
    if (canExport) {
      return Tooltip(
        message: '导出为 ${exportFormatLabel(exportFormat)}',
        child: iconButton,
      );
    }
    return iconButton;
  }
}

/// 编辑页 Tab（与 [IndexedStack] / 分段按钮顺序一致）。
enum ProjectEditorTab { images, metadata }
