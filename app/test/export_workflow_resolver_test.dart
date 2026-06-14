import 'dart:io';

import 'package:comic_book_maker/src/rust/api/export.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'support/frb/rust_integration.dart';

const _baseSettings = ProjectSettings(
  exportFormat: ExportFormatFrb.comicArchive,
  inferredImportKind: InferredImportKindFrb.images,
  deleteProjectAfterExport: false,
  useDefaultExportDirectory: true,
  exportDirectory: null,
  comicArchiveContainer: ComicArchiveContainerFrb.zip,
  useComicArchiveExtension: true,
);

ExportPlanResultFrb _plan({
  required ProjectSettings settings,
  required String? globalExportDirectory,
  String projectTitle = 'My Comic',
  bool hasPages = true,
}) {
  return planExport(
    request: ExportPlanRequestFrb(
      projectTitle: projectTitle,
      settings: settings,
      globalExportDirectory: globalExportDirectory,
      hasPages: hasPages,
    ),
  );
}

void main() {
  exportRustTestSetUpAll();

  late Directory tempRoot;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('cbm-export-resolver-');
  });

  tearDown(() {
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  });

  group('planExport target resolution', () {
    test('uses global directory when useDefaultExportDirectory is true', () {
      final exportDir = Directory(p.join(tempRoot.path, 'exports'));
      exportDir.createSync();

      final result = _plan(
        settings: _baseSettings,
        globalExportDirectory: exportDir.path,
      );

      expect(result, isA<ExportPlanResultFrb_Ready>());
      final ready = (result as ExportPlanResultFrb_Ready).field0;
      expect(
        ready.target.destinationPath,
        p.join(exportDir.path, 'My Comic.cbz'),
      );
      expect(ready.target.exportComicArchive, isTrue);
      expect(ready.target.formatLabel, 'CBZ');
    });

    test('uses project directory when not using global default', () {
      final projectDir = Directory(p.join(tempRoot.path, 'project-out'));
      projectDir.createSync();

      final result = _plan(
        settings: ProjectSettings(
          exportFormat: ExportFormatFrb.comicArchive,
          inferredImportKind: InferredImportKindFrb.images,
          deleteProjectAfterExport: false,
          useDefaultExportDirectory: false,
          exportDirectory: projectDir.path,
          comicArchiveContainer: ComicArchiveContainerFrb.zip,
          useComicArchiveExtension: false,
        ),
        globalExportDirectory: p.join(tempRoot.path, 'ignored'),
        projectTitle: 'Issue 1',
      );

      final ready = (result as ExportPlanResultFrb_Ready).field0;
      expect(
        ready.target.destinationPath,
        p.join(projectDir.path, 'Issue 1.zip'),
      );
      expect(ready.target.formatLabel, 'ZIP');
    });

    test('pdf export resolves pdf path and label', () {
      final exportDir = Directory(p.join(tempRoot.path, 'exports'));
      exportDir.createSync();

      final result = _plan(
        settings: const ProjectSettings(
          exportFormat: ExportFormatFrb.pdf,
          inferredImportKind: InferredImportKindFrb.images,
          deleteProjectAfterExport: false,
          useDefaultExportDirectory: true,
          exportDirectory: null,
          comicArchiveContainer: ComicArchiveContainerFrb.zip,
          useComicArchiveExtension: true,
        ),
        globalExportDirectory: exportDir.path,
        projectTitle: 'Comic',
      );

      final ready = (result as ExportPlanResultFrb_Ready).field0;
      expect(ready.target.destinationPath, p.join(exportDir.path, 'Comic.pdf'));
      expect(ready.target.exportComicArchive, isFalse);
      expect(ready.target.exportPdf, isTrue);
      expect(ready.target.formatLabel, 'PDF');
    });

    test('epub export ignores comic archive extension settings', () {
      final exportDir = Directory(p.join(tempRoot.path, 'exports'));
      exportDir.createSync();

      final result = _plan(
        settings: const ProjectSettings(
          exportFormat: ExportFormatFrb.epub,
          inferredImportKind: InferredImportKindFrb.epub,
          deleteProjectAfterExport: false,
          useDefaultExportDirectory: true,
          exportDirectory: null,
          comicArchiveContainer: ComicArchiveContainerFrb.rar,
          useComicArchiveExtension: true,
        ),
        globalExportDirectory: exportDir.path,
        projectTitle: 'Book',
      );

      final ready = (result as ExportPlanResultFrb_Ready).field0;
      expect(ready.target.destinationPath, p.join(exportDir.path, 'Book.epub'));
      expect(ready.target.exportComicArchive, isFalse);
    });
  });

  group('planExport blocks', () {
    test('blocks when global directory missing but required', () {
      final result = _plan(
        settings: _baseSettings,
        globalExportDirectory: null,
        projectTitle: 'x',
      );

      expect(result, isA<ExportPlanResultFrb_Blocked>());
      final blocked = result as ExportPlanResultFrb_Blocked;
      expect(
        blocked.reason,
        ExportPlanBlockReasonFrb.exportDirectoryMissing,
      );
    });

    test('blocks pdf export when global directory missing', () {
      final result = _plan(
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
        projectTitle: 'Comic',
      );

      final blocked = result as ExportPlanResultFrb_Blocked;
      expect(
        blocked.reason,
        ExportPlanBlockReasonFrb.exportDirectoryMissing,
      );
      expect(blocked.presentation.message, contains('默认导出目录'));
    });

    test('blocks pdf export when project directory missing', () {
      final result = _plan(
        settings: const ProjectSettings(
          exportFormat: ExportFormatFrb.pdf,
          inferredImportKind: InferredImportKindFrb.images,
          deleteProjectAfterExport: false,
          useDefaultExportDirectory: false,
          exportDirectory: null,
          comicArchiveContainer: ComicArchiveContainerFrb.zip,
          useComicArchiveExtension: true,
        ),
        globalExportDirectory: tempRoot.path,
        projectTitle: 'Comic',
      );

      final blocked = result as ExportPlanResultFrb_Blocked;
      expect(
        blocked.reason,
        ExportPlanBlockReasonFrb.exportDirectoryMissing,
      );
      expect(blocked.presentation.message, contains('专用导出目录'));
    });

    test('comicArchiveFileExtension follows extension strategy', () {
      expect(
        comicArchiveFileExtension(
          settings: const ProjectSettings(
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
          settings: const ProjectSettings(
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
          settings: const ProjectSettings(
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
          settings: const ProjectSettings(
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
      final exportDir = Directory(p.join(tempRoot.path, 'exports'));
      exportDir.createSync();

      final result = _plan(
        settings: const ProjectSettings(
          exportFormat: ExportFormatFrb.comicArchive,
          inferredImportKind: InferredImportKindFrb.comicArchive,
          deleteProjectAfterExport: false,
          useDefaultExportDirectory: true,
          exportDirectory: null,
          comicArchiveContainer: ComicArchiveContainerFrb.rar,
          useComicArchiveExtension: true,
        ),
        globalExportDirectory: exportDir.path,
        projectTitle: 'RAR Comic',
      );

      final ready = (result as ExportPlanResultFrb_Ready).field0;
      expect(
        ready.target.destinationPath,
        p.join(exportDir.path, 'RAR Comic.cbr'),
      );
      expect(ready.target.formatLabel, 'CBR');
      expect(ready.target.comicArchiveContainer, ComicArchiveContainerFrb.rar);
    });

    test('resolves RAR without comic extension to rar path', () {
      final exportDir = Directory(p.join(tempRoot.path, 'exports'));
      exportDir.createSync();

      final result = _plan(
        settings: const ProjectSettings(
          exportFormat: ExportFormatFrb.comicArchive,
          inferredImportKind: InferredImportKindFrb.comicArchive,
          deleteProjectAfterExport: false,
          useDefaultExportDirectory: true,
          exportDirectory: null,
          comicArchiveContainer: ComicArchiveContainerFrb.rar,
          useComicArchiveExtension: false,
        ),
        globalExportDirectory: exportDir.path,
        projectTitle: 'Archive',
      );

      final ready = (result as ExportPlanResultFrb_Ready).field0;
      expect(ready.target.destinationPath, p.join(exportDir.path, 'Archive.rar'));
      expect(ready.target.formatLabel, 'RAR');
    });

    test('resolves 7Z comic archive to cb7 path', () {
      final exportDir = Directory(p.join(tempRoot.path, 'exports'));
      exportDir.createSync();

      final result = _plan(
        settings: const ProjectSettings(
          exportFormat: ExportFormatFrb.comicArchive,
          inferredImportKind: InferredImportKindFrb.comicArchive,
          deleteProjectAfterExport: false,
          useDefaultExportDirectory: true,
          exportDirectory: null,
          comicArchiveContainer: ComicArchiveContainerFrb.sevenZip,
          useComicArchiveExtension: true,
        ),
        globalExportDirectory: exportDir.path,
        projectTitle: '7Z Comic',
      );

      final ready = (result as ExportPlanResultFrb_Ready).field0;
      expect(
        ready.target.destinationPath,
        p.join(exportDir.path, '7Z Comic.cb7'),
      );
      expect(ready.target.formatLabel, 'CB7');
      expect(
        ready.target.comicArchiveContainer,
        ComicArchiveContainerFrb.sevenZip,
      );
    });

    test('resolves 7Z without comic extension to 7z path', () {
      final exportDir = Directory(p.join(tempRoot.path, 'exports'));
      exportDir.createSync();

      final result = _plan(
        settings: const ProjectSettings(
          exportFormat: ExportFormatFrb.comicArchive,
          inferredImportKind: InferredImportKindFrb.comicArchive,
          deleteProjectAfterExport: false,
          useDefaultExportDirectory: true,
          exportDirectory: null,
          comicArchiveContainer: ComicArchiveContainerFrb.sevenZip,
          useComicArchiveExtension: false,
        ),
        globalExportDirectory: exportDir.path,
        projectTitle: 'Archive',
      );

      final ready = (result as ExportPlanResultFrb_Ready).field0;
      expect(ready.target.destinationPath, p.join(exportDir.path, 'Archive.7z'));
      expect(ready.target.formatLabel, '7Z');
    });
  });
}
