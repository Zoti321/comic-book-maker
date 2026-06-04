import 'package:comic_book_maker/application/archive_import_runner.dart';
import 'package:comic_book_maker/providers/project_workspace_provider.dart';
import 'package:comic_book_maker/providers/project_workspace_state.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/ui/design_system/append_archive_sheet.dart';
import 'package:comic_book_maker/ui/design_system/design_system.dart';
import 'package:comic_book_maker/ui/design_system/import_archive_sheet.dart';
import 'package:comic_book_maker/ui/import_kind_picker_rules.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
      await _appendArchive(context, workspace, workspaceNotifier);
    case InferredImportKindFrb.epub:
      await _appendEpubArchive(context, workspace, workspaceNotifier);
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
  ProjectWorkspaceState workspace,
  ProjectWorkspace workspaceNotifier,
) async {
  final sheetFormat = await showAppendArchiveSheet(context);
  if (sheetFormat == null || !context.mounted) return;

  final runner = ArchiveImportRunner();
  final format = ArchiveImportRunner.fromAppendFormat(sheetFormat);

  try {
    final sourcePath = await runner.pickSourcePath(format);
    if (sourcePath == null || !context.mounted) return;

    final appendResult = await runAppBlockingOperation(
      context: context,
      message: runner.appendBlockingMessage(format),
      operation: () async => runner.appendToProject(
        projectId: workspace.projectId,
        format: format,
        sourcePath: sourcePath,
      ),
    );
    if (!context.mounted) return;
    workspaceNotifier.reloadPages();
    await showAppAppendImportOutcome(
      context,
      addedPageCount: appendResult.addedPageCount,
      warnings: appendResult.warnings,
    );
  } on StateError catch (e) {
    workspaceNotifier.reportError(e.message);
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

Future<void> _appendEpubArchive(
  BuildContext context,
  ProjectWorkspaceState workspace,
  ProjectWorkspace workspaceNotifier,
) async {
  final runner = ArchiveImportRunner();
  const format = ImportArchiveFormat.epub;

  try {
    final sourcePath = await runner.pickSourcePath(format);
    if (sourcePath == null || !context.mounted) return;

    final appendResult = await runAppBlockingOperation(
      context: context,
      message: runner.appendBlockingMessage(format),
      operation: () async => runner.appendToProject(
        projectId: workspace.projectId,
        format: format,
        sourcePath: sourcePath,
      ),
    );
    if (!context.mounted) return;
    workspaceNotifier.reloadPages();
    await showAppAppendImportOutcome(
      context,
      addedPageCount: appendResult.addedPageCount,
      warnings: appendResult.warnings,
    );
  } on StateError catch (e) {
    workspaceNotifier.reportError(e.message);
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
