import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/domain/use_cases/export_workflow.dart';
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

    test('pdf export resolves pdf path and label', () {
      final target = resolveExportTarget(
        settings: const ProjectSettings(
          exportFormat: ExportFormatFrb.pdf,
          inferredImportKind: InferredImportKindFrb.images,
          deleteProjectAfterExport: false,
          useDefaultExportDirectory: true,
          exportDirectory: null,
          comicArchiveContainer: ComicArchiveContainerFrb.zip,
          useComicArchiveExtension: true,
        ),
        globalExportDirectory: '/tmp',
        safeTitle: 'Comic',
      );

      expect(target!.destinationPath, p.join('/tmp', 'Comic.pdf'));
      expect(target.exportComicArchive, isFalse);
      expect(target.exportPdf, isTrue);
      expect(target.formatLabel, 'PDF');
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

    test('blocks pdf export when global directory missing', () {
      final block = resolveExportBlock(
        settings: const ProjectSettings(
          exportFormat: ExportFormatFrb.pdf,
          inferredImportKind: InferredImportKindFrb.images,
          deleteProjectAfterExport: false,
          useDefaultExportDirectory: true,
          exportDirectory: null,
          comicArchiveContainer: ComicArchiveContainerFrb.zip,
          useComicArchiveExtension: true,
        ),
        globalExportDirectory: null,
        safeTitle: 'Comic',
      );

      expect(block?.reason, ExportWorkflowBlockReason.exportDirectoryMissing);
      expect(block?.message, contains('默认导出目录'));
    });

    test('blocks pdf export when project directory missing', () {
      final block = resolveExportBlock(
        settings: const ProjectSettings(
          exportFormat: ExportFormatFrb.pdf,
          inferredImportKind: InferredImportKindFrb.images,
          deleteProjectAfterExport: false,
          useDefaultExportDirectory: false,
          exportDirectory: null,
          comicArchiveContainer: ComicArchiveContainerFrb.zip,
          useComicArchiveExtension: true,
        ),
        globalExportDirectory: '/tmp',
        safeTitle: 'Comic',
      );

      expect(block?.reason, ExportWorkflowBlockReason.exportDirectoryMissing);
      expect(block?.message, contains('专用导出目录'));
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
      expect(
        comicArchiveFileExtension(
          const ProjectSettings(
            exportFormat: ExportFormatFrb.comicArchive,
            inferredImportKind: InferredImportKindFrb.images,
            deleteProjectAfterExport: false,
            useDefaultExportDirectory: true,
            exportDirectory: null,
            comicArchiveContainer: ComicArchiveContainerFrb.sevenZip,
            useComicArchiveExtension: true,
          ),
        ),
        'cb7',
      );
      expect(
        comicArchiveFileExtension(
          const ProjectSettings(
            exportFormat: ExportFormatFrb.comicArchive,
            inferredImportKind: InferredImportKindFrb.images,
            deleteProjectAfterExport: false,
            useDefaultExportDirectory: true,
            exportDirectory: null,
            comicArchiveContainer: ComicArchiveContainerFrb.sevenZip,
            useComicArchiveExtension: false,
          ),
        ),
        '7z',
      );
    });

    test('resolves RAR comic archive to cbr path', () {
      final target = resolveExportTarget(
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
        safeTitle: 'RAR Comic',
      );

      expect(target, isNotNull);
      expect(target!.destinationPath, p.join('/tmp', 'RAR Comic.cbr'));
      expect(target.formatLabel, 'CBR');
      expect(target.comicArchiveContainer, ComicArchiveContainerFrb.rar);
    });

    test('resolves RAR without comic extension to rar path', () {
      final target = resolveExportTarget(
        settings: const ProjectSettings(
          exportFormat: ExportFormatFrb.comicArchive,
          inferredImportKind: InferredImportKindFrb.comicArchive,
          deleteProjectAfterExport: false,
          useDefaultExportDirectory: true,
          exportDirectory: null,
          comicArchiveContainer: ComicArchiveContainerFrb.rar,
          useComicArchiveExtension: false,
        ),
        globalExportDirectory: '/tmp',
        safeTitle: 'Archive',
      );

      expect(target!.destinationPath, p.join('/tmp', 'Archive.rar'));
      expect(target.formatLabel, 'RAR');
    });

    test('resolves 7Z comic archive to cb7 path', () {
      final target = resolveExportTarget(
        settings: const ProjectSettings(
          exportFormat: ExportFormatFrb.comicArchive,
          inferredImportKind: InferredImportKindFrb.comicArchive,
          deleteProjectAfterExport: false,
          useDefaultExportDirectory: true,
          exportDirectory: null,
          comicArchiveContainer: ComicArchiveContainerFrb.sevenZip,
          useComicArchiveExtension: true,
        ),
        globalExportDirectory: '/tmp',
        safeTitle: '7Z Comic',
      );

      expect(target, isNotNull);
      expect(target!.destinationPath, p.join('/tmp', '7Z Comic.cb7'));
      expect(target.formatLabel, 'CB7');
      expect(target.comicArchiveContainer, ComicArchiveContainerFrb.sevenZip);
    });

    test('resolves 7Z without comic extension to 7z path', () {
      final target = resolveExportTarget(
        settings: const ProjectSettings(
          exportFormat: ExportFormatFrb.comicArchive,
          inferredImportKind: InferredImportKindFrb.comicArchive,
          deleteProjectAfterExport: false,
          useDefaultExportDirectory: true,
          exportDirectory: null,
          comicArchiveContainer: ComicArchiveContainerFrb.sevenZip,
          useComicArchiveExtension: false,
        ),
        globalExportDirectory: '/tmp',
        safeTitle: 'Archive',
      );

      expect(target!.destinationPath, p.join('/tmp', 'Archive.7z'));
      expect(target.formatLabel, '7Z');
    });
  });
}
