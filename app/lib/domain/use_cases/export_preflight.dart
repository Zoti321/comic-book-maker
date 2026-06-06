import 'dart:io';

import 'package:comic_book_maker/domain/use_cases/export_failure_presentation.dart';
import 'package:path/path.dart' as p;

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

/// Runs overwrite / delete confirmations in the agreed order.
Future<bool> runExportConfirmations({
  required ExportPreflightResult preflight,
  required bool deleteAfterExport,
  required Future<bool> Function() confirmOverwrite,
  required Future<bool> Function() confirmDeleteProject,
}) async {
  if (preflight.needsOverwriteConfirmation) {
    final confirmed = await confirmOverwrite();
    if (!confirmed) return false;
  }

  if (deleteAfterExport) {
    final confirmed = await confirmDeleteProject();
    if (!confirmed) return false;
  }

  return true;
}
