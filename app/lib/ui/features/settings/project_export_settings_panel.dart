import 'package:comic_book_maker/providers/export_path_provider.dart';
import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/features/settings/comic_archive_export_controls.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<ExportFormatFrb>(
          key: ValueKey(settings.exportFormat),
          initialValue: settings.exportFormat,
          decoration: InputDecoration(
            labelText: 'Export 格式',
            helperText: '决定导出文件类型与元数据 Tab 的编辑模型',
            enabled: enabled,
          ),
          items: ExportFormatFrb.values
              .map(
                (format) => DropdownMenuItem(
                  value: format,
                  enabled: format != ExportFormatFrb.pdf,
                  child: Text(exportFormatLabel(format)),
                ),
              )
              .toList(),
          onChanged: enabled
              ? (value) {
                  if (value == null || value == ExportFormatFrb.pdf) return;
                  onExportFormatChanged(value);
                }
              : null,
        ),
        if (settings.exportFormat == ExportFormatFrb.comicArchive) ...[
          const SizedBox(height: 16),
          ComicArchiveExportControls(
            settings: settings,
            enabled: enabled,
            exampleBaseName: exampleBaseName,
            onContainerChanged: onContainerChanged,
            onUseComicExtensionChanged: onUseComicExtensionChanged,
          ),
        ],
        const SizedBox(height: 16),
        Text(
          '导出目录',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        AppCheckbox(
          value: settings.useDefaultExportDirectory,
          onChanged: enabled
              ? (value) => onUseDefaultDirectoryChanged(value ?? true)
              : null,
          label: '沿用应用默认导出目录',
          sublabel: hasGlobal
              ? '当前全局目录：$globalExportDir'
              : '尚未在「设置」中配置全局目录',
        ),
        if (!settings.useDefaultExportDirectory) ...[
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
        const SizedBox(height: 8),
        Text(
          '导出时将直接保存到上述目录，不再询问路径。',
          style: theme.textTheme.bodySmall?.copyWith(
            color: onSurfaceVariant,
          ),
        ),
        if (showDeleteAfterExport) ...[
          const SizedBox(height: 16),
          AppCheckbox(
            value: settings.deleteProjectAfterExport,
            onChanged: enabled
                ? (value) => onDeleteAfterExportChanged(value ?? false)
                : null,
            label: '导出后删除项目',
            sublabel: 'Export 成功后将永久删除本地 Page 与 Metadata',
          ),
        ],
      ],
    );
  }
}
