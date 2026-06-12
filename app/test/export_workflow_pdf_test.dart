import 'dart:io';

import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/domain/use_cases/export_workflow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import 'support/data/repositories/in_memory_core_gateway.dart';

const _pdfSettings = ProjectSettings(
  exportFormat: ExportFormatFrb.pdf,
  inferredImportKind: InferredImportKindFrb.images,
  deleteProjectAfterExport: true,
  useDefaultExportDirectory: true,
  exportDirectory: null,
  comicArchiveContainer: ComicArchiveContainerFrb.zip,
  useComicArchiveExtension: true,
);

void main() {
  late Directory tempRoot;
  late ExportWorkflow workflow;

  setUp(() {
    tempRoot = Directory.systemTemp.createTempSync('cbm-export-pdf-plan-');
    workflow = ExportWorkflow(gateway: InMemoryCoreGateway());
  });

  tearDown(() {
    if (tempRoot.existsSync()) {
      tempRoot.deleteSync(recursive: true);
    }
  });

  group('ExportWorkflow.plan for PDF', () {
    test('blocks when project has no pages', () {
      final plan = workflow.plan(
        const ExportWorkflowRequest(
          projectTitle: 'Empty',
          settings: _pdfSettings,
          globalExportDirectory: '/tmp',
          hasPages: false,
        ),
      );

      expect(plan, isA<ExportWorkflowBlocked>());
      final blocked = plan as ExportWorkflowBlocked;
      expect(blocked.presentation.message, contains('至少一页'));
    });

    test('is ready with pdf target and delete-after-export flag', () {
      final exportDir = Directory(p.join(tempRoot.path, 'exports'));
      exportDir.createSync();

      final plan = workflow.plan(
        ExportWorkflowRequest(
          projectTitle: 'My Comic',
          settings: _pdfSettings,
          globalExportDirectory: exportDir.path,
          hasPages: true,
        ),
      );

      expect(plan, isA<ExportWorkflowReady>());
      final ready = plan as ExportWorkflowReady;
      expect(ready.target.exportPdf, isTrue);
      expect(ready.target.exportComicArchive, isFalse);
      expect(ready.target.formatLabel, 'PDF');
      expect(
        ready.target.destinationPath,
        p.join(exportDir.path, 'My Comic.pdf'),
      );
      expect(ready.deleteAfterExport, isTrue);
      expect(ready.needsOverwriteConfirmation, isFalse);
    });

    test('requires overwrite confirmation when pdf destination exists', () {
      final exportDir = Directory(p.join(tempRoot.path, 'exports'));
      exportDir.createSync();
      File(p.join(exportDir.path, 'Existing.pdf')).writeAsStringSync('old');

      final plan = workflow.plan(
        ExportWorkflowRequest(
          projectTitle: 'Existing',
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

      expect(plan, isA<ExportWorkflowReady>());
      expect((plan as ExportWorkflowReady).needsOverwriteConfirmation, isTrue);
    });
  });
}
