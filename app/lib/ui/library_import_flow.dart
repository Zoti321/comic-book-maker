import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/ui/design_system/design_system.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// 上次导入失败时可重试的来源（留在漫画库，不导航离开）。
typedef LibraryImportRetry = ({
  ImportArchiveFormat format,
  String sourcePath,
  String message,
});

String libraryImportDisplayName(ImportArchiveFormat format) {
  return switch (format) {
    ImportArchiveFormat.cbr => 'CBR',
    ImportArchiveFormat.cbz => 'CBZ',
    ImportArchiveFormat.epub => 'EPUB',
  };
}

List<String> libraryImportAllowedExtensions(ImportArchiveFormat format) {
  return switch (format) {
    ImportArchiveFormat.cbr => const ['cbr'],
    ImportArchiveFormat.cbz => const ['cbz'],
    ImportArchiveFormat.epub => const ['epub'],
  };
}

/// 选择本地归档文件；取消返回 `null`。
Future<String?> pickLibraryImportSourcePath(ImportArchiveFormat format) async {
  final displayName = libraryImportDisplayName(format);
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: libraryImportAllowedExtensions(format),
    allowMultiple: false,
  );
  if (result == null || result.files.isEmpty) return null;

  final sourcePath = result.files.single.path;
  if (sourcePath == null || sourcePath.isEmpty) {
    throw StateError('无法读取所选 $displayName 文件路径');
  }
  return sourcePath;
}

Future<ImportCbzResult> _importArchive({
  required ImportArchiveFormat format,
  required String sourcePath,
}) {
  return Future(() => switch (format) {
        ImportArchiveFormat.cbr => importCbr(sourcePath: sourcePath),
        ImportArchiveFormat.cbz => importCbz(sourcePath: sourcePath),
        ImportArchiveFormat.epub => importEpub(sourcePath: sourcePath),
      });
}

/// 阻塞式导入 + 成功/失败反馈。成功返回 `null`；失败返回可 [LibraryImportRetry]。
Future<LibraryImportRetry?> runLibraryArchiveImport({
  required BuildContext context,
  required ImportArchiveFormat format,
  required String sourcePath,
  required VoidCallback onProjectsReloaded,
}) async {
  final displayName = libraryImportDisplayName(format);

  try {
    final imported = await runAppBlockingOperation(
      context: context,
      message: '正在导入 $displayName…',
      operation: () => _importArchive(format: format, sourcePath: sourcePath),
    );

    onProjectsReloaded();

    if (!context.mounted) return null;

    await showAppLibraryImportOutcome(
      context,
      warnings: imported.warnings,
    );
    return null;
  } catch (e) {
    if (!context.mounted) return null;
    return (
      format: format,
      sourcePath: sourcePath,
      message: e.toString(),
    );
  }
}
