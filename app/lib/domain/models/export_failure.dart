/// Core [Export](CONTEXT.md) 失败原因（domain 接缝，与 FRB 解耦）。
enum ExportFailureKind {
  destinationExists,
  destinationIsDirectory,
  destinationNotWritable,
  destinationLocked,
  destinationFinalizeFailed,
  pageAssetMissing,
  pageAssetUnreadable,
  insufficientSpace,
  archiveWriteFailed,
  noPages,
  projectNotFound,
  deleteAfterExportFailed,
}

/// Repository 将 FRB [ExportError] 映射为此类型后向上抛出。
class ExportFailure implements Exception {
  const ExportFailure({required this.kind, this.detail = ''});

  final ExportFailureKind kind;
  final String detail;

  @override
  String toString() => 'ExportFailure($kind${detail.isEmpty ? '' : ': $detail'})';
}
