import 'package:comic_book_maker/src/rust/api/export.dart';
import 'package:comic_book_maker/src/rust/export_error.dart';

export 'package:comic_book_maker/src/rust/api/export.dart'
    show ExportFailurePresentationFrb;

/// Core 统一的用户可见 Export 失败文案。
typedef ExportFailurePresentation = ExportFailurePresentationFrb;

ExportFailurePresentationFrb presentationForExportError(ExportError error) =>
    exportErrorPresentation(error: error);

ExportFailurePresentationFrb? presentationForCaughtExportFailure(Object error) {
  if (error is ExportError) {
    return presentationForExportError(error);
  }
  return null;
}
