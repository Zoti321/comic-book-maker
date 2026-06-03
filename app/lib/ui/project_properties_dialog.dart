import 'package:comic_book_maker/providers/project_workspace_provider.dart';
import 'package:comic_book_maker/providers/project_workspace_state.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/ui/design_system/design_system.dart';
import 'package:comic_book_maker/ui/import_metadata_preview.dart';
import 'package:comic_book_maker/ui/project_editor_settings_bar.dart';
import 'package:comic_book_maker/ui/project_export_settings_panel.dart';
import 'package:comic_book_maker/ui/project_settings_update.dart';
import 'package:comic_book_maker/ui/side_tab_dialog_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 查看 / 调整项目属性（侧边 Tab：概览 / 导入 / 导出 / 元数据）。
Future<void> showProjectPropertiesDialog({
  required BuildContext context,
  required String projectId,
}) {
  return showAppFeatureDialog<void>(
    context: context,
    builder: (dialogContext) => AppDialog(
      title: '项目属性',
      content: _ProjectPropertiesBody(projectId: projectId),
      actions: [
        AppButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('关闭'),
        ),
      ],
    ),
  );
}

class _ProjectPropertiesBody extends HookConsumerWidget {
  const _ProjectPropertiesBody({required this.projectId});

  final String projectId;

  static const _tabs = [
    SideTabDialogTab(label: '概览', icon: Icons.info_outline),
    SideTabDialogTab(label: '导入', icon: Icons.download_outlined),
    SideTabDialogTab(label: '导出', icon: Icons.upload_outlined),
    SideTabDialogTab(label: '元数据', icon: Icons.description_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = useState(0);
    final workspace = ref.watch(projectWorkspaceProvider(projectId));
    final notifier = ref.read(projectWorkspaceProvider(projectId).notifier);
    final settings = workspace.settings;
    final saving = workspace.savingExportFormat;

    final importSnapshot = useState<ImportMetadataSnapshotFrb?>(null);
    final importLoadError = useState<String?>(null);
    final importLoading = useState(true);

    Future<void> loadImportSnapshot() async {
      importLoading.value = true;
      importLoadError.value = null;
      try {
        importSnapshot.value =
            getImportMetadataSnapshot(projectId: projectId);
      } catch (e) {
        importSnapshot.value = null;
        importLoadError.value = e.toString();
      } finally {
        importLoading.value = false;
      }
    }

    useEffect(() {
      loadImportSnapshot();
      return null;
    }, [projectId, settings?.inferredImportKind]);

    Future<void> persistSettings(ProjectSettingsUpdate update) async {
      await notifier.saveProjectSettings(update);
    }

    Future<void> onImportKindChanged(InferredImportKindFrb? value) async {
      if (value == null || settings == null || saving) return;
      if (value == settings.inferredImportKind) return;
      if (value == InferredImportKindFrb.pdf) return;

      final confirmed = await showAppConfirmDialog(
        context: context,
        title: '更改导入格式',
        description: const Text(
          '更改导入格式将删除本项目中的全部页面与书目元数据，'
          '项目将变为空（无 Page Image、无可编辑元数据）。\n\n'
          '项目名称会保留。完成后请通过编辑页或图片 Tab 重新导入内容。\n\n'
          '此操作不可恢复，是否继续？',
        ),
        confirmLabel: '清空并更改',
        destructive: true,
      );
      if (confirmed != true || !context.mounted) return;

      try {
        await notifier.changeInferredImportKind(value);
        if (context.mounted) {
          await loadImportSnapshot();
        }
      } catch (_) {}
    }

    if (settings == null) {
      return const SizedBox(
        height: 200,
        child: AppPageLoading(message: '正在加载项目设置…', compact: true),
      );
    }

    final exampleName = workspace.project.title
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .trim();

    final Widget panel = switch (tabIndex.value) {
      0 => _OverviewTab(workspace: workspace),
      1 => _ImportTab(
          settings: settings,
          saving: saving,
          onImportKindChanged: onImportKindChanged,
        ),
      2 => ProjectExportSettingsPanel(
          settings: settings,
          enabled: !saving,
          exampleBaseName: exampleName.isEmpty ? '未命名' : exampleName,
          onExportFormatChanged: (format) => persistSettings(
            projectSettingsUpdateFrom(settings, exportFormat: format),
          ),
          onContainerChanged: (container) => persistSettings(
            projectSettingsUpdateFrom(
              settings,
              comicArchiveContainer: container,
            ),
          ),
          onUseComicExtensionChanged: (value) => persistSettings(
            projectSettingsUpdateFrom(
              settings,
              useComicArchiveExtension: value,
            ),
          ),
          onUseDefaultDirectoryChanged: (value) => persistSettings(
            projectSettingsUpdateFrom(
              settings,
              useDefaultExportDirectory: value,
              clearExportDirectory: value,
            ),
          ),
          onExportDirectoryChanged: (directory) => persistSettings(
            projectSettingsUpdateFrom(
              settings,
              useDefaultExportDirectory: false,
              exportDirectory: directory,
            ),
          ),
          onDeleteAfterExportChanged: (value) => persistSettings(
            projectSettingsUpdateFrom(
              settings,
              deleteProjectAfterExport: value,
            ),
          ),
        ),
      _ => _MetadataTab(
          settings: settings,
          snapshot: importSnapshot.value,
          loading: importLoading.value,
          loadError: importLoadError.value,
        ),
    };

    return SideTabDialogShell(
      selectedIndex: tabIndex.value,
      onTabSelected: (index) => tabIndex.value = index,
      tabs: _tabs,
      child: SingleChildScrollView(child: panel),
    );
  }
}

String _formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.workspace});

  final ProjectWorkspaceState workspace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final updatedAt = DateTime.fromMillisecondsSinceEpoch(
      workspace.project.updatedAtMs.toInt(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PropertyRow(label: '项目名称', value: workspace.project.title),
        _PropertyRow(
          label: '页面',
          value: workspace.pages.isEmpty
              ? '尚无页面'
              : '${workspace.pages.length} 页 · 封面第 ${workspace.coverPageIndex + 1} 页',
        ),
        _PropertyRow(
          label: '最近更新',
          value: _formatDateTime(updatedAt),
        ),
        const SizedBox(height: 8),
        Text(
          'Export 与导入格式请在「导出」「导入」Tab 中修改。',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _ImportTab extends StatelessWidget {
  const _ImportTab({
    required this.settings,
    required this.saving,
    required this.onImportKindChanged,
  });

  final ProjectSettings settings;
  final bool saving;
  final ValueChanged<InferredImportKindFrb?> onImportKindChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '导入格式决定追加 / 替换页面时可选择的文件类型。更改后将清空现有内容。',
          style: theme.textTheme.bodySmall?.copyWith(
            color: onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<InferredImportKindFrb>(
          key: ValueKey(settings.inferredImportKind),
          initialValue: settings.inferredImportKind,
          decoration: InputDecoration(
            labelText: '导入格式',
            enabled: !saving,
          ),
          items: InferredImportKindFrb.values
              .map(
                (kind) => DropdownMenuItem(
                  value: kind,
                  enabled: kind != InferredImportKindFrb.pdf,
                  child: Text(inferredImportKindLabel(kind)),
                ),
              )
              .toList(),
          onChanged: saving ? null : onImportKindChanged,
        ),
        const SizedBox(height: 12),
        Text(
          '本对话框不提供重新导入。清空后请在编辑页使用追加导入或图片 Tab 添加页面。',
          style: theme.textTheme.bodySmall?.copyWith(
            color: onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _MetadataTab extends StatelessWidget {
  const _MetadataTab({
    required this.settings,
    required this.snapshot,
    required this.loading,
    required this.loadError,
  });

  final ProjectSettings settings;
  final ImportMetadataSnapshotFrb? snapshot;
  final bool loading;
  final String? loadError;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const AppPageLoading(
        message: '正在读取导入元数据…',
        compact: true,
      );
    }

    if (loadError != null) {
      return Text('无法读取导入元数据：$loadError');
    }

    return ImportMetadataPreview(
      snapshot: snapshot!,
      inferredImportKind: settings.inferredImportKind,
      exportFormatLabel: exportFormatLabel(settings.exportFormat),
    );
  }
}

class _PropertyRow extends StatelessWidget {
  const _PropertyRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
