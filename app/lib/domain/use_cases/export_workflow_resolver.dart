import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:path/path.dart' as p;

/// Resolved export target on disk plus labels for UI / Core API choice.
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

/// Why export cannot proceed before calling Core.
enum ExportWorkflowBlockReason {
  settingsNotLoaded,
  pdfNotImplemented,
  archiveContainerNotImplemented,
  exportDirectoryMissing,
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
}

/// Builds destination path from [settings] and app-global default directory.
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

/// Whether Core can Export with the selected comic archive container.
bool isComicArchiveContainerImplemented(ProjectSettings settings) {
  return switch (settings.comicArchiveContainer) {
    ComicArchiveContainerFrb.zip => true,
    ComicArchiveContainerFrb.rar => true,
    ComicArchiveContainerFrb.sevenZip => false,
  };
}

/// File extension (no dot) for the comic archive export file name.
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
