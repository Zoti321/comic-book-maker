import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/data/repositories/core_gateway_types.dart';
import 'package:comic_book_maker/data/repositories/gateways/export_gateway.dart';
import 'package:comic_book_maker/domain/use_cases/export_failure_presentation.dart';
import 'package:comic_book_maker/src/rust/api/export.dart';

export 'package:comic_book_maker/src/rust/api/export.dart'
    show
        comicArchiveContainerLabel,
        comicArchiveFileExtension,
        isComicArchiveContainerImplemented,
        isComicArchiveContainerSelectable,
        sanitizeExportTitle;

/// 解析后的 Export 目标路径与 Core API 选项。
typedef ResolvedExportTarget = ResolvedExportTargetFrb;

/// 规划一次 [Export](CONTEXT.md) 所需的输入。
class ExportWorkflowRequest {
  const ExportWorkflowRequest({
    required this.projectTitle,
    required this.settings,
    required this.globalExportDirectory,
    required this.hasPages,
  });

  final String projectTitle;
  final ProjectSettings? settings;
  final String? globalExportDirectory;
  final bool hasPages;

  String get safeTitle => sanitizeExportTitle(title: projectTitle);
}

/// Export 会话规划结果。
sealed class ExportWorkflowPlan {
  const ExportWorkflowPlan();
}

/// 路径 / 设置 / 磁盘检查未通过，无法继续。
final class ExportWorkflowBlocked extends ExportWorkflowPlan {
  const ExportWorkflowBlocked(this.presentation);

  final ExportFailurePresentation presentation;
}

/// 可执行 Export；UI 须按需确认覆盖与导出后删除。
final class ExportWorkflowReady extends ExportWorkflowPlan {
  const ExportWorkflowReady({
    required this.target,
    required this.deleteAfterExport,
    required this.needsOverwriteConfirmation,
    required this.progressMessage,
  });

  final ResolvedExportTarget target;
  final bool deleteAfterExport;
  final bool needsOverwriteConfirmation;
  final String progressMessage;
}

/// [Export](CONTEXT.md) 用例：规划委托 Core，确认顺序与写出仍由 Flutter 编排。
class ExportWorkflow {
  ExportWorkflow({ExportGateway? gateway})
      : _gateway = gateway ?? const FrbCoreGateway();

  final ExportGateway _gateway;

  ExportWorkflowPlan plan(ExportWorkflowRequest request) {
    final result = planExport(
      request: ExportPlanRequestFrb(
        projectTitle: request.projectTitle,
        settings: request.settings,
        globalExportDirectory: request.globalExportDirectory,
        hasPages: request.hasPages,
      ),
    );

    return switch (result) {
      ExportPlanResultFrb_Blocked(:final presentation) =>
        ExportWorkflowBlocked(presentation),
      ExportPlanResultFrb_Ready(:final field0) => ExportWorkflowReady(
          target: field0.target,
          deleteAfterExport: field0.deleteAfterExport,
          needsOverwriteConfirmation: field0.needsOverwriteConfirmation,
          progressMessage: field0.progressMessage,
        ),
    };
  }

  Future<bool> runConfirmations({
    required bool needsOverwriteConfirmation,
    required bool deleteAfterExport,
    required Future<bool> Function() confirmOverwrite,
    required Future<bool> Function() confirmDeleteProject,
  }) {
    return _runExportConfirmations(
      needsOverwriteConfirmation: needsOverwriteConfirmation,
      deleteAfterExport: deleteAfterExport,
      confirmOverwrite: confirmOverwrite,
      confirmDeleteProject: confirmDeleteProject,
    );
  }

  Future<void> execute({
    required String projectId,
    required ResolvedExportTarget target,
    required bool deleteProjectAfterExport,
  }) =>
      _gateway.exportArchive(
        projectId: projectId,
        destinationPath: target.destinationPath,
        exportComicArchive: target.exportComicArchive,
        comicArchiveContainer: target.comicArchiveContainer,
        exportPdf: target.exportPdf,
        deleteProjectAfterExport: deleteProjectAfterExport,
      );

  ExportFailurePresentation? presentationForCaughtFailure(Object error) =>
      presentationForCaughtExportFailure(error);
}

Future<bool> runExportConfirmations({
  required bool needsOverwriteConfirmation,
  required bool deleteAfterExport,
  required Future<bool> Function() confirmOverwrite,
  required Future<bool> Function() confirmDeleteProject,
}) =>
    _runExportConfirmations(
      needsOverwriteConfirmation: needsOverwriteConfirmation,
      deleteAfterExport: deleteAfterExport,
      confirmOverwrite: confirmOverwrite,
      confirmDeleteProject: confirmDeleteProject,
    );

Future<bool> _runExportConfirmations({
  required bool needsOverwriteConfirmation,
  required bool deleteAfterExport,
  required Future<bool> Function() confirmOverwrite,
  required Future<bool> Function() confirmDeleteProject,
}) async {
  if (needsOverwriteConfirmation) {
    final confirmed = await confirmOverwrite();
    if (!confirmed) return false;
  }

  if (deleteAfterExport) {
    final confirmed = await confirmDeleteProject();
    if (!confirmed) return false;
  }

  return true;
}
