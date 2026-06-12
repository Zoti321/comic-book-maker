import 'package:comic_book_maker/data/repositories/core_gateway.dart';

/// 受支持的 Page Image 扩展名（与 Core `page_image` 一致）。
const kPageImageExtensions = [
  'jpg',
  'jpeg',
  'png',
  'webp',
  'gif',
  'avif',
  'bmp',
];

/// 文件选择器用途：决定扩展名过滤策略。
enum ImportKindPickerIntent {
  /// 图片 Tab 画廊末尾「添加页面」——始终仅 Page Image。
  galleryAddPage,

  /// 编辑页「追加导入」——跟随 `inferred_import_kind`。
  appendImport,

  /// 缩略图菜单「替换」——始终仅 Page Image（Page Operation）。
  replacePage,
}

/// 按 Import 格式与用途解析允许的扩展名；`null` 表示该入口不可用。
List<String>? allowedExtensionsFor(
  InferredImportKindFrb kind,
  ImportKindPickerIntent intent,
) {
  if (intent == ImportKindPickerIntent.galleryAddPage) {
    return kPageImageExtensions;
  }

  return switch (intent) {
    ImportKindPickerIntent.replacePage => kPageImageExtensions,
    ImportKindPickerIntent.appendImport => switch (kind) {
        InferredImportKindFrb.images => kPageImageExtensions,
        InferredImportKindFrb.comicArchive => null,
        InferredImportKindFrb.epub => const ['epub'],
        InferredImportKindFrb.pdf => null,
      },
    ImportKindPickerIntent.galleryAddPage => kPageImageExtensions,
  };
}

String appendImportBlockedReason(InferredImportKindFrb kind) {
  return switch (kind) {
    InferredImportKindFrb.pdf => 'PDF 导入尚未实现。',
    _ => '',
  };
}

bool canAppendImportForSettings(
  ProjectSettings? settings, {
  required bool operationInProgress,
}) {
  if (settings == null || operationInProgress) return false;
  return settings.inferredImportKind != InferredImportKindFrb.pdf;
}

bool canExportProject({
  required ProjectSettings? settings,
  required int pageCount,
  required bool operationInProgress,
}) {
  if (settings == null || pageCount == 0 || operationInProgress) {
    return false;
  }
  return true;
}
