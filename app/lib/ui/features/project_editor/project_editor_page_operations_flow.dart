import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_provider.dart';
import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_state.dart';
import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_dialogs.dart';
import 'package:comic_book_maker/domain/use_cases/page_import_rules.dart';
import 'package:comic_book_maker/ui/features/project_editor/pages/page_image_viewer.dart';
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

  await _runPageOperation(
    context: context,
    failureTitle: '添加页面失败',
    nextStepHint: '请确认文件为受支持的图片格式且未被其他程序占用。',
    blockingMessage: '正在添加图片…',
    operation: () => workspaceNotifier.addPageImages(sourcePaths),
  );
}

/// 替换单页图片：按项目 [inferred_import_kind] 限制可选扩展名。
Future<void> runReplacePageImage({
  required BuildContext context,
  required ProjectWorkspaceState workspace,
  required ProjectWorkspace workspaceNotifier,
  required PageSummary page,
}) async {
  final kind = workspace.settings?.inferredImportKind;
  if (kind == null) return;

  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: allowedExtensionsFor(
      kind,
      ImportKindPickerIntent.replacePage,
    )!,
  );
  if (result == null || result.files.isEmpty) return;
  final sourcePath = result.files.single.path;
  if (sourcePath == null || sourcePath.isEmpty) {
    workspaceNotifier.reportError('无法读取所选文件路径');
    return;
  }
  if (!context.mounted) return;

  await _runPageOperation(
    context: context,
    failureTitle: '替换页面失败',
    nextStepHint: '请确认文件格式受支持且未被其他程序占用。',
    blockingMessage: '正在替换页面…',
    operation: () => workspaceNotifier.replacePage(page.id, sourcePath),
  );
}

/// 删除页面：确认后执行。
Future<void> runDeletePage({
  required BuildContext context,
  required ProjectWorkspace workspaceNotifier,
  required PageSummary page,
}) async {
  final confirmed = await showProjectEditorConfirmDialog(
    context: context,
    title: '删除页面',
    description: Text('确定删除第 ${page.sortIndex + 1} 页？'),
    confirmLabel: '删除',
    destructive: true,
  );
  if (confirmed != true || !context.mounted) return;

  await _runPageOperation(
    context: context,
    failureTitle: '删除页面失败',
    nextStepHint: '请稍后重试；若问题持续，请检查项目文件是否可写。',
    operation: () => workspaceNotifier.deletePage(page.id),
  );
}

/// 将指定页的 [sortIndex] 设为封面。
Future<void> runSetCoverPage({
  required BuildContext context,
  required ProjectWorkspace workspaceNotifier,
  required PageSummary page,
}) async {
  if (!context.mounted) return;

  await _runPageOperation(
    context: context,
    failureTitle: '设置封面失败',
    nextStepHint: '请确认元数据可保存后重试。',
    operation: () => workspaceNotifier.setCoverPage(page.sortIndex),
  );
}

Future<void> runMovePageEarlier({
  required BuildContext context,
  required ProjectWorkspace workspaceNotifier,
  required PageSummary page,
}) async {
  await _runPageOperation(
    context: context,
    failureTitle: '移动页面失败',
    nextStepHint: '请稍后重试。',
    operation: () => workspaceNotifier.movePageEarlier(page),
  );
}

Future<void> runMovePageLater({
  required BuildContext context,
  required ProjectWorkspace workspaceNotifier,
  required PageSummary page,
}) async {
  await _runPageOperation(
    context: context,
    failureTitle: '移动页面失败',
    nextStepHint: '请稍后重试。',
    operation: () => workspaceNotifier.movePageLater(page),
  );
}

Future<void> runViewPageOriginal({
  required BuildContext context,
  required List<PageSummary> pages,
  required PageSummary page,
}) =>
    showPageImageViewer(
      context,
      pages: pages,
      initialPage: page,
    );

Future<void> _runPageOperation({
  required BuildContext context,
  required String failureTitle,
  required String nextStepHint,
  required Future<void> Function() operation,
  String? blockingMessage,
}) async {
  try {
    if (blockingMessage != null) {
      await runProjectEditorBlockingOperation(
        context: context,
        message: blockingMessage,
        operation: operation,
      );
    } else {
      await operation();
    }
  } catch (e) {
    if (!context.mounted) return;
    await showProjectEditorOperationFailure(
      context,
      title: failureTitle,
      message: e.toString(),
      nextStepHint: nextStepHint,
    );
  }
}
