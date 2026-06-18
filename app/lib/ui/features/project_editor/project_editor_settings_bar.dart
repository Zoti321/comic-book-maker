import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:comic_book_maker/ui/core/widgets/app_dropdown_menu.dart';
import 'package:flutter/material.dart';

String exportFormatLabel(ExportFormatFrb format) {
  return switch (format) {
    ExportFormatFrb.epub => 'EPUB',
    ExportFormatFrb.comicArchive => '漫画压缩包',
    ExportFormatFrb.pdf => 'PDF',
  };
}

String inferredImportKindLabel(InferredImportKindFrb kind) {
  return switch (kind) {
    InferredImportKindFrb.images => '图片',
    InferredImportKindFrb.comicArchive => '漫画压缩包',
    InferredImportKindFrb.epub => 'EPUB',
    InferredImportKindFrb.pdf => 'PDF',
  };
}

String appendImportActionLabel(InferredImportKindFrb kind) {
  return switch (kind) {
    InferredImportKindFrb.images => '添加图片',
    InferredImportKindFrb.comicArchive => '从漫画压缩包导入',
    InferredImportKindFrb.epub => '从 EPUB 导入',
    InferredImportKindFrb.pdf => 'PDF 导入（尚未实现）',
  };
}

class ProjectEditorSettingsBar extends StatelessWidget {
  const ProjectEditorSettingsBar({
    super.key,
    required this.settings,
    required this.savingExportFormat,
    required this.onExportFormatChanged,
  });

  final ProjectSettings settings;
  final bool savingExportFormat;
  final ValueChanged<ExportFormatFrb> onExportFormatChanged;

  @override
  Widget build(BuildContext context) {
    final padding = AppSpacing.pagePadding(context);
    final onSurfaceVariant = Theme.of(context).colorScheme.onSurfaceVariant;

    return Padding(
      padding: EdgeInsets.fromLTRB(padding.left, 8, padding.right, 0),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stacked = constraints.maxWidth < 520;
              final exportField = AppDropdownMenu<ExportFormatFrb>(
                key: ValueKey(settings.exportFormat),
                label: 'Export 格式',
                value: settings.exportFormat,
                enabled: !savingExportFormat,
                trailingIcon: savingExportFormat
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : null,
                items: [
                  for (final format in ExportFormatFrb.values)
                    AppDropdownMenuItem(
                      value: format,
                      label: exportFormatLabel(format),
                    ),
                ],
                onChanged: savingExportFormat
                    ? null
                    : (value) {
                        if (value == null) return;
                        onExportFormatChanged(value);
                      },
              );

              final inferredField = InputDecorator(
                decoration: const InputDecoration(
                  labelText: '推断的导入类型',
                  helperText: '由首次 Import 确定，不可修改',
                ),
                child: Text(
                  inferredImportKindLabel(settings.inferredImportKind),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: onSurfaceVariant,
                      ),
                ),
              );

              if (stacked) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    exportField,
                    const SizedBox(height: 12),
                    inferredField,
                  ],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: exportField),
                  const SizedBox(width: 16),
                  Expanded(child: inferredField),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
