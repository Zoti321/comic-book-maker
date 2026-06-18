import 'package:comic_book_maker/src/rust/api/metadata.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/frb/rust_integration.dart';

void main() {
  rustIntegrationTestSetUpAll();

  group('Metadata FRB integration', () {
    test('getMetadataEditorSchema decodes field hints', () {
      final schema = getMetadataEditorSchema(
        exportFormat: ExportFormatFrb.comicArchive,
      );

      expect(schema.editorTitle, '元数据');
      expect(schema.sections, hasLength(3));

      final general = schema.sections.firstWhere((s) => s.id == 'general');
      final language = general.fields.firstWhere((f) => f.id == 'language_iso');
      expect(language.hint, '如 zh-CN');

      final series = schema.sections.firstWhere((s) => s.id == 'series');
      final number = series.fields.firstWhere((f) => f.id == 'number');
      expect(number.hint, '如 1A');
    });
  });
}
