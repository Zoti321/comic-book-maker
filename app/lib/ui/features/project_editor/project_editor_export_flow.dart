import 'package:comic_book_maker/domain/use_cases/archive_export_runner.dart';
import 'package:comic_book_maker/domain/use_cases/export_workflow_resolver.dart';
import 'package:comic_book_maker/providers/export_path_provider.dart';
import 'package:comic_book_maker/ui/features/library/providers/library_provider.dart';
import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_provider.dart';
import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_state.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:comic_book_maker/ui/core/design_system/design_system.dart';
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
  required ProjectWorkspace workspaceNotifier,
  Future<bool> Function()? prepareMetadataForExport,
}) async {
  if (workspace.exporting || workspace.pages.isEmpty) return;

  if (prepareMetadataForExport != null) {
    final ready = await prepareMetadataForExport();
    if (!ready || !context.mounted) return;
  }

  final settings = workspace.settings;
  final globalExportDirectory = await readReadyGlobalExportDirectory(
    ref.read(exportPathProvider),
    awaitLoaded: () => ref.read(exportPathProvider.future),
  );
  final safeTitle =
      workspace.project.title.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

  final block = resolveExportBlock(
    settings: settings,
    globalExportDirectory: globalExportDirectory,
    safeTitle: safeTitle,
  );
  if (block != null) {
    if (!context.mounted) return;
    await showAppOperationFailure(
      context,
      title: block.title,
      message: block.message,
      nextStepHint: block.nextStepHint,
    );
    return;
  }

  final target = resolveExportTarget(
    settings: settings!,
    globalExportDirectory: globalExportDirectory,
    safeTitle: safeTitle,
  );
  if (target == null) return;

  final deleteAfterExport = settings.deleteProjectAfterExport;
  if (deleteAfterExport) {
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: '导出并删除项目',
      description: Text(
        '将导出「${workspace.project.title}」为 ${target.formatLabel} 并保存至：\n'
        '${target.destinationPath}\n\n'
        '导出完成后，本地页面与元数据将被永久删除，此操作不可恢复。',
      ),
      confirmLabel: '导出并删除',
      destructive: true,
    );
    if (confirmed != true || !context.mounted) return;
  }

  final exportRunner = ArchiveExportRunner();

  try {
    await runAppBlockingOperation(
      context: context,
      message: '正在导出 ${target.formatLabel}…',
      operation: () => exportRunner.exportProject(
        projectId: workspace.projectId,
        target: target,
        deleteProjectAfterExport: deleteAfterExport,
      ),
    );
  } catch (e) {
    if (!context.mounted) return;
    await showAppOperationFailure(
      context,
      title: '导出失败',
      message: e.toString(),
      nextStepHint: '请检查目标路径是否可写，或在设置 / 项目属性中更换导出目录后重试。',
    );
    return;
  }

  if (!context.mounted) return;

  await showAppExportSuccessDialog(
    context,
    destinationPath: target.destinationPath,
    deletedProject: deleteAfterExport,
  );

  if (!context.mounted) return;

  if (deleteAfterExport) {
    leaveProjectEditorAfterDeletedExport(
      context: context,
      ref: ref,
      projectId: workspace.projectId,
    );
  }
}
