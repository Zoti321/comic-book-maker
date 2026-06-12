import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/domain/use_cases/page_import_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('allowedExtensionsFor', () {
    test('gallery add always page images', () {
      for (final kind in InferredImportKindFrb.values) {
        expect(
          allowedExtensionsFor(kind, ImportKindPickerIntent.galleryAddPage),
          kPageImageExtensions,
        );
      }
    });

    test('append import follows kind', () {
      expect(
        allowedExtensionsFor(
          InferredImportKindFrb.images,
          ImportKindPickerIntent.appendImport,
        ),
        kPageImageExtensions,
      );
      expect(
        allowedExtensionsFor(
          InferredImportKindFrb.comicArchive,
          ImportKindPickerIntent.appendImport,
        ),
        isNull,
      );
      expect(
        allowedExtensionsFor(
          InferredImportKindFrb.epub,
          ImportKindPickerIntent.appendImport,
        ),
        const ['epub'],
      );
      expect(
        allowedExtensionsFor(
          InferredImportKindFrb.pdf,
          ImportKindPickerIntent.appendImport,
        ),
        isNull,
      );
    });

    test('replace always page images regardless of import kind', () {
      for (final kind in InferredImportKindFrb.values) {
        expect(
          allowedExtensionsFor(kind, ImportKindPickerIntent.replacePage),
          kPageImageExtensions,
        );
      }
    });
  });

  group('appendImportBlockedReason', () {
    test('pdf has message', () {
      expect(
        appendImportBlockedReason(InferredImportKindFrb.pdf),
        contains('尚未实现'),
      );
    });
  });

  group('canExportProject', () {
    const pdfSettings = ProjectSettings(
      exportFormat: ExportFormatFrb.pdf,
      inferredImportKind: InferredImportKindFrb.pdf,
      deleteProjectAfterExport: false,
      useDefaultExportDirectory: true,
      exportDirectory: null,
      comicArchiveContainer: ComicArchiveContainerFrb.zip,
      useComicArchiveExtension: true,
    );

    test('allows pdf export when pages exist', () {
      expect(
        canExportProject(
          settings: pdfSettings,
          pageCount: 2,
          operationInProgress: false,
        ),
        isTrue,
      );
    });

    test('blocks export without pages regardless of format', () {
      expect(
        canExportProject(
          settings: pdfSettings,
          pageCount: 0,
          operationInProgress: false,
        ),
        isFalse,
      );
    });
  });
}
