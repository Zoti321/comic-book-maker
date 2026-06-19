import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/models/create_project_draft.dart';
import 'package:comic_book_maker/domain/use_cases/archive_import_runner.dart';
import 'package:comic_book_maker/ui/features/create_project/providers/create_project_wizard_session_provider.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_settings_bar.dart';
import 'package:comic_book_maker/ui/features/settings/export_settings_layout.dart';
import 'package:comic_book_maker/ui/features/settings/project_export_settings_panel.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_dialog_shell.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const createProjectWizardTabs = [
  SideTabDialogTab(label: '导入', icon: Icons.download_outlined),
  SideTabDialogTab(label: '导出', icon: Icons.upload_outlined),
  SideTabDialogTab(label: '行为', icon: Icons.tune_outlined),
];

class CreateProjectWizardState {
  CreateProjectWizardState({
    required this.draft,
    required this.titleController,
    required this.setDraft,
    required this.pickImages,
    required this.pickComicArchive,
    required this.pickEpub,
    required this.tabIndex,
    required this.setTabIndex,
  });

  final ValueNotifier<CreateProjectDraft> draft;
  final TextEditingController titleController;
  final void Function(CreateProjectDraft next) setDraft;
  final Future<void> Function() pickImages;
  final Future<void> Function() pickComicArchive;
  final Future<void> Function() pickEpub;
  final int tabIndex;
  final ValueChanged<int> setTabIndex;

  CreateProjectDraft get current => draft.value;

  bool get canCreate => current.canCreate;

  CreateProjectDraft finalizedDraft() =>
      current.copyWith(projectTitle: titleController.text);
}

CreateProjectWizardState useCreateProjectWizardState(WidgetRef ref) {
  final session = ref.watch(createProjectWizardSessionProvider);
  final notifier = ref.read(createProjectWizardSessionProvider.notifier);

  return CreateProjectWizardState(
    draft: notifier.draftListenable,
    titleController: session.titleController,
    setDraft: notifier.setDraft,
    pickImages: notifier.pickImages,
    pickComicArchive: notifier.pickComicArchive,
    pickEpub: notifier.pickEpub,
    tabIndex: session.tabIndex,
    setTabIndex: notifier.setTabIndex,
  );
}

/// 新建项目向导内容（导入 / 导出 / 行为 Tab 面板）。
class CreateProjectWizardTabPanel extends HookConsumerWidget {
  const CreateProjectWizardTabPanel({
    super.key,
    required this.tabIndex,
    required this.state,
  });

  final int tabIndex;
  final CreateProjectWizardState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = state.draft.value;
    final settingsForPanel = ProjectSettings(
      exportFormat: current.exportFormat,
      inferredImportKind:
          current.inferredImportKind ?? InferredImportKindFrb.images,
      deleteProjectAfterExport: current.deleteProjectAfterExport,
      useDefaultExportDirectory: current.useDefaultExportDirectory,
      exportDirectory: current.exportDirectory,
      comicArchiveContainer: current.comicArchiveContainer,
      useComicArchiveExtension: current.useComicArchiveExtension,
    );

    return switch (tabIndex) {
      0 => CreateProjectWizardImportTab(
          draft: current,
          onPickImages: state.pickImages,
          onPickComicArchive: state.pickComicArchive,
          onPickEpub: state.pickEpub,
        ),
      1 => ProjectExportSettingsPanel(
          settings: settingsForPanel,
          enabled: true,
          layout: ExportSettingsLayout.horizontal,
          showDeleteAfterExport: false,
          onExportFormatChanged: (format) =>
              state.setDraft(current.copyWith(exportFormat: format)),
          onContainerChanged: (container) => state.setDraft(
            current.copyWith(comicArchiveContainer: container),
          ),
          onUseComicExtensionChanged: (value) => state.setDraft(
            current.copyWith(useComicArchiveExtension: value),
          ),
          onUseDefaultDirectoryChanged: (value) => state.setDraft(
            current.copyWith(
              useDefaultExportDirectory: value,
              clearExportDirectory: value,
            ),
          ),
          onExportDirectoryChanged: (directory) => state.setDraft(
            current.copyWith(
              useDefaultExportDirectory: false,
              exportDirectory: directory,
            ),
          ),
          onDeleteAfterExportChanged: (_) {},
        ),
      _ => CreateProjectWizardBehaviorTab(
          deleteAfterExport: current.deleteProjectAfterExport,
          titleController: state.titleController,
          onDeleteAfterExportChanged: (value) => state.setDraft(
            current.copyWith(deleteProjectAfterExport: value),
          ),
          onTitleChanged: (value) =>
              state.setDraft(current.copyWith(projectTitle: value)),
        ),
    };
  }
}

class CreateProjectWizardImportTab extends StatelessWidget {
  const CreateProjectWizardImportTab({
    super.key,
    required this.draft,
    required this.onPickImages,
    required this.onPickComicArchive,
    required this.onPickEpub,
  });

  final CreateProjectDraft draft;
  final VoidCallback onPickImages;
  final VoidCallback onPickComicArchive;
  final VoidCallback onPickEpub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.image_outlined),
            onPressed: onPickImages,
            label: const Text('导入图片'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.folder_zip_outlined),
            onPressed: onPickComicArchive,
            label: const Text('导入漫画压缩包'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.menu_book_outlined),
            onPressed: onPickEpub,
            label: const Text('导入 EPUB'),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Text(
          '已选来源',
          style: theme.textTheme.labelMedium?.copyWith(
            color: onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        DecoratedBox(
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerLow,
            borderRadius: AppRadius.mdBorder,
            border: Border.all(color: theme.colorScheme.outline),
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              _importSourceSummary(draft.importSource),
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ),
        if (draft.inferredImportKind != null) ...[
          const SizedBox(height: 12),
          Text(
            '推断的导入类型',
            style: theme.textTheme.labelMedium?.copyWith(
              color: onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            inferredImportKindLabel(draft.inferredImportKind!),
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  String _importSourceSummary(CreateProjectImportSource? source) {
    if (source == null) return '尚未选择';
    return switch (source) {
      CreateProjectImageImport(:final sourcePaths) =>
        '${sourcePaths.length} 张 Page Image',
      CreateProjectArchiveImport(:final format, :final sourcePath) =>
        '${ArchiveImportRunner.displayName(format)}：$sourcePath',
    };
  }
}

class CreateProjectWizardBehaviorTab extends StatelessWidget {
  const CreateProjectWizardBehaviorTab({
    super.key,
    required this.deleteAfterExport,
    required this.titleController,
    required this.onDeleteAfterExportChanged,
    required this.onTitleChanged,
  });

  final bool deleteAfterExport;
  final TextEditingController titleController;
  final ValueChanged<bool> onDeleteAfterExportChanged;
  final ValueChanged<String> onTitleChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: '项目名称',
            hintText: '留空则自动命名（图片：项目A/B/…；档案：文件名）',
          ),
          onChanged: onTitleChanged,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Checkbox(
              value: deleteAfterExport,
              onChanged: (value) =>
                  onDeleteAfterExportChanged(value ?? false),
            ),
            const SizedBox(width: 8),
            const Expanded(
              child: Text('导出后删除项目'),
            ),
          ],
        ),
      ],
    );
  }
}
