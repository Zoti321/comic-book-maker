import 'package:comic_book_maker/application/archive_import_runner.dart';
import 'package:comic_book_maker/application/library_operations.dart';
import 'package:comic_book_maker/ui/design_system/design_system.dart';
import 'package:comic_book_maker/ui/design_system/import_archive_sheet.dart';
import 'package:flutter/material.dart';

String libraryImportDisplayName(ImportArchiveFormat format) =>
    ArchiveImportRunner.displayName(format);

/// 上次导入失败时可重试的来源（留在漫画库，不导航离开）。
typedef LibraryImportRetry = ({
  ImportArchiveFormat format,
  String sourcePath,
  String message,
});

/// 阻塞式导入 + 成功/失败反馈。成功返回 `null`；失败返回可 [LibraryImportRetry]。
Future<LibraryImportRetry?> runLibraryArchiveImport({
  required BuildContext context,
  required LibraryOperations library,
  required ImportArchiveFormat format,
  required String sourcePath,
}) async {
  final runner = ArchiveImportRunner();

  try {
    final imported = await runAppBlockingOperation(
      context: context,
      message: runner.importBlockingMessage(format),
      operation: () => library.importArchive(
        format: format,
        sourcePath: sourcePath,
      ),
    );

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
