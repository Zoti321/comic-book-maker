import 'dart:io';
import 'dart:typed_data';

import 'package:comic_book_maker/domain/use_cases/export_workflow.dart';
import 'package:comic_book_maker/domain/use_cases/mobile_export_platform.dart';
import 'package:comic_book_maker/domain/use_cases/mobile_export_workflow.dart';
import 'package:comic_book_maker/providers/core_gateway_provider.dart';
import 'package:comic_book_maker/providers/export_path_provider.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:comic_book_maker/ui/features/library/providers/library_provider.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_dialogs.dart';
import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_provider.dart';
import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_state.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// 导出并删除后离开编辑页：使用 [GoRouter.go] 替换路由栈。
void leaveProjectEditorAfterDeletedExport({
  required BuildContext context,
  required WidgetRef ref,
  required String projectId,
}) {
  ref.read(libraryOperationsProvider).refreshLibraryCatalog();
  ref.invalidate(projectWorkspaceProvider(projectId));
  if (context.mounted) {
    context.go(AppRoutes.projects);
  }
}

/// 读取全局默认导出目录：若 provider 首次仍在加载，则等待初始化完成一次。
Future<String?> readReadyGlobalExportDirectory(
  AsyncValue<String?> current, {
  required Future<String?> Function() awaitLoaded,
}) async {
  if (current.hasValue) return current.value;
  if (!current.isLoading) return null;
  try {
    return await awaitLoaded();
  } catch (_) {
    return null;
  }
}

/// 按项目工作流设置执行 Export（路径与导出后删除均来自 [ProjectSettings]）。
Future<void> runProjectExport({
  required BuildContext context,
  required WidgetRef ref,
  required ProjectWorkspaceState workspace,
  required String projectId,
  required ProjectWorkspace workspaceNotifier,
  Future<bool> Function()? prepareMetadataForExport,
}) async {
  if (prepareMetadataForExport != null) {
    final ready = await prepareMetadataForExport();
    if (!context.mounted) return;
    if (!ready) {
      await showProjectEditorOperationFailure(
        context,
        title: '无法导出',
        message: '元数据未保存成功，请先修正表单错误后重试。',
        nextStepHint: '检查元数据 Tab 中的红色校验提示。',
      );
      return;
    }
  }

  try {
    final workflow = ExportWorkflow(gateway: ref.read(coreGatewayProvider));

    if (usesMobileExportSaveFile()) {
      await _runMobileProjectExport(
        context: context,
        ref: ref,
        workspace: workspace,
        projectId: projectId,
        workflow: workflow,
      );
      return;
    }

    await _runDesktopProjectExport(
      context: context,
      ref: ref,
      workspace: workspace,
      projectId: projectId,
      workflow: workflow,
    );
  } catch (_) {
    if (!context.mounted) return;
    await showProjectEditorOperationFailure(
      context,
      title: '导出失败',
      message: '导出过程中发生未知错误。',
      nextStepHint: '请重试；若问题持续，请重启应用后再试。',
    );
  }
}

Future<void> _runDesktopProjectExport({
  required BuildContext context,
  required WidgetRef ref,
  required ProjectWorkspaceState workspace,
  required String projectId,
  required ExportWorkflow workflow,
}) async {
  final globalExportDirectory = await readReadyGlobalExportDirectory(
    ref.read(exportPathProvider),
    awaitLoaded: () => ref.read(exportPathProvider.future),
  );

  final plan = workflow.plan(
    ExportWorkflowRequest(
      projectTitle: workspace.project.title,
      settings: workspace.settings,
      globalExportDirectory: globalExportDirectory,
      hasPages: workspace.pages.isNotEmpty,
    ),
  );

  final ExportWorkflowReady readyPlan;
  switch (plan) {
    case ExportWorkflowBlocked(:final presentation):
      if (!context.mounted) return;
      await showProjectEditorOperationFailure(
        context,
        title: presentation.title,
        message: presentation.message,
        nextStepHint: presentation.nextStepHint,
      );
      return;
    case ExportWorkflowReady ready:
      readyPlan = ready;
  }

  final confirmed = await workflow.runConfirmations(
    needsOverwriteConfirmation: readyPlan.needsOverwriteConfirmation,
    deleteAfterExport: readyPlan.deleteAfterExport,
    confirmOverwrite: () => _confirmExportOverwrite(
      context: context,
      destinationPath: readyPlan.target.destinationPath,
    ),
    confirmDeleteProject: () => _confirmDeleteProjectAfterExport(
      context: context,
      projectTitle: workspace.project.title,
      formatLabel: readyPlan.target.formatLabel,
      destinationPath: readyPlan.target.destinationPath,
    ),
  );
  if (!confirmed || !context.mounted) return;

  await _executeProjectExport(
    context: context,
    ref: ref,
    workspace: workspace,
    projectId: projectId,
    workflow: workflow,
    readyPlan: readyPlan,
    exportFailureNextStepHint:
        '请检查目标路径是否可写，或在设置 / 项目属性中更换导出目录后重试。',
  );
}

Future<void> _runMobileProjectExport({
  required BuildContext context,
  required WidgetRef ref,
  required ProjectWorkspaceState workspace,
  required String projectId,
  required ExportWorkflow workflow,
}) async {
  final settings = workspace.settings;
  if (settings == null) {
    if (!context.mounted) return;
    await showProjectEditorOperationFailure(
      context,
      title: '无法导出',
      message: '项目设置尚未加载，请稍后重试。',
      nextStepHint: '若问题持续，请返回漫画库后重新打开项目。',
    );
    return;
  }

  final tempDir = await getTemporaryDirectory();
  final plan = workflow.plan(
    ExportWorkflowRequest(
      projectTitle: workspace.project.title,
      settings: mobileExportPlanningSettings(settings),
      globalExportDirectory: tempDir.path,
      hasPages: workspace.pages.isNotEmpty,
    ),
  );

  final ExportWorkflowReady readyTemplate;
  switch (plan) {
    case ExportWorkflowBlocked(:final presentation):
      if (!context.mounted) return;
      await showProjectEditorOperationFailure(
        context,
        title: presentation.title,
        message: presentation.message,
        nextStepHint: presentation.nextStepHint,
      );
      return;
    case ExportWorkflowReady ready:
      readyTemplate = ready;
  }

  final suggestedFileName = p.basename(readyTemplate.target.destinationPath);
  final tempPath = readyTemplate.target.destinationPath;
  final deleteAfterExport = readyTemplate.deleteAfterExport;

  if (!context.mounted) return;

  if (deleteAfterExport) {
    final confirmed = await _confirmDeleteProjectAfterExport(
      context: context,
      projectTitle: workspace.project.title,
      formatLabel: readyTemplate.target.formatLabel,
    );
    if (!confirmed || !context.mounted) return;
  }

  try {
    if (!context.mounted) return;
    try {
      await runProjectEditorDismissibleBackgroundOperation(
        context: context,
        message: readyTemplate.progressMessage,
        dismissHint: '可点击空白处关闭，导出将在后台继续',
        operation: () => workflow.execute(
          projectId: workspace.projectId,
          target: readyTemplate.target,
          deleteProjectAfterExport: false,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      final failure = workflow.presentationForCaughtFailure(e);
      await showProjectEditorOperationFailure(
        context,
        title: failure?.title ?? '导出失败',
        message: failure?.message ?? '导出过程中发生未知错误。',
        nextStepHint: failure?.nextStepHint ?? '请重试导出。',
      );
      return;
    }

    if (!context.mounted) return;

    final Uint8List exportBytes;
    try {
      exportBytes = await File(tempPath).readAsBytes();
    } catch (_) {
      if (!context.mounted) return;
      await showProjectEditorOperationFailure(
        context,
        title: '导出失败',
        message: '无法读取已生成的导出文件。',
        nextStepHint: '请重试导出。',
      );
      return;
    }

    final extension = p.extension(suggestedFileName);
    final allowedExtensions =
        extension.isNotEmpty ? [extension.substring(1)] : null;

    String? savedPath;
    try {
      savedPath = await FilePicker.platform.saveFile(
        dialogTitle: '导出 ${readyTemplate.target.formatLabel}',
        fileName: suggestedFileName,
        allowedExtensions: allowedExtensions,
        bytes: exportBytes,
      );
    } catch (_) {
      if (!context.mounted) return;
      await showProjectEditorOperationFailure(
        context,
        title: '无法保存',
        message: '打开系统保存对话框失败。',
        nextStepHint: '请重试导出并选择可写的保存位置。',
      );
      return;
    }

    if (!context.mounted) return;
    if (savedPath == null) return;

    showProjectEditorExportSuccessSnackBar(
      context,
      deletedProject: deleteAfterExport,
    );

    if (!context.mounted) return;

    if (deleteAfterExport) {
      ref.read(coreGatewayProvider).deleteProject(projectId: projectId);
      leaveProjectEditorAfterDeletedExport(
        context: context,
        ref: ref,
        projectId: projectId,
      );
    }
  } finally {
    _deleteFileIfExists(tempPath);
  }
}

void _deleteFileIfExists(String path) {
  try {
    final file = File(path);
    if (file.existsSync()) {
      file.deleteSync();
    }
  } catch (_) {}
}

Future<void> _executeProjectExport({
  required BuildContext context,
  required WidgetRef ref,
  required ProjectWorkspaceState workspace,
  required String projectId,
  required ExportWorkflow workflow,
  required ExportWorkflowReady readyPlan,
  required String exportFailureNextStepHint,
}) async {
  try {
    await runProjectEditorDismissibleBackgroundOperation(
      context: context,
      message: readyPlan.progressMessage,
      dismissHint: '可点击空白处关闭，导出将在后台继续',
      operation: () => workflow.execute(
        projectId: workspace.projectId,
        target: readyPlan.target,
        deleteProjectAfterExport: readyPlan.deleteAfterExport,
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    final failure = workflow.presentationForCaughtFailure(e);
    await showProjectEditorOperationFailure(
      context,
      title: failure?.title ?? '导出失败',
      message: failure?.message ?? '导出过程中发生未知错误。',
      nextStepHint: failure?.nextStepHint ?? exportFailureNextStepHint,
    );
    return;
  }

  if (!context.mounted) return;

  showProjectEditorExportSuccessSnackBar(
    context,
    deletedProject: readyPlan.deleteAfterExport,
  );

  if (!context.mounted) return;

  if (readyPlan.deleteAfterExport) {
    leaveProjectEditorAfterDeletedExport(
      context: context,
      ref: ref,
      projectId: projectId,
    );
  }
}

Future<bool> _confirmExportOverwrite({
  required BuildContext context,
  required String destinationPath,
}) async {
  if (!context.mounted) return false;
  final result = await showProjectEditorConfirmDialog(
    context: context,
    title: '覆盖已有文件？',
    description: Text(
      '目标位置已存在文件：\n$destinationPath\n\n'
      '继续将覆盖该文件。',
    ),
    confirmLabel: '覆盖并导出',
    destructive: true,
  );
  return result == true;
}

Future<bool> _confirmDeleteProjectAfterExport({
  required BuildContext context,
  required String projectTitle,
  required String formatLabel,
  String? destinationPath,
}) async {
  if (!context.mounted) return false;

  final saveLocationDescription = destinationPath == null
      ? '保存位置将在下一步由系统文件对话框选择。\n\n'
      : '并保存至：\n$destinationPath\n\n';

  final result = await showProjectEditorConfirmDialog(
    context: context,
    title: '导出并删除项目',
    description: Text(
      '将导出「$projectTitle」为 $formatLabel，'
      '$saveLocationDescription'
      '导出完成后，本地页面与元数据将被永久删除，此操作不可恢复。',
    ),
    confirmLabel: '导出并删除',
    destructive: true,
  );
  return result == true;
}
