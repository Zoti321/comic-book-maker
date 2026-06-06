import 'dart:io';

import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/use_cases/export_failure_presentation.dart';
import 'package:path/path.dart' as p;

/// 解析后的 Export 目标路径与 Core API 选项。
class ResolvedExportTarget {
  const ResolvedExportTarget({
    required this.destinationPath,
    required this.formatLabel,
    required this.exportComicArchive,
    this.comicArchiveContainer,
  });

  final String destinationPath;
  final String formatLabel;
  final bool exportComicArchive;
  final ComicArchiveContainerFrb? comicArchiveContainer;
}

/// Flutter 侧在调用 Core 前阻断 Export 的原因。
enum ExportWorkflowBlockReason {
  settingsNotLoaded,
  pdfNotImplemented,
  archiveContainerNotImplemented,
  exportDirectoryMissing,
  noPages,
}

class ExportWorkflowBlock {
  const ExportWorkflowBlock({
    required this.reason,
    required this.title,
    required this.message,
    required this.nextStepHint,
  });

  final ExportWorkflowBlockReason reason;
  final String title;
  final String message;
  final String nextStepHint;

  ExportFailurePresentation toPresentation() => ExportFailurePresentation(
        title: title,
        message: message,
        nextStepHint: nextStepHint,
      );
}

enum ExportPreflightStatus {
  ready,
  blocked,
  needsOverwriteConfirmation,
}

class ExportPreflightResult {
  const ExportPreflightResult._({
    required this.status,
    this.presentation,
  });

  const ExportPreflightResult.ready()
      : this._(status: ExportPreflightStatus.ready);

  const ExportPreflightResult.blocked(ExportFailurePresentation presentation)
      : this._(status: ExportPreflightStatus.blocked, presentation: presentation);

  const ExportPreflightResult.needsOverwriteConfirmation()
      : this._(status: ExportPreflightStatus.needsOverwriteConfirmation);

  final ExportPreflightStatus status;
  final ExportFailurePresentation? presentation;

  bool get isBlocked => status == ExportPreflightStatus.blocked;
  bool get needsOverwriteConfirmation =>
      status == ExportPreflightStatus.needsOverwriteConfirmation;
}

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

  String get safeTitle =>
      projectTitle.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');
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
  });

  final ResolvedExportTarget target;
  final bool deleteAfterExport;
  final bool needsOverwriteConfirmation;

  String get progressMessage => '正在导出 ${target.formatLabel}…';
}

/// [Export](CONTEXT.md) 用例：路径解析、preflight、确认顺序与 Core 调用。
class ExportWorkflow {
  ExportWorkflow({CoreGateway? gateway})
      : _gateway = gateway ?? const FrbCoreGateway();

  final CoreGateway _gateway;

  ExportWorkflowPlan plan(ExportWorkflowRequest request) {
    if (!request.hasPages) {
      return const ExportWorkflowBlocked(
        ExportFailurePresentation(
          title: '无法导出',
          message: 'Export 需要至少一页。',
          nextStepHint: '请先为项目添加页面后再导出。',
        ),
      );
    }

    final block = resolveExportBlock(
      settings: request.settings,
      globalExportDirectory: request.globalExportDirectory,
      safeTitle: request.safeTitle,
    );
    if (block != null) {
      return ExportWorkflowBlocked(block.toPresentation());
    }

    final settings = request.settings!;
    final target = resolveExportTarget(
      settings: settings,
      globalExportDirectory: request.globalExportDirectory,
      safeTitle: request.safeTitle,
    );
    if (target == null) {
      return const ExportWorkflowBlocked(
        ExportFailurePresentation(
          title: '无法导出',
          message: '无法解析导出目标，请检查项目设置。',
          nextStepHint: '若问题持续，请返回漫画库后重新打开项目。',
        ),
      );
    }

    final preflight = checkExportPreflight(target.destinationPath);
    if (preflight.isBlocked) {
      return ExportWorkflowBlocked(preflight.presentation!);
    }

    return ExportWorkflowReady(
      target: target,
      deleteAfterExport: settings.deleteProjectAfterExport,
      needsOverwriteConfirmation: preflight.needsOverwriteConfirmation,
    );
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
        deleteProjectAfterExport: deleteProjectAfterExport,
      );

  ExportFailurePresentation? presentationForCaughtFailure(Object error) =>
      presentationForCaughtExportFailure(error);
}

ExportWorkflowBlock? resolveExportBlock({
  required ProjectSettings? settings,
  required String? globalExportDirectory,
  required String safeTitle,
}) {
  if (settings == null) {
    return const ExportWorkflowBlock(
      reason: ExportWorkflowBlockReason.settingsNotLoaded,
      title: '无法导出',
      message: '项目设置尚未加载，请稍后重试。',
      nextStepHint: '若问题持续，请返回漫画库后重新打开项目。',
    );
  }

  if (settings.exportFormat == ExportFormatFrb.pdf) {
    return const ExportWorkflowBlock(
      reason: ExportWorkflowBlockReason.pdfNotImplemented,
      title: '无法导出 PDF',
      message: 'PDF Export 尚未实现。',
      nextStepHint: '请在项目属性中将 Export 格式改为漫画压缩包或 EPUB 后重试。',
    );
  }

  final exportComicArchive =
      settings.exportFormat == ExportFormatFrb.comicArchive;

  if (exportComicArchive && !isComicArchiveContainerImplemented(settings)) {
    return ExportWorkflowBlock(
      reason: ExportWorkflowBlockReason.archiveContainerNotImplemented,
      title: '无法导出',
      message:
          '「${comicArchiveContainerLabel(settings.comicArchiveContainer)}」容器 Export 尚未实现。',
      nextStepHint: '请在项目属性中将压缩算法改为 ZIP 或 RAR，或等待后续版本支持。',
    );
  }

  final directory = _resolveExportDirectory(
    settings: settings,
    globalExportDirectory: globalExportDirectory,
  );
  if (directory == null) {
    final useGlobal = settings.useDefaultExportDirectory;
    return ExportWorkflowBlock(
      reason: ExportWorkflowBlockReason.exportDirectoryMissing,
      title: '无法导出',
      message: useGlobal ? '尚未配置应用默认导出目录。' : '尚未配置本项目的专用导出目录。',
      nextStepHint: useGlobal
          ? '请在「设置」中配置默认导出目录。'
          : '请在项目属性 → 导出中配置专用导出目录，或改为沿用全局默认目录。',
    );
  }

  return null;
}

ResolvedExportTarget? resolveExportTarget({
  required ProjectSettings settings,
  required String? globalExportDirectory,
  required String safeTitle,
}) {
  if (resolveExportBlock(
        settings: settings,
        globalExportDirectory: globalExportDirectory,
        safeTitle: safeTitle,
      ) !=
      null) {
    return null;
  }

  final directory = _resolveExportDirectory(
    settings: settings,
    globalExportDirectory: globalExportDirectory,
  )!;
  final exportComicArchive =
      settings.exportFormat == ExportFormatFrb.comicArchive;
  final fileName = exportComicArchive
      ? comicArchiveExportFileName(settings, safeTitle)
      : '$safeTitle.epub';
  final formatLabel = exportComicArchive
      ? comicArchiveExportFormatLabel(settings)
      : 'EPUB';

  return ResolvedExportTarget(
    destinationPath: p.join(directory, fileName),
    formatLabel: formatLabel,
    exportComicArchive: exportComicArchive,
    comicArchiveContainer:
        exportComicArchive ? settings.comicArchiveContainer : null,
  );
}

bool isComicArchiveContainerImplemented(ProjectSettings settings) {
  return switch (settings.comicArchiveContainer) {
    ComicArchiveContainerFrb.zip => true,
    ComicArchiveContainerFrb.rar => true,
    ComicArchiveContainerFrb.sevenZip => false,
  };
}

String comicArchiveFileExtension(ProjectSettings settings) {
  return switch (settings.comicArchiveContainer) {
    ComicArchiveContainerFrb.zip =>
      settings.useComicArchiveExtension ? 'cbz' : 'zip',
    ComicArchiveContainerFrb.sevenZip =>
      settings.useComicArchiveExtension ? 'cb7' : '7z',
    ComicArchiveContainerFrb.rar =>
      settings.useComicArchiveExtension ? 'cbr' : 'rar',
  };
}

String comicArchiveExportFileName(ProjectSettings settings, String safeTitle) {
  return '$safeTitle.${comicArchiveFileExtension(settings)}';
}

String comicArchiveExportFormatLabel(ProjectSettings settings) {
  return switch (settings.comicArchiveContainer) {
    ComicArchiveContainerFrb.zip =>
      settings.useComicArchiveExtension ? 'CBZ' : 'ZIP',
    ComicArchiveContainerFrb.rar =>
      settings.useComicArchiveExtension ? 'CBR' : 'RAR',
    ComicArchiveContainerFrb.sevenZip =>
      comicArchiveContainerLabel(settings.comicArchiveContainer),
  };
}

String comicArchiveContainerLabel(ComicArchiveContainerFrb container) {
  return switch (container) {
    ComicArchiveContainerFrb.zip => 'ZIP',
    ComicArchiveContainerFrb.sevenZip => '7Z',
    ComicArchiveContainerFrb.rar => 'RAR',
  };
}

bool comicArchiveContainerSelectable(ComicArchiveContainerFrb container) {
  return switch (container) {
    ComicArchiveContainerFrb.zip => true,
    ComicArchiveContainerFrb.rar => true,
    ComicArchiveContainerFrb.sevenZip => false,
  };
}

ExportPreflightResult checkExportPreflight(String destinationPath) {
  final normalized = p.normalize(destinationPath.trim());
  if (normalized.isEmpty) {
    return const ExportPreflightResult.blocked(
      ExportFailurePresentation(
        title: '无法导出',
        message: '导出目标路径无效。',
        nextStepHint: '请在项目属性或设置中检查导出目录配置。',
      ),
    );
  }

  final destinationType =
      FileSystemEntity.typeSync(normalized, followLinks: false);
  if (destinationType == FileSystemEntityType.directory) {
    return ExportPreflightResult.blocked(
      ExportFailurePresentation(
        title: '无法导出',
        message: '导出目标不能是文件夹，请检查项目或全局导出目录设置。',
        nextStepHint: normalized,
      ),
    );
  }

  if (destinationType == FileSystemEntityType.file) {
    return const ExportPreflightResult.needsOverwriteConfirmation();
  }

  final parentPath = p.dirname(normalized);
  if (parentPath.isEmpty || parentPath == normalized) {
    return const ExportPreflightResult.ready();
  }

  final parentType = FileSystemEntity.typeSync(parentPath, followLinks: false);
  if (parentType == FileSystemEntityType.notFound) {
    return ExportPreflightResult.blocked(
      ExportFailurePresentation(
        title: '无法导出',
        message: '无法写入导出目录，请检查路径是否存在以及是否有写入权限。',
        nextStepHint: 'export directory does not exist: $parentPath',
      ),
    );
  }

  if (parentType != FileSystemEntityType.directory) {
    return ExportPreflightResult.blocked(
      ExportFailurePresentation(
        title: '无法导出',
        message: '无法写入导出目录，请检查路径是否存在以及是否有写入权限。',
        nextStepHint: 'export parent path is not a directory: $parentPath',
      ),
    );
  }

  if (!isDirectoryWritable(parentPath)) {
    return ExportPreflightResult.blocked(
      ExportFailurePresentation(
        title: '无法导出',
        message: '无法写入导出目录，请检查路径是否存在以及是否有写入权限。',
        nextStepHint: 'export directory is not writable: $parentPath',
      ),
    );
  }

  return const ExportPreflightResult.ready();
}

bool isDirectoryWritable(String directoryPath) {
  final probePath = p.join(
    directoryPath,
    '.cbm-write-probe-${DateTime.now().microsecondsSinceEpoch}',
  );
  final probe = File(probePath);
  try {
    probe.createSync(recursive: false);
    probe.deleteSync();
    return true;
  } catch (_) {
    return false;
  }
}

Future<bool> runExportConfirmations({
  required ExportPreflightResult preflight,
  required bool deleteAfterExport,
  required Future<bool> Function() confirmOverwrite,
  required Future<bool> Function() confirmDeleteProject,
}) =>
    _runExportConfirmations(
      needsOverwriteConfirmation: preflight.needsOverwriteConfirmation,
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

String? _resolveExportDirectory({
  required ProjectSettings settings,
  required String? globalExportDirectory,
}) {
  if (settings.useDefaultExportDirectory) {
    final trimmed = globalExportDirectory?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  final projectDir = settings.exportDirectory?.trim();
  if (projectDir == null || projectDir.isEmpty) {
    return null;
  }
  return projectDir;
}
