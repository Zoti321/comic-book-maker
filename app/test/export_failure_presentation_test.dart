import 'package:comic_book_maker/domain/use_cases/export_failure_presentation.dart';
import 'package:comic_book_maker/src/rust/export_error.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('presentationForExportError', () {
    test('maps NoPages to Chinese copy', () {
      const error = ExportError(
        kind: ExportErrorKind.noPages,
        detail: '',
      );

      final presentation = presentationForExportError(error);

      expect(presentation.title, '无法导出');
      expect(presentation.message, contains('至少一页'));
      expect(presentation.nextStepHint, isNotNull);
    });

    test('maps PageAssetMissing with detail hint', () {
      const error = ExportError(
        kind: ExportErrorKind.pageAssetMissing,
        detail: 'open page asset /tmp/001.png: not found',
      );

      final presentation = presentationForExportError(error);

      expect(presentation.title, '无法导出');
      expect(presentation.message, contains('找不到'));
      expect(presentation.nextStepHint, contains('001.png'));
    });

    test('maps DestinationNotWritable', () {
      const error = ExportError(
        kind: ExportErrorKind.destinationNotWritable,
        detail: 'create export directory D:\\out: access denied',
      );

      final presentation = presentationForExportError(error);

      expect(presentation.title, '无法导出');
      expect(presentation.message, contains('写入'));
      expect(presentation.nextStepHint, contains('access denied'));
    });

    test('presentationForExportFailure recognizes ExportError', () {
      const error = ExportError(
        kind: ExportErrorKind.projectNotFound,
        detail: 'project not found: p1',
      );

      final presentation = presentationForExportFailure(error);

      expect(presentation, isNotNull);
      expect(presentation!.message, contains('找不到'));
    });

    test('presentationForExportFailure returns null for unknown errors', () {
      expect(presentationForExportFailure(Exception('boom')), isNull);
    });
  });
}
