import 'package:comic_book_maker/domain/use_cases/export_workflow.dart';
import 'package:comic_book_maker/providers/core_gateway_provider.dart';
import 'package:comic_book_maker/providers/export_path_provider.dart';
import 'package:comic_book_maker/ui/features/library/providers/library_provider.dart';
import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_provider.dart';
import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_state.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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

  final globalExportDirectory = await readReadyGlobalExportDirectory(
    ref.read(exportPathProvider),
    awaitLoaded: () => ref.read(exportPathProvider.future),
  );

  final workflow = ExportWorkflow(gateway: ref.read(coreGatewayProvider));
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
    confirmOverwrite: () async {
      if (!context.mounted) return false;
      final result = await showProjectEditorConfirmDialog(
        context: context,
        title: '覆盖已有文件？',
        description: Text(
          '目标位置已存在文件：\n${readyPlan.target.destinationPath}\n\n'
          '继续将覆盖该文件。',
        ),
        confirmLabel: '覆盖并导出',
        destructive: true,
      );
      return result == true;
    },
    confirmDeleteProject: () async {
      if (!context.mounted) return false;
      final result = await showProjectEditorConfirmDialog(
        context: context,
        title: '导出并删除项目',
        description: Text(
          '将导出「${workspace.project.title}」为 ${readyPlan.target.formatLabel} 并保存至：\n'
          '${readyPlan.target.destinationPath}\n\n'
          '导出完成后，本地页面与元数据将被永久删除，此操作不可恢复。',
        ),
        confirmLabel: '导出并删除',
        destructive: true,
      );
      return result == true;
    },
  );
  if (!confirmed || !context.mounted) return;

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
      nextStepHint: failure?.nextStepHint ??
          '请检查目标路径是否可写，或在设置 / 项目属性中更换导出目录后重试。',
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
