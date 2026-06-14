import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/models/create_project_command.dart';
import 'package:comic_book_maker/domain/models/create_project_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateProjectDraft validation', () {
    test('cannot create without import source', () {
      final draft = CreateProjectDraft();

      expect(draft.canCreate, isFalse);
      expect(draft.createDisabledReason, contains('导入'));
      expect(() => draft.toCommand(), throwsA(isA<CreateProjectValidationException>()));
    });

    test('requires dedicated export directory when not using global default', () {
      final draft = CreateProjectDraft(
        importSource: const CreateProjectImageImport([r'C:\a.png']),
        useDefaultExportDirectory: false,
      );

      expect(draft.canCreate, isFalse);
      expect(draft.createDisabledReason, contains('专用导出目录'));
    });

    test('image import infers images kind and comic archive export', () {
      final draft = CreateProjectDraft()
        ..applyImportSource(const CreateProjectImageImport([r'C:\a.png']));

      expect(draft.inferredImportKind, InferredImportKindFrb.images);
      expect(draft.exportFormat, ExportFormatFrb.comicArchive);
      expect(draft.canCreate, isTrue);
    });

    test('epub import switches export format to epub', () {
      final draft = CreateProjectDraft()
        ..applyImportSource(
          const CreateProjectArchiveImport(
            format: ArchiveFormatFrb.epub,
            sourcePath: r'C:\book.epub',
          ),
        );

      expect(draft.inferredImportKind, InferredImportKindFrb.epub);
      expect(draft.exportFormat, ExportFormatFrb.epub);
    });

    test('toCommand carries optional title and settings', () {
      final draft = CreateProjectDraft(
        projectTitle: '  我的漫画  ',
      )..applyImportSource(
          const CreateProjectArchiveImport(
            format: ArchiveFormatFrb.cbz,
            sourcePath: r'C:\comic.cbz',
          ),
        );

      final command = draft.toCommand();

      expect(command.title, '我的漫画');
      expect(command.importSource, isA<CreateProjectArchiveImport>());
      expect(command.settingsUpdate.exportFormat, ExportFormatFrb.comicArchive);
    });
  });
}
