import 'package:comic_book_maker/domain/models/export_failure.dart';
import 'package:comic_book_maker/domain/use_cases/export_failure_presentation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('presentationForExportFailure', () {
    test('maps NoPages to Chinese copy', () {
      const error = ExportFailure(kind: ExportFailureKind.noPages);

      final presentation = presentationForExportFailure(error);

      expect(presentation.title, '无法导出');
      expect(presentation.message, contains('至少一页'));
      expect(presentation.nextStepHint, isNotNull);
    });

    test('maps PageAssetMissing with detail hint', () {
      const error = ExportFailure(
        kind: ExportFailureKind.pageAssetMissing,
        detail: 'open page asset /tmp/001.png: not found',
      );

      final presentation = presentationForExportFailure(error);

      expect(presentation.title, '无法导出');
      expect(presentation.message, contains('找不到'));
      expect(presentation.nextStepHint, contains('001.png'));
    });

    test('maps DestinationNotWritable', () {
      const error = ExportFailure(
        kind: ExportFailureKind.destinationNotWritable,
        detail: 'create export directory D:\\out: access denied',
      );

      final presentation = presentationForExportFailure(error);

      expect(presentation.title, '无法导出');
      expect(presentation.message, contains('写入'));
      expect(presentation.nextStepHint, contains('access denied'));
    });

    test('presentationForCaughtExportFailure recognizes ExportFailure', () {
      const error = ExportFailure(
        kind: ExportFailureKind.projectNotFound,
        detail: 'project not found: p1',
      );

      final presentation = presentationForCaughtExportFailure(error);

      expect(presentation, isNotNull);
      expect(presentation!.message, contains('找不到'));
    });

    test('presentationForCaughtExportFailure returns null for unknown errors', () {
      expect(presentationForCaughtExportFailure(Exception('boom')), isNull);
    });

    test('maps ArchiveWriteFailed with unsupported pdf page format detail', () {
      const error = ExportFailure(
        kind: ExportFailureKind.archiveWriteFailed,
        detail: 'PDF 导出不支持 .webp 页图（pages/002.webp）。请将页面替换为 JPEG 或 PNG 后重试。',
      );

      final presentation = presentationForExportFailure(error);

      expect(presentation.title, '导出失败');
      expect(presentation.message, contains('生成档案'));
      expect(presentation.nextStepHint, contains('JPEG 或 PNG'));
    });
  });
}
