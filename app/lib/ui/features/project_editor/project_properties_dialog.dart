import 'dart:async';

import 'package:comic_book_maker/ui/features/library/providers/library_provider.dart';
import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_provider.dart';
import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/core/design_system/design_system.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_settings_bar.dart';
import 'package:comic_book_maker/ui/features/settings/export_settings_layout.dart';
import 'package:comic_book_maker/ui/features/settings/project_export_settings_panel.dart';
import 'package:comic_book_maker/ui/core/project_settings_update.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_dialog_shell.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_feature_dialog.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 查看 / 调整项目属性（侧边 Tab：概览 / 导入 / 导出 / 元数据）。
Future<void> showProjectPropertiesDialog({
  required BuildContext context,
  required String projectId,
}) {
  return showAppFeatureDialog<void>(
    context: context,
    builder: (dialogContext) => _ProjectPropertiesDialog(
      projectId: projectId,
      dialogContext: dialogContext,
    ),
  );
}

class _ProjectPropertiesDialog extends HookConsumerWidget {
  const _ProjectPropertiesDialog({
    required this.projectId,
    required this.dialogContext,
  });

  final String projectId;
  final BuildContext dialogContext;

  static const _tabs = [
    SideTabDialogTab(label: '概览', icon: LucideIcons.info),
    SideTabDialogTab(label: '导入', icon: LucideIcons.download),
    SideTabDialogTab(label: '导出', icon: LucideIcons.upload),
    SideTabDialogTab(label: '元数据', icon: LucideIcons.fileText),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabIndex = useState(0);
    final workspace = ref.watch(projectWorkspaceProvider(projectId));
    final notifier = ref.read(projectWorkspaceProvider(projectId).notifier);
    final settings = workspace.settings;
    final saving = workspace.savingExportFormat;

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
      } catch (_) {}
    }

    if (settings == null) {
      return AppDialog(
        title: '项目属性',
        content: const SizedBox(
          height: 200,
          child: AppPageLoading(message: '正在加载项目设置…', compact: true),
        ),
        actions: [
          AppButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('关闭'),
          ),
        ],
      );
    }

    final Widget panel = switch (tabIndex.value) {
      0 => _OverviewTab(projectId: projectId),
      1 => _ImportTab(
          settings: settings,
          saving: saving,
          onImportKindChanged: onImportKindChanged,
        ),
      2 => ProjectExportSettingsPanel(
          settings: settings,
          enabled: !saving,
          layout: ExportSettingsLayout.horizontal,
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
      _ => _MetadataTab(settings: settings),
    };

    return SideTabFeatureDialog(
      title: '项目属性',
      tabs: _tabs,
      selectedIndex: tabIndex.value,
      onTabSelected: (index) => tabIndex.value = index,
      body: SingleChildScrollView(child: panel),
      actions: [
        AppButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('关闭'),
        ),
      ],
    );
  }
}

String _formatDateTime(DateTime dt) {
  final local = dt.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${local.year}-${two(local.month)}-${two(local.day)} '
      '${two(local.hour)}:${two(local.minute)}';
}

class _OverviewTab extends HookConsumerWidget {
  const _OverviewTab({required this.projectId});

  final String projectId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspace = ref.watch(projectWorkspaceProvider(projectId));
    final notifier = ref.read(projectWorkspaceProvider(projectId).notifier);
    final titleController = useTextEditingController(text: workspace.project.title);
    final titleFocusNode = useFocusNode();
    final savingTitle = useState(false);
    final titleError = useState<String?>(null);

    useEffect(() {
      if (titleController.text != workspace.project.title) {
        titleController.text = workspace.project.title;
      }
      return null;
    }, [workspace.project.title]);

    Future<void> saveTitle() async {
      final trimmed = titleController.text.trim();
      if (trimmed.isEmpty) {
        titleError.value = '项目名称不能为空';
        return;
      }
      if (trimmed == workspace.project.title) {
        titleError.value = null;
        return;
      }

      savingTitle.value = true;
      titleError.value = null;
      try {
        notifier.renameProjectTitle(trimmed);
        ref.read(libraryProjectsProvider.notifier).reload();
      } catch (e) {
        titleError.value = e.toString();
      } finally {
        savingTitle.value = false;
      }
    }

    useEffect(() {
      void onFocusChange() {
        if (!titleFocusNode.hasFocus) {
          unawaited(saveTitle());
        }
      }

      titleFocusNode.addListener(onFocusChange);
      return () => titleFocusNode.removeListener(onFocusChange);
    }, [titleFocusNode, workspace.project.title]);

    final updatedAt = DateTime.fromMillisecondsSinceEpoch(
      workspace.project.updatedAtMs.toInt(),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          controller: titleController,
          focusNode: titleFocusNode,
          label: '项目名称',
          enabled: !savingTitle.value,
          errorText: titleError.value,
        ),
        const SizedBox(height: 12),
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
    return AppSelect<InferredImportKindFrb>(
      key: ValueKey(settings.inferredImportKind),
      label: '导入格式',
      enabled: !saving,
      value: settings.inferredImportKind,
      onChanged: saving ? null : onImportKindChanged,
      items: [
        for (final kind in InferredImportKindFrb.values)
          AppSelectItem(
            value: kind,
            label: inferredImportKindLabel(kind),
            enabled: kind != InferredImportKindFrb.pdf,
          ),
      ],
    );
  }
}

class _MetadataTab extends StatelessWidget {
  const _MetadataTab({required this.settings});

  final ProjectSettings settings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '导入时已将归档元数据映射为应用内 canonical 字段并写入数据库。',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          '查看与编辑书目元数据请前往项目编辑页的「元数据」Tab。',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 16),
        _PropertyRow(
          label: '推断导入类型',
          value: inferredImportKindLabel(settings.inferredImportKind),
        ),
        _PropertyRow(
          label: 'Export 格式',
          value: exportFormatLabel(settings.exportFormat),
        ),
      ],
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
