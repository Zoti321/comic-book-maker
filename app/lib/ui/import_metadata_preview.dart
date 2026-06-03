import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/ui/design_system/design_system.dart';
import 'package:comic_book_maker/ui/theme/app_tokens.dart';
import 'package:flutter/material.dart';

String importMetadataKindLabel(ImportMetadataKindFrb kind) {
  return switch (kind) {
    ImportMetadataKindFrb.comicinfo => 'ComicInfo',
    ImportMetadataKindFrb.opf => 'OPF metadata',
    ImportMetadataKindFrb.none => '无',
  };
}

/// 归档内导入元数据的只读预览（与下方可编辑「导出元数据」区分）。
class ImportMetadataPreview extends StatefulWidget {
  const ImportMetadataPreview({
    super.key,
    required this.snapshot,
    this.inferredImportKind,
    required this.exportFormatLabel,
  });

  final ImportMetadataSnapshotFrb snapshot;
  final InferredImportKindFrb? inferredImportKind;

  /// 当前 Export 格式展示名（如 CBZ / EPUB），用于说明与下方表单的关系。
  final String exportFormatLabel;

  @override
  State<ImportMetadataPreview> createState() => _ImportMetadataPreviewState();
}

class _ImportMetadataPreviewState extends State<ImportMetadataPreview> {
  late final ScrollController _xmlScrollController;

  @override
  void initState() {
    super.initState();
    _xmlScrollController = ScrollController();
  }

  @override
  void dispose() {
    _xmlScrollController.dispose();
    super.dispose();
  }

  bool get _hasXml =>
      widget.snapshot.xml != null && widget.snapshot.xml!.trim().isNotEmpty;

  bool get _showEmptyState =>
      widget.snapshot.kind == ImportMetadataKindFrb.none ||
      !_hasXml ||
      widget.inferredImportKind == InferredImportKindFrb.images;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurfaceVariant = theme.colorScheme.onSurfaceVariant;

    return AppCard(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.archive_outlined,
                size: 20,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '导入元数据（只读）',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _showEmptyState
                          ? '导入资源中没有元数据。请在下方「导出元数据」中填写并保存，导出时将写入 ${widget.exportFormatLabel}。'
                          : '来自归档的 ${importMetadataKindLabel(widget.snapshot.kind)} 原文预览。'
                              ' 在下方分段中编辑并保存后，才会作为 ${widget.exportFormatLabel} 导出元数据。',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!_showEmptyState) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.arrow_downward, size: 16, color: onSurfaceVariant),
                const SizedBox(width: 6),
                Text(
                  '可编辑字段在下方「导出元数据」',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 220),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: AppRadius.mdBorder,
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Scrollbar(
                  controller: _xmlScrollController,
                  child: SingleChildScrollView(
                    controller: _xmlScrollController,
                    primary: false,
                    padding: const EdgeInsets.all(10),
                    child: SelectableText(
                      widget.snapshot.xml!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'monospace',
                        height: 1.35,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
