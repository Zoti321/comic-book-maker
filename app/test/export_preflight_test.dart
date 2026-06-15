import 'dart:io';

import 'package:comic_book_maker/domain/use_cases/export_workflow.dart';
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

ExportPlanResultFrb _planTo({
  required String destinationParent,
  required String projectTitle,
  ProjectSettings settings = _baseSettings,
}) {
  return planExport(
    request: ExportPlanRequestFrb(
      projectTitle: projectTitle,
      settings: settings,
      globalExportDirectory: destinationParent,
      hasPages: true,
    ),
  );
}

void main() {
  exportRustTestSetUpAll();

  group('planExport preflight', () {
    late Directory tempRoot;

    setUp(() {
      tempRoot = Directory.systemTemp.createTempSync('cbm-export-preflight-');
    });

    tearDown(() {
      if (tempRoot.existsSync()) {
        tempRoot.deleteSync(recursive: true);
      }
    });

    test('blocks when destination is a directory', () {
      final exportDir = Directory(p.join(tempRoot.path, 'exports'));
      exportDir.createSync();
      Directory(p.join(exportDir.path, 'comic.cbz')).createSync();

      final result = _planTo(
        destinationParent: exportDir.path,
        projectTitle: 'comic',
      );

      expect(result, isA<ExportPlanResultFrb_Blocked>());
      final blocked = result as ExportPlanResultFrb_Blocked;
      expect(blocked.presentation.message, contains('文件夹'));
    });

    test('requires overwrite confirmation when destination file exists', () {
      final exportDir = Directory(p.join(tempRoot.path, 'exports'));
      exportDir.createSync();
      final destination = File(p.join(exportDir.path, 'comic.cbz'));
      destination.writeAsStringSync('existing');

      final result = _planTo(
        destinationParent: exportDir.path,
        projectTitle: 'comic',
      );

      expect(result, isA<ExportPlanResultFrb_Ready>());
      final ready = (result as ExportPlanResultFrb_Ready).field0;
      expect(ready.needsOverwriteConfirmation, isTrue);
      expect(ready.target.destinationPath, destination.path);
    });

    test('blocks when parent directory does not exist', () {
      final missingParent = p.join(tempRoot.path, 'missing');
      final result = _planTo(
        destinationParent: missingParent,
        projectTitle: 'comic',
      );

      expect(result, isA<ExportPlanResultFrb_Blocked>());
      final blocked = result as ExportPlanResultFrb_Blocked;
      expect(blocked.presentation.message, contains('写入'));
    });

    test('is ready for new file in writable directory', () {
      final exportDir = Directory(p.join(tempRoot.path, 'exports'));
      exportDir.createSync();

      final result = _planTo(
        destinationParent: exportDir.path,
        projectTitle: 'new-comic',
      );

      expect(result, isA<ExportPlanResultFrb_Ready>());
      final ready = (result as ExportPlanResultFrb_Ready).field0;
      expect(ready.needsOverwriteConfirmation, isFalse);
    });

    test('treats pdf destination like other archive formats', () {
      final exportDir = Directory(p.join(tempRoot.path, 'exports'));
      exportDir.createSync();
      File(p.join(exportDir.path, 'comic.pdf')).writeAsStringSync('existing');

      final result = planExport(
        request: ExportPlanRequestFrb(
          projectTitle: 'comic',
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
          hasPages: true,
        ),
      );

      expect(result, isA<ExportPlanResultFrb_Ready>());
      final ready = (result as ExportPlanResultFrb_Ready).field0;
      expect(ready.needsOverwriteConfirmation, isTrue);
    });
  });

  group('runExportConfirmations', () {
    test('asks overwrite before delete when both are needed', () async {
      final order = <String>[];

      final confirmed = await runExportConfirmations(
        needsOverwriteConfirmation: true,
        deleteAfterExport: true,
        confirmOverwrite: () async {
          order.add('overwrite');
          return true;
        },
        confirmDeleteProject: () async {
          order.add('delete');
          return true;
        },
      );

      expect(confirmed, isTrue);
      expect(order, ['overwrite', 'delete']);
    });

    test('returns false when overwrite is cancelled', () async {
      var deleteCalled = false;

      final confirmed = await runExportConfirmations(
        needsOverwriteConfirmation: true,
        deleteAfterExport: true,
        confirmOverwrite: () async => false,
        confirmDeleteProject: () async {
          deleteCalled = true;
          return true;
        },
      );

      expect(confirmed, isFalse);
      expect(deleteCalled, isFalse);
    });

    test('skips overwrite confirmation when file does not exist', () async {
      var overwriteCalled = false;

      final confirmed = await runExportConfirmations(
        needsOverwriteConfirmation: false,
        deleteAfterExport: false,
        confirmOverwrite: () async {
          overwriteCalled = true;
          return true;
        },
        confirmDeleteProject: () async => true,
      );

      expect(confirmed, isTrue);
      expect(overwriteCalled, isFalse);
    });
  });
}
