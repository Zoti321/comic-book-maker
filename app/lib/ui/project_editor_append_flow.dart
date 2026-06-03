import 'package:comic_book_maker/providers/project_workspace_provider.dart';
import 'package:comic_book_maker/providers/project_workspace_state.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/ui/design_system/design_system.dart';
import 'package:comic_book_maker/ui/import_kind_picker_rules.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// 图片 Tab 画廊「添加页面」：始终仅 Page Image，不受 `inferred_import_kind` 限制。
Future<void> runGalleryAddPageImages({
  required BuildContext context,
  required ProjectWorkspace workspaceNotifier,
}) async {
  final extensions = allowedExtensionsFor(
    InferredImportKindFrb.images,
    ImportKindPickerIntent.galleryAddPage,
  )!;
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: extensions,
    allowMultiple: true,
  );
  if (result == null || result.files.isEmpty) return;

  final sourcePaths = result.files
      .map((f) => f.path)
      .whereType<String>()
      .where((path) => path.isNotEmpty)
      .toList();

  if (sourcePaths.isEmpty) {
    workspaceNotifier.reportError('无法读取所选文件路径');
    return;
  }

  if (!context.mounted) return;

  try {
    await runAppBlockingOperation(
      context: context,
      message: '正在添加图片…',
      operation: () => workspaceNotifier.addPageImages(sourcePaths),
    );
    if (!context.mounted) return;
    showAppOperationSuccessSnackBar(context, '已添加 ${sourcePaths.length} 张图片');
  } catch (e) {
    if (!context.mounted) return;
    await showAppOperationFailure(
      context,
      title: '添加页面失败',
      message: e.toString(),
      nextStepHint: '请确认文件为受支持的图片格式且未被其他程序占用。',
    );
  }
}

/// 顶栏「追加导入」：按 `inferred_import_kind` 选择数据源；统一 blocking loading 与结果反馈。
Future<void> runProjectAppendImport({
  required BuildContext context,
  required ProjectWorkspaceState workspace,
  required ProjectWorkspace workspaceNotifier,
}) async {
  final kind = workspace.settings?.inferredImportKind;
  if (kind == null || !workspace.canAppendImport) return;

  switch (kind) {
    case InferredImportKindFrb.images:
      await _appendImages(context, workspaceNotifier, kind);
    case InferredImportKindFrb.pdf:
      if (!context.mounted) return;
      await showAppOperationFailure(
        context,
        title: '无法追加导入',
        message: appendImportBlockedReason(kind),
        nextStepHint: '请使用图片、CBZ/CBR 或 EPUB 作为导入来源，或在项目属性中更改导入格式。',
      );
    case InferredImportKindFrb.comicArchive:
      await _appendArchive(context, workspaceNotifier);
    case InferredImportKindFrb.epub:
      await _appendEpub(context, workspaceNotifier, kind);
  }
}

Future<void> _appendImages(
  BuildContext context,
  ProjectWorkspace workspaceNotifier,
  InferredImportKindFrb kind,
) async {
  final allowedExtensions = allowedExtensionsFor(
    kind,
    ImportKindPickerIntent.appendImport,
  )!;
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
    allowMultiple: true,
  );
  if (result == null || result.files.isEmpty) return;

  final sourcePaths = result.files
      .map((f) => f.path)
      .whereType<String>()
      .where((path) => path.isNotEmpty)
      .toList();

  if (sourcePaths.isEmpty) {
    workspaceNotifier.reportError('无法读取所选文件路径');
    return;
  }

  if (!context.mounted) return;

  try {
    await runAppBlockingOperation(
      context: context,
      message: '正在添加图片…',
      operation: () => workspaceNotifier.addPageImages(sourcePaths),
    );
    if (!context.mounted) return;
    showAppOperationSuccessSnackBar(context, '已添加 ${sourcePaths.length} 张图片');
  } catch (e) {
    if (!context.mounted) return;
    await showAppOperationFailure(
      context,
      title: '添加图片失败',
      message: e.toString(),
      nextStepHint: '请确认文件格式受支持且未被其他程序占用。',
    );
  }
}

Future<void> _appendArchive(
  BuildContext context,
  ProjectWorkspace workspaceNotifier,
) async {
  final format = await showAppendArchiveSheet(context);
  if (format == null || !context.mounted) return;

  final allowedExtensions = switch (format) {
    AppendArchiveFormat.cbz => const ['cbz'],
    AppendArchiveFormat.cbr => const ['cbr'],
  };
  final displayName = switch (format) {
    AppendArchiveFormat.cbz => 'CBZ',
    AppendArchiveFormat.cbr => 'CBR',
  };

  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
    allowMultiple: false,
  );
  if (result == null || result.files.isEmpty) return;

  final sourcePath = result.files.single.path;
  if (sourcePath == null || sourcePath.isEmpty) {
    workspaceNotifier.reportError('无法读取所选 $displayName 文件路径');
    return;
  }

  if (!context.mounted) return;

  try {
    final appendResult = await runAppBlockingOperation(
      context: context,
      message: '正在从 $displayName 追加页面…',
      operation: () => switch (format) {
        AppendArchiveFormat.cbz => workspaceNotifier.appendCbz(sourcePath),
        AppendArchiveFormat.cbr => workspaceNotifier.appendCbr(sourcePath),
      },
    );
    if (!context.mounted) return;
    await showAppAppendImportOutcome(
      context,
      addedPageCount: appendResult.addedPageCount,
      warnings: appendResult.warnings,
    );
  } catch (e) {
    if (!context.mounted) return;
    await showAppOperationFailure(
      context,
      title: '追加导入失败',
      message: e.toString(),
      nextStepHint: '请确认压缩包未损坏且格式与项目推断类型一致。',
    );
  }
}

Future<void> _appendEpub(
  BuildContext context,
  ProjectWorkspace workspaceNotifier,
  InferredImportKindFrb kind,
) async {
  final allowedExtensions = allowedExtensionsFor(
    kind,
    ImportKindPickerIntent.appendImport,
  )!;
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: allowedExtensions,
    allowMultiple: false,
  );
  if (result == null || result.files.isEmpty) return;

  final sourcePath = result.files.single.path;
  if (sourcePath == null || sourcePath.isEmpty) {
    workspaceNotifier.reportError('无法读取所选 EPUB 文件路径');
    return;
  }

  if (!context.mounted) return;

  try {
    final appendResult = await runAppBlockingOperation(
      context: context,
      message: '正在从 EPUB 追加页面…',
      operation: () => workspaceNotifier.appendEpub(sourcePath),
    );
    if (!context.mounted) return;
    await showAppAppendImportOutcome(
      context,
      addedPageCount: appendResult.addedPageCount,
      warnings: appendResult.warnings,
    );
  } catch (e) {
    if (!context.mounted) return;
    await showAppOperationFailure(
      context,
      title: '追加导入失败',
      message: e.toString(),
      nextStepHint: '请确认 EPUB 可读且与当前项目兼容。',
    );
  }
}
