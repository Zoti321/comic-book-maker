import 'package:comic_book_maker/src/rust/export_error.dart';

/// User-facing copy for an [ExportError] from Core.
class ExportFailurePresentation {
  const ExportFailurePresentation({
    required this.title,
    required this.message,
    this.nextStepHint,
  });

  final String title;
  final String message;
  final String? nextStepHint;
}

ExportFailurePresentation presentationForExportError(ExportError error) {
  return switch (error.kind) {
    ExportErrorKind.destinationExists => ExportFailurePresentation(
        title: '无法导出',
        message: '目标位置已存在同名文件。',
        nextStepHint: _optionalDetailHint(error.detail),
      ),
    ExportErrorKind.destinationIsDirectory => ExportFailurePresentation(
        title: '无法导出',
        message: '导出目标不能是文件夹，请检查项目或全局导出目录设置。',
        nextStepHint: _optionalDetailHint(error.detail),
      ),
    ExportErrorKind.destinationNotWritable => ExportFailurePresentation(
        title: '无法导出',
        message: '无法写入导出目录，请检查路径是否存在以及是否有写入权限。',
        nextStepHint: _optionalDetailHint(error.detail),
      ),
    ExportErrorKind.destinationLocked => ExportFailurePresentation(
        title: '无法导出',
        message: '目标文件正被其他程序占用，请关闭相关程序后重试。',
        nextStepHint: _optionalDetailHint(error.detail),
      ),
    ExportErrorKind.destinationFinalizeFailed => ExportFailurePresentation(
        title: '导出失败',
        message: '文件已写入但无法完成保存，请检查目标路径后重试。',
        nextStepHint: _optionalDetailHint(error.detail),
      ),
    ExportErrorKind.pageAssetMissing => ExportFailurePresentation(
        title: '无法导出',
        message: '某页图片文件找不到，项目资源可能已损坏或被移动。',
        nextStepHint: _optionalDetailHint(error.detail),
      ),
    ExportErrorKind.pageAssetUnreadable => ExportFailurePresentation(
        title: '无法导出',
        message: '无法读取某页图片，请检查文件权限或是否被占用。',
        nextStepHint: _optionalDetailHint(error.detail),
      ),
    ExportErrorKind.insufficientSpace => ExportFailurePresentation(
        title: '无法导出',
        message: '磁盘空间不足，无法完成导出。',
        nextStepHint: _optionalDetailHint(error.detail),
      ),
    ExportErrorKind.archiveWriteFailed => ExportFailurePresentation(
        title: '导出失败',
        message: '生成档案文件时出错，请稍后重试。',
        nextStepHint: _optionalDetailHint(error.detail),
      ),
    ExportErrorKind.noPages => const ExportFailurePresentation(
        title: '无法导出',
        message: 'Export 需要至少一页。',
        nextStepHint: '请先为项目添加页面后再导出。',
      ),
    ExportErrorKind.projectNotFound => ExportFailurePresentation(
        title: '无法导出',
        message: '找不到当前项目，可能已被删除。',
        nextStepHint: _optionalDetailHint(error.detail),
      ),
    ExportErrorKind.deleteAfterExportFailed => ExportFailurePresentation(
        title: '导出部分完成',
        message: '文件已导出，但删除本地项目失败。',
        nextStepHint: _optionalDetailHint(error.detail),
      ),
  };
}

ExportFailurePresentation? presentationForExportFailure(Object error) {
  if (error is ExportError) {
    return presentationForExportError(error);
  }
  return null;
}

String? _optionalDetailHint(String detail) {
  final trimmed = detail.trim();
  if (trimmed.isEmpty) return null;
  return trimmed;
}
