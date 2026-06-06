import 'package:comic_book_maker/domain/models/export_failure.dart';
import 'package:comic_book_maker/src/rust/export_error.dart' as frb;

ExportFailure mapExportError(frb.ExportError error) {
  return ExportFailure(
    kind: switch (error.kind) {
      frb.ExportErrorKind.destinationExists =>
        ExportFailureKind.destinationExists,
      frb.ExportErrorKind.destinationIsDirectory =>
        ExportFailureKind.destinationIsDirectory,
      frb.ExportErrorKind.destinationNotWritable =>
        ExportFailureKind.destinationNotWritable,
      frb.ExportErrorKind.destinationLocked =>
        ExportFailureKind.destinationLocked,
      frb.ExportErrorKind.destinationFinalizeFailed =>
        ExportFailureKind.destinationFinalizeFailed,
      frb.ExportErrorKind.pageAssetMissing =>
        ExportFailureKind.pageAssetMissing,
      frb.ExportErrorKind.pageAssetUnreadable =>
        ExportFailureKind.pageAssetUnreadable,
      frb.ExportErrorKind.insufficientSpace =>
        ExportFailureKind.insufficientSpace,
      frb.ExportErrorKind.archiveWriteFailed =>
        ExportFailureKind.archiveWriteFailed,
      frb.ExportErrorKind.noPages => ExportFailureKind.noPages,
      frb.ExportErrorKind.projectNotFound =>
        ExportFailureKind.projectNotFound,
      frb.ExportErrorKind.deleteAfterExportFailed =>
        ExportFailureKind.deleteAfterExportFailed,
    },
    detail: error.detail,
  );
}
