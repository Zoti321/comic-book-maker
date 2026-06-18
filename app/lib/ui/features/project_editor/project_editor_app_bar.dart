import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_state.dart';
import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/use_cases/page_import_rules.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/widgets/ellipsis_tooltip_text.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_settings_bar.dart';
import 'package:flutter/material.dart';

/// Project 编辑页顶栏：返回 + 项目标题 · 页数 + 导出 / 追加导入 / 项目属性。
class ProjectEditorAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ProjectEditorAppBar({
    super.key,
    required this.workspace,
    required this.onExport,
    required this.onAppendImport,
    required this.onOpenProjectProperties,
    required this.onBack,
  });

  final ProjectWorkspaceState workspace;
  final VoidCallback onExport;
  final VoidCallback onAppendImport;
  final VoidCallback onOpenProjectProperties;
  final VoidCallback onBack;

  static const toolbarPreferredSize = Size.fromHeight(kToolbarHeight);

  @override
  Size get preferredSize => toolbarPreferredSize;

  String _headerTitle(int pageCount) {
    final title = workspace.project.title;
    if (pageCount <= 0) return title;
    return '$title · $pageCount 页';
  }

  @override
  Widget build(BuildContext context) {
    final exportFormat =
        workspace.settings?.exportFormat ?? ExportFormatFrb.comicArchive;
    final useWideActions = !isCompact(context);
    final pageCount = workspace.pages.length;
    final theme = Theme.of(context);

    return AppBar(
      surfaceTintColor: Colors.transparent,
      leadingWidth: 48,
      leading: IconButton(
        onPressed: onBack,
        icon: const Icon(Icons.arrow_back),
        style: IconButton.styleFrom(
          visualDensity: VisualDensity.compact,
        ),
      ),
      title: EllipsisTooltipText(
        text: _headerTitle(pageCount),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
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
        const SizedBox(width: 4),
        _ProjectPropertiesButton(onPressed: onOpenProjectProperties),
        const SizedBox(width: 8),
      ],
    );
  }
}

ButtonStyle _desktopFilledButtonStyle(BuildContext context) {
  return FilledButton.styleFrom(
    minimumSize: const Size(0, 40),
    padding: const EdgeInsets.symmetric(horizontal: 24),
    textStyle: Theme.of(context).textTheme.labelLarge,
  );
}

ButtonStyle _desktopOutlinedButtonStyle(BuildContext context) {
  return OutlinedButton.styleFrom(
    minimumSize: const Size(0, 40),
    padding: const EdgeInsets.symmetric(horizontal: 24),
    textStyle: Theme.of(context).textTheme.labelLarge,
  );
}

ButtonStyle _compactCircularIconButtonStyle() {
  return IconButton.styleFrom(
    visualDensity: VisualDensity.compact,
    shape: const CircleBorder(),
  );
}

class _ProjectPropertiesButton extends StatelessWidget {
  const _ProjectPropertiesButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: '项目属性',
      icon: const Icon(Icons.settings_outlined),
      style: _compactCircularIconButtonStyle(),
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

    if (showLabel) {
      final button = OutlinedButton.icon(
        onPressed: enabled ? onPressed : null,
        style: _desktopOutlinedButtonStyle(context),
        icon: const Icon(Icons.file_download_outlined, size: 18),
        label: Text(label),
      );
      if (disabledTooltip != null) {
        return Tooltip(message: disabledTooltip, child: button);
      }
      return button;
    }

    final iconButton = IconButton(
      onPressed: enabled ? onPressed : null,
      icon: const Icon(Icons.file_download_outlined),
      style: _compactCircularIconButtonStyle(),
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
        style: _desktopFilledButtonStyle(context),
        icon: const Icon(Icons.file_upload_outlined, size: 18),
        label: const Text('导出'),
      );
    }

    final iconButton = IconButton(
      onPressed: canExport ? onPressed : null,
      icon: const Icon(Icons.file_upload_outlined),
      style: _compactCircularIconButtonStyle(),
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
