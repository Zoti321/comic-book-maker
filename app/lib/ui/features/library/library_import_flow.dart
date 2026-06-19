import 'package:comic_book_maker/domain/use_cases/archive_import_runner.dart';
import 'package:comic_book_maker/domain/use_cases/library_operations.dart';
import 'package:comic_book_maker/ui/core/design_system/app_overlay.dart';
import 'package:flutter/material.dart';

String libraryImportDisplayName(ArchiveFormatFrb format) =>
    ArchiveImportRunner.displayName(format);

/// 上次导入失败时可重试的来源（留在漫画库，不导航离开）。
typedef LibraryImportRetry = ({
  ArchiveFormatFrb format,
  String sourcePath,
  String message,
});

Future<T> _runBlockingLibraryOperation<T>({
  required BuildContext context,
  required String message,
  required Future<T> Function() operation,
}) async {
  if (!context.mounted) {
    throw StateError('Context is not mounted');
  }

  showAppOverlayDialog<void>(
    context: context,
    barrierDismissible: false,
    useRootNavigator: true,
    builder: (dialogContext) => PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 16),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    ),
  );
  await WidgetsBinding.instance.endOfFrame;

  try {
    return await operation();
  } finally {
    if (context.mounted) {
      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
  }
}

Future<void> _showLibraryImportWarnings(
  BuildContext context, {
  required List<String> warnings,
}) async {
  if (warnings.isEmpty) return;

  await showAppOverlayDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('导入完成（有警告）'),
      content: Text(warnings.join('\n')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('知道了'),
        ),
      ],
    ),
  );
}

/// 阻塞式导入 + 成功/失败反馈。成功返回 `null`；失败返回可 [LibraryImportRetry]。
Future<LibraryImportRetry?> runLibraryArchiveImport({
  required BuildContext context,
  required LibraryOperations library,
  required ArchiveFormatFrb format,
  required String sourcePath,
}) async {
  final runner = ArchiveImportRunner();

  try {
    final imported = await _runBlockingLibraryOperation(
      context: context,
      message: runner.importBlockingMessage(format),
      operation: () => library.importArchive(
        format: format,
        sourcePath: sourcePath,
      ),
    );

    if (!context.mounted) return null;

    await _showLibraryImportWarnings(context, warnings: imported.warnings);
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
