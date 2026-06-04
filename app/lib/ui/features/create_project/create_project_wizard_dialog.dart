import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/features/create_project/create_project_draft.dart';
import 'package:comic_book_maker/ui/core/design_system/design_system.dart';
import 'package:comic_book_maker/domain/use_cases/archive_import_runner.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_settings_bar.dart';
import 'package:comic_book_maker/ui/features/settings/project_export_settings_panel.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_dialog_shell.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _pageImageExtensions = [
  'jpg', 'jpeg', 'png', 'webp', 'gif', 'avif', 'bmp',
];

/// 新建项目三步向导（导入 / 导出 / 行为）。
class CreateProjectWizardDialog extends HookConsumerWidget {
  const CreateProjectWizardDialog({super.key});

  static const _tabs = [
    SideTabDialogTab(label: '导入', icon: Icons.download_outlined),
    SideTabDialogTab(label: '导出', icon: Icons.upload_outlined),
    SideTabDialogTab(label: '行为', icon: Icons.tune_outlined),
  ];

  @override
  Widget build(BuildContext context, WidgetRef widgetRef) {
    final tabIndex = useState(0);
    final draft = useState(CreateProjectDraft());
    final titleController = useTextEditingController();
    void setDraft(CreateProjectDraft next) {
      draft.value = next;
    }

    Future<void> pickImages() async {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: _pageImageExtensions,
        allowMultiple: true,
      );
      if (result == null || result.files.isEmpty) return;

      final paths = result.files
          .map((f) => f.path)
          .whereType<String>()
          .where((p) => p.isNotEmpty)
          .toList();
      if (paths.isEmpty) return;

      final next = draft.value.copyWith();
      next.applyImportSource(CreateProjectImageImport(paths));
      setDraft(next);
    }

    Future<void> pickArchive(ImportArchiveFormat format) async {
      final path = await ArchiveImportRunner().pickSourcePath(format);
      if (path == null) return;

      final next = draft.value.copyWith();
      next.applyImportSource(
        CreateProjectArchiveImport(format: format, sourcePath: path),
      );
      setDraft(next);
    }

    final current = draft.value;
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

    final Widget panel = switch (tabIndex.value) {
      0 => _ImportTab(
          draft: current,
          onPickImages: pickImages,
          onPickCbz: () => pickArchive(ImportArchiveFormat.cbz),
          onPickCbr: () => pickArchive(ImportArchiveFormat.cbr),
          onPickEpub: () => pickArchive(ImportArchiveFormat.epub),
        ),
      1 => ProjectExportSettingsPanel(
          settings: settingsForPanel,
          enabled: true,
          exampleBaseName: '未命名',
          showDeleteAfterExport: false,
          onExportFormatChanged: (format) =>
              setDraft(current.copyWith(exportFormat: format)),
          onContainerChanged: (container) => setDraft(
            current.copyWith(comicArchiveContainer: container),
          ),
          onUseComicExtensionChanged: (value) => setDraft(
            current.copyWith(useComicArchiveExtension: value),
          ),
          onUseDefaultDirectoryChanged: (value) => setDraft(
            current.copyWith(
              useDefaultExportDirectory: value,
              clearExportDirectory: value,
            ),
          ),
          onExportDirectoryChanged: (directory) => setDraft(
            current.copyWith(
              useDefaultExportDirectory: false,
              exportDirectory: directory,
            ),
          ),
          onDeleteAfterExportChanged: (_) {},
        ),
      _ => _BehaviorTab(
          deleteAfterExport: current.deleteProjectAfterExport,
          titleController: titleController,
          onDeleteAfterExportChanged: (value) => setDraft(
            current.copyWith(deleteProjectAfterExport: value),
          ),
          onTitleChanged: (value) =>
              setDraft(current.copyWith(projectTitle: value)),
        ),
    };

    final disabledReason = current.createDisabledReason;
    final theme = Theme.of(context);

    return AppDialog(
      title: '新建项目',
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          SideTabDialogShell(
            selectedIndex: tabIndex.value,
            onTabSelected: (index) => tabIndex.value = index,
            tabs: _tabs,
            child: panel,
          ),
          if (disabledReason != null) ...[
            const SizedBox(height: 8),
            Text(
              disabledReason,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
        ],
      ),
      actions: [
        AppButton(
          variant: AppButtonVariant.outline,
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        AppButton(
          onPressed: current.canCreate
              ? () {
                  Navigator.pop(
                    context,
                    current.copyWith(projectTitle: titleController.text),
                  );
                }
              : null,
          child: const Text('创建'),
        ),
      ],
    );
  }
}

class _ImportTab extends StatelessWidget {
  const _ImportTab({
    required this.draft,
    required this.onPickImages,
    required this.onPickCbz,
    required this.onPickCbr,
    required this.onPickEpub,
  });

  final CreateProjectDraft draft;
  final VoidCallback onPickImages;
  final VoidCallback onPickCbz;
  final VoidCallback onPickCbr;
  final VoidCallback onPickEpub;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '选择要导入的资源（必选）',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        AppButton(
          variant: AppButtonVariant.outline,
          icon: const Icon(Icons.image_outlined),
          onPressed: onPickImages,
          child: const Text('选择 Page Image'),
        ),
        const SizedBox(height: 8),
        AppButton(
          variant: AppButtonVariant.outline,
          icon: const Icon(Icons.folder_zip_outlined),
          onPressed: onPickCbz,
          child: const Text('导入 CBZ'),
        ),
        const SizedBox(height: 8),
        AppButton(
          variant: AppButtonVariant.outline,
          icon: const Icon(Icons.archive_outlined),
          onPressed: onPickCbr,
          child: const Text('导入 CBR'),
        ),
        const SizedBox(height: 8),
        AppButton(
          variant: AppButtonVariant.outline,
          icon: const Icon(Icons.menu_book_outlined),
          onPressed: onPickEpub,
          child: const Text('导入 EPUB'),
        ),
        const SizedBox(height: 16),
        Text(
          '已选来源',
          style: theme.textTheme.labelMedium?.copyWith(
            color: onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _importSourceSummary(draft.importSource),
          style: theme.textTheme.bodyMedium,
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

class _BehaviorTab extends StatelessWidget {
  const _BehaviorTab({
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
        AppTextField(
          controller: titleController,
          label: '项目名称',
          hint: '留空则使用「未命名」或归档内标题',
          onChanged: onTitleChanged,
        ),
        const SizedBox(height: 16),
        AppCheckbox(
          value: deleteAfterExport,
          onChanged: (value) => onDeleteAfterExportChanged(value ?? false),
          label: '导出后删除项目',
          sublabel: 'Export 成功后将永久删除本地 Page 与 Metadata',
        ),
      ],
    );
  }
}
