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
}
