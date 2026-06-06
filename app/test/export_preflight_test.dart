import 'dart:io';

import 'package:comic_book_maker/domain/use_cases/export_workflow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  group('checkExportPreflight', () {
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

      final result = checkExportPreflight(exportDir.path);

      expect(result.isBlocked, isTrue);
      expect(result.presentation?.message, contains('文件夹'));
    });

    test('requires overwrite confirmation when destination file exists', () {
      final exportDir = Directory(p.join(tempRoot.path, 'exports'));
      exportDir.createSync();
      final destination = File(p.join(exportDir.path, 'comic.cbz'));
      destination.writeAsStringSync('existing');

      final result = checkExportPreflight(destination.path);

      expect(result.needsOverwriteConfirmation, isTrue);
      expect(result.isBlocked, isFalse);
    });

    test('blocks when parent directory does not exist', () {
      final destination = p.join(tempRoot.path, 'missing', 'comic.cbz');

      final result = checkExportPreflight(destination);

      expect(result.isBlocked, isTrue);
      expect(result.presentation?.message, contains('写入'));
    });

    test('is ready for new file in writable directory', () {
      final exportDir = Directory(p.join(tempRoot.path, 'exports'));
      exportDir.createSync();
      final destination = p.join(exportDir.path, 'new-comic.cbz');

      final result = checkExportPreflight(destination);

      expect(result.status, ExportPreflightStatus.ready);
    });
  });

  group('runExportConfirmations', () {
    test('asks overwrite before delete when both are needed', () async {
      final order = <String>[];

      final confirmed = await runExportConfirmations(
        preflight: const ExportPreflightResult.needsOverwriteConfirmation(),
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
        preflight: const ExportPreflightResult.needsOverwriteConfirmation(),
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
        preflight: const ExportPreflightResult.ready(),
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
