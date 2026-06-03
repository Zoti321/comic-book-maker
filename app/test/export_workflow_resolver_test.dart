import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/ui/export_workflow_resolver.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

const _baseSettings = ProjectSettings(
  exportFormat: ExportFormatFrb.comicArchive,
  inferredImportKind: InferredImportKindFrb.images,
  deleteProjectAfterExport: false,
  useDefaultExportDirectory: true,
  exportDirectory: null,
  comicArchiveContainer: ComicArchiveContainerFrb.zip,
  useComicArchiveExtension: true,
);

void main() {
  group('resolveExportTarget', () {
    test('uses global directory when useDefaultExportDirectory is true', () {
      final target = resolveExportTarget(
        settings: _baseSettings,
        globalExportDirectory: r'D:\exports',
        safeTitle: 'My Comic',
      );

      expect(target, isNotNull);
      expect(
        target!.destinationPath,
        r'D:\exports\My Comic.cbz',
      );
      expect(target.exportComicArchive, isTrue);
      expect(target.formatLabel, 'CBZ');
    });

    test('uses project directory when not using global default', () {
      final target = resolveExportTarget(
        settings: const ProjectSettings(
          exportFormat: ExportFormatFrb.comicArchive,
          inferredImportKind: InferredImportKindFrb.images,
          deleteProjectAfterExport: false,
          useDefaultExportDirectory: false,
          exportDirectory: r'E:\project-out',
          comicArchiveContainer: ComicArchiveContainerFrb.zip,
          useComicArchiveExtension: false,
        ),
        globalExportDirectory: r'D:\exports',
        safeTitle: 'Issue 1',
      );

      expect(target!.destinationPath, r'E:\project-out\Issue 1.zip');
      expect(target.formatLabel, 'ZIP');
    });

    test('epub export ignores comic archive extension settings', () {
      final target = resolveExportTarget(
        settings: const ProjectSettings(
          exportFormat: ExportFormatFrb.epub,
          inferredImportKind: InferredImportKindFrb.epub,
          deleteProjectAfterExport: false,
          useDefaultExportDirectory: true,
          exportDirectory: null,
          comicArchiveContainer: ComicArchiveContainerFrb.rar,
          useComicArchiveExtension: true,
        ),
        globalExportDirectory: '/tmp',
        safeTitle: 'Book',
      );

      expect(target!.destinationPath, p.join('/tmp', 'Book.epub'));
      expect(target.exportComicArchive, isFalse);
    });
  });

  group('resolveExportBlock', () {
    test('blocks when global directory missing but required', () {
      final block = resolveExportBlock(
        settings: _baseSettings,
        globalExportDirectory: null,
        safeTitle: 'x',
      );

      expect(block?.reason, ExportWorkflowBlockReason.exportDirectoryMissing);
    });

    test('comicArchiveFileExtension follows extension strategy', () {
      expect(
        comicArchiveFileExtension(
          const ProjectSettings(
            exportFormat: ExportFormatFrb.comicArchive,
            inferredImportKind: InferredImportKindFrb.images,
            deleteProjectAfterExport: false,
            useDefaultExportDirectory: true,
            exportDirectory: null,
            comicArchiveContainer: ComicArchiveContainerFrb.zip,
            useComicArchiveExtension: false,
          ),
        ),
        'zip',
      );
      expect(
        comicArchiveFileExtension(
          const ProjectSettings(
            exportFormat: ExportFormatFrb.comicArchive,
            inferredImportKind: InferredImportKindFrb.images,
            deleteProjectAfterExport: false,
            useDefaultExportDirectory: true,
            exportDirectory: null,
            comicArchiveContainer: ComicArchiveContainerFrb.rar,
            useComicArchiveExtension: true,
          ),
        ),
        'cbr',
      );
    });

    test('blocks unimplemented archive container', () {
      final block = resolveExportBlock(
        settings: const ProjectSettings(
          exportFormat: ExportFormatFrb.comicArchive,
          inferredImportKind: InferredImportKindFrb.comicArchive,
          deleteProjectAfterExport: false,
          useDefaultExportDirectory: true,
          exportDirectory: null,
          comicArchiveContainer: ComicArchiveContainerFrb.rar,
          useComicArchiveExtension: true,
        ),
        globalExportDirectory: '/tmp',
        safeTitle: 'x',
      );

      expect(
        block?.reason,
        ExportWorkflowBlockReason.archiveContainerNotImplemented,
      );
    });
  });
}
