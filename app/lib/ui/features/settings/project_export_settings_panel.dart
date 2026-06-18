import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/core/widgets/app_dropdown_menu.dart';
import 'package:comic_book_maker/ui/features/settings/comic_archive_export_controls.dart';
import 'package:comic_book_maker/ui/features/settings/export_settings_layout.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_settings_bar.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 项目 Export 工作流设置（属性对话框 / 新建向导共用）。
class ProjectExportSettingsPanel extends StatelessWidget {
  const ProjectExportSettingsPanel({
    super.key,
    required this.settings,
    required this.enabled,
    required this.onExportFormatChanged,
    required this.onContainerChanged,
    required this.onUseComicExtensionChanged,
    required this.onUseDefaultDirectoryChanged,
    required this.onExportDirectoryChanged,
    required this.onDeleteAfterExportChanged,
    this.showDeleteAfterExport = true,
    this.layout = ExportSettingsLayout.stacked,
  });

  final ProjectSettings settings;
  final bool enabled;
  final ValueChanged<ExportFormatFrb> onExportFormatChanged;
  final ValueChanged<ComicArchiveContainerFrb> onContainerChanged;
  final ValueChanged<bool> onUseComicExtensionChanged;
  final ValueChanged<bool> onUseDefaultDirectoryChanged;
  final ValueChanged<String?> onExportDirectoryChanged;
  final ValueChanged<bool> onDeleteAfterExportChanged;
  final bool showDeleteAfterExport;
  final ExportSettingsLayout layout;

  bool get _horizontal => layout == ExportSettingsLayout.horizontal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Future<void> pickProjectExportDirectory() async {
      final selected = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择导出目录',
      );
      if (selected == null) return;
      onExportDirectoryChanged(selected);
    }

    final exportFormatSelect = AppDropdownMenu<ExportFormatFrb>(
      key: ValueKey(settings.exportFormat),
      label: _horizontal ? null : '导出格式',
      value: settings.exportFormat,
      enabled: enabled,
      items: [
        for (final format in ExportFormatFrb.values)
          AppDropdownMenuItem(
            value: format,
            label: exportFormatLabel(format),
          ),
      ],
      onChanged: enabled
          ? (value) {
              if (value == null) return;
              onExportFormatChanged(value);
            }
          : null,
    );

    final defaultDirectoryCheckbox = Row(
      children: [
        Checkbox(
          value: settings.useDefaultExportDirectory,
          onChanged: enabled
              ? (value) => onUseDefaultDirectoryChanged(value ?? true)
              : null,
        ),
        Expanded(
          child: Text(
            '使用默认导出目录',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );

    final customDirectoryFields = !settings.useDefaultExportDirectory
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              Text(
                settings.exportDirectory?.trim().isNotEmpty == true
                    ? settings.exportDirectory!
                    : '未选择导出目录',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: enabled ? pickProjectExportDirectory : null,
                icon: const Icon(LucideIcons.folder),
                label: const Text('选择导出目录'),
              ),
            ],
          )
        : const SizedBox.shrink();

    final exportDirectorySection = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        defaultDirectoryCheckbox,
        customDirectoryFields,
      ],
    );

    final deleteAfterExportCheckbox = Row(
      children: [
        Checkbox(
          value: settings.deleteProjectAfterExport,
          onChanged: enabled
              ? (value) => onDeleteAfterExportChanged(value ?? false)
              : null,
        ),
        Expanded(
          child: Text(
            '导出后删除项目',
            style: theme.textTheme.bodyMedium,
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_horizontal)
          _LabeledFieldRow(label: '导出格式', child: exportFormatSelect)
        else
          exportFormatSelect,
        if (settings.exportFormat == ExportFormatFrb.comicArchive) ...[
          const SizedBox(height: 16),
          ComicArchiveExportControls(
            settings: settings,
            enabled: enabled,
            layout: layout,
            onContainerChanged: onContainerChanged,
            onUseComicExtensionChanged: onUseComicExtensionChanged,
          ),
        ],
        const SizedBox(height: 16),
        if (_horizontal)
          _LabeledFieldRow(reserveLeadingSpace: true, child: exportDirectorySection)
        else
          exportDirectorySection,
        if (showDeleteAfterExport) ...[
          const SizedBox(height: 16),
          if (_horizontal)
            _LabeledFieldRow(
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

class _LabeledFieldRow extends StatelessWidget {
  const _LabeledFieldRow({
    required this.child,
    this.label,
    this.reserveLeadingSpace = false,
  });

  final Widget child;
  final String? label;
  final bool reserveLeadingSpace;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    const labelWidth = 160.0;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: labelWidth,
          child: label == null
              ? const SizedBox.shrink()
              : Text(
                  label!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
        ),
        const SizedBox(width: 16),
        Expanded(child: child),
      ],
    );
  }
}
