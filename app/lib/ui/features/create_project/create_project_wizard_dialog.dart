import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/models/create_project_draft.dart';
import 'package:comic_book_maker/domain/use_cases/archive_import_runner.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_settings_bar.dart';
import 'package:comic_book_maker/ui/features/settings/export_settings_layout.dart';
import 'package:comic_book_maker/ui/features/settings/project_export_settings_panel.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_dialog_shell.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_feature_dialog.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _pageImageExtensions = [
  'jpg', 'jpeg', 'png', 'webp', 'gif', 'avif', 'bmp',
];

/// 新建项目三步向导（导入 / 导出 / 行为）。
class CreateProjectWizardDialog extends HookConsumerWidget {
  const CreateProjectWizardDialog({super.key});

  static const _tabs = [
    SideTabDialogTab(label: '导入', icon: LucideIcons.download),
    SideTabDialogTab(label: '导出', icon: LucideIcons.upload),
    SideTabDialogTab(label: '行为', icon: LucideIcons.slidersHorizontal),
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

    Future<void> pickComicArchive() async {
      final picked = await ArchiveImportRunner().pickComicArchivePath();
      if (picked == null) return;

      final next = draft.value.copyWith();
      next.applyImportSource(
        CreateProjectArchiveImport(
          format: picked.format,
          sourcePath: picked.path,
        ),
      );
      setDraft(next);
    }

    Future<void> pickArchive(ArchiveFormatFrb format) async {
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
          onPickComicArchive: pickComicArchive,
          onPickEpub: () => pickArchive(ArchiveFormatFrb.epub),
        ),
      1 => ProjectExportSettingsPanel(
          settings: settingsForPanel,
          enabled: true,
          layout: ExportSettingsLayout.horizontal,
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

    return SideTabFeatureDialog(
      title: '新建项目',
      tabs: _tabs,
      selectedIndex: tabIndex.value,
      onTabSelected: (index) => tabIndex.value = index,
      body: SingleChildScrollView(child: panel),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
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
            icon: const Icon(LucideIcons.image),
            onPressed: onPickImages,
            label: const Text('导入图片'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(LucideIcons.folderArchive),
            onPressed: onPickComicArchive,
            label: const Text('导入漫画压缩包'),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(LucideIcons.bookOpen),
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
