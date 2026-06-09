import 'package:comic_book_maker/providers/export_path_provider.dart';
import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/features/settings/comic_archive_export_controls.dart';
import 'package:comic_book_maker/ui/features/settings/export_settings_layout.dart';
import 'package:comic_book_maker/ui/core/design_system/design_system.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_settings_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 项目 Export 工作流设置（属性对话框 / 新建向导共用）。
class ProjectExportSettingsPanel extends ConsumerWidget {
  const ProjectExportSettingsPanel({
    super.key,
    required this.settings,
    required this.enabled,
    required this.exampleBaseName,
    required this.onExportFormatChanged,
    required this.onContainerChanged,
    required this.onUseComicExtensionChanged,
    required this.onUseDefaultDirectoryChanged,
    required this.onExportDirectoryChanged,
    required this.onDeleteAfterExportChanged,
    this.showDeleteAfterExport = true,
    this.layout = ExportSettingsLayout.stacked,
    this.minimalCopy = false,
  });

  final ProjectSettings settings;
  final bool enabled;
  final String exampleBaseName;
  final ValueChanged<ExportFormatFrb> onExportFormatChanged;
  final ValueChanged<ComicArchiveContainerFrb> onContainerChanged;
  final ValueChanged<bool> onUseComicExtensionChanged;
  final ValueChanged<bool> onUseDefaultDirectoryChanged;
  final ValueChanged<String?> onExportDirectoryChanged;
  final ValueChanged<bool> onDeleteAfterExportChanged;
  final bool showDeleteAfterExport;
  final ExportSettingsLayout layout;
  final bool minimalCopy;

  bool get _horizontal => layout == ExportSettingsLayout.horizontal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;
    final globalExportDir = ref.watch(exportPathProvider).value;
    final hasGlobal =
        globalExportDir != null && globalExportDir.trim().isNotEmpty;

    Future<void> pickProjectExportDirectory() async {
      final selected = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择项目专用导出目录',
      );
      if (selected == null) return;
      onExportDirectoryChanged(selected);
    }

    final exportFormatSelect = AppSelect<ExportFormatFrb>(
      key: ValueKey(settings.exportFormat),
      label: _horizontal ? null : '导出格式',
      helper: minimalCopy ? null : '决定导出文件类型与元数据 Tab 的编辑模型',
      enabled: enabled,
      value: settings.exportFormat,
      onChanged: enabled ? onExportFormatChanged : null,
      items: [
        for (final format in ExportFormatFrb.values)
          AppSelectItem(
            value: format,
            label: exportFormatLabel(format),
            enabled: format != ExportFormatFrb.pdf,
          ),
      ],
    );

    final defaultDirectoryCheckbox = AppCheckbox(
      value: settings.useDefaultExportDirectory,
      onChanged: enabled
          ? (value) => onUseDefaultDirectoryChanged(value ?? true)
          : null,
      label: '使用默认导出目录',
      sublabel: minimalCopy
          ? null
          : hasGlobal
              ? '当前全局目录：$globalExportDir'
              : '尚未在「设置」中配置全局目录',
    );

    final customDirectoryFields = !settings.useDefaultExportDirectory
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                settings.exportDirectory?.trim().isNotEmpty == true
                    ? settings.exportDirectory!
                    : '未选择专用目录',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              AppButton(
                variant: AppButtonVariant.secondary,
                onPressed: enabled ? pickProjectExportDirectory : null,
                icon: const Icon(LucideIcons.folder),
                child: const Text('选择专用导出目录'),
              ),
            ],
          )
        : const SizedBox.shrink();

    final exportDirectorySection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!minimalCopy) ...[
          Text(
            '导出目录',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (_horizontal)
          AppLabeledFieldRow(
            reserveLeadingSpace: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                defaultDirectoryCheckbox,
                customDirectoryFields,
              ],
            ),
          )
        else ...[
          defaultDirectoryCheckbox,
          customDirectoryFields,
        ],
        if (!minimalCopy) ...[
          const SizedBox(height: 8),
          Text(
            '导出时将直接保存到上述目录，不再询问路径。',
            style: theme.textTheme.bodySmall?.copyWith(
              color: onSurfaceVariant,
            ),
          ),
        ],
      ],
    );

    final deleteAfterExportCheckbox = AppCheckbox(
      value: settings.deleteProjectAfterExport,
      onChanged: enabled
          ? (value) => onDeleteAfterExportChanged(value ?? false)
          : null,
      label: '导出后删除项目',
      sublabel: minimalCopy
          ? null
          : 'Export 成功后将永久删除本地 Page 与 Metadata',
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_horizontal)
          AppLabeledFieldRow(
            label: '导出格式',
            child: exportFormatSelect,
          )
        else
          exportFormatSelect,
        if (settings.exportFormat == ExportFormatFrb.comicArchive) ...[
          const SizedBox(height: 16),
          ComicArchiveExportControls(
            settings: settings,
            enabled: enabled,
            exampleBaseName: exampleBaseName,
            layout: layout,
            minimalCopy: minimalCopy,
            onContainerChanged: onContainerChanged,
            onUseComicExtensionChanged: onUseComicExtensionChanged,
          ),
        ],
        const SizedBox(height: 16),
        exportDirectorySection,
        if (showDeleteAfterExport) ...[
          const SizedBox(height: 16),
          if (_horizontal)
            AppLabeledFieldRow(
              reserveLeadingSpace: true,
              child: deleteAfterExportCheckbox,
            )
          else
            deleteAfterExportCheckbox,
        ],
      ],
    );
  }
}
