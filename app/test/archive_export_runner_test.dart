import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/use_cases/export_workflow.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/data/repositories/in_memory_core_gateway.dart';

class _RecordingCoreGateway extends InMemoryCoreGateway {
  _RecordingCoreGateway() : super();

  bool? lastExportComicArchive;
  bool? lastExportPdf;
  bool? lastDeleteProjectAfterExport;
  ComicArchiveContainerFrb? lastComicArchiveContainer;

  @override
  Future<void> exportArchive({
    required String projectId,
    required String destinationPath,
    required bool exportComicArchive,
    ComicArchiveContainerFrb? comicArchiveContainer,
    required bool exportPdf,
    required bool deleteProjectAfterExport,
  }) async {
    lastExportComicArchive = exportComicArchive;
    lastExportPdf = exportPdf;
    lastDeleteProjectAfterExport = deleteProjectAfterExport;
    lastComicArchiveContainer = comicArchiveContainer;
  }
}

void main() {
  late _RecordingCoreGateway gateway;
  late ExportWorkflow workflow;

  setUp(() {
    gateway = _RecordingCoreGateway();
    workflow = ExportWorkflow(gateway: gateway);
  });

  test('routes ZIP comic archive to comic CBZ export', () async {
    await workflow.execute(
      projectId: 'p1',
      target: const ResolvedExportTarget(
        destinationPath: '/tmp/out.cbz',
        formatLabel: 'CBZ',
        exportComicArchive: true,
        comicArchiveContainer: ComicArchiveContainerFrb.zip,
        exportPdf: false,
      ),
      deleteProjectAfterExport: false,
    );

    expect(gateway.lastExportComicArchive, isTrue);
    expect(gateway.lastComicArchiveContainer, ComicArchiveContainerFrb.zip);
  });

  test('routes 7Z comic archive to comic CB7 export', () async {
    await workflow.execute(
      projectId: 'p1',
      target: const ResolvedExportTarget(
        destinationPath: '/tmp/out.cb7',
        formatLabel: 'CB7',
        exportComicArchive: true,
        comicArchiveContainer: ComicArchiveContainerFrb.sevenZip,
        exportPdf: false,
      ),
      deleteProjectAfterExport: false,
    );

    expect(gateway.lastExportComicArchive, isTrue);
    expect(
      gateway.lastComicArchiveContainer,
      ComicArchiveContainerFrb.sevenZip,
    );
  });

  test('routes RAR comic archive to comic CBR export', () async {
    await workflow.execute(
      projectId: 'p1',
      target: const ResolvedExportTarget(
        destinationPath: '/tmp/out.cbr',
        formatLabel: 'CBR',
        exportComicArchive: true,
        comicArchiveContainer: ComicArchiveContainerFrb.rar,
        exportPdf: false,
      ),
      deleteProjectAfterExport: false,
    );

    expect(gateway.lastExportComicArchive, isTrue);
    expect(gateway.lastComicArchiveContainer, ComicArchiveContainerFrb.rar);
  });

  test('routes EPUB to EPUB export', () async {
    await workflow.execute(
      projectId: 'p1',
      target: const ResolvedExportTarget(
        destinationPath: '/tmp/out.epub',
        formatLabel: 'EPUB',
        exportComicArchive: false,
        exportPdf: false,
      ),
      deleteProjectAfterExport: false,
    );

    expect(gateway.lastExportComicArchive, isFalse);
    expect(gateway.lastExportPdf, isFalse);
    expect(gateway.lastComicArchiveContainer, isNull);
  });

  test('routes PDF to PDF export', () async {
    await workflow.execute(
      projectId: 'p1',
      target: const ResolvedExportTarget(
        destinationPath: '/tmp/out.pdf',
        formatLabel: 'PDF',
        exportComicArchive: false,
        exportPdf: true,
      ),
      deleteProjectAfterExport: false,
    );

    expect(gateway.lastExportComicArchive, isFalse);
    expect(gateway.lastExportPdf, isTrue);
    expect(gateway.lastComicArchiveContainer, isNull);
  });

  test('passes deleteProjectAfterExport to gateway for pdf', () async {
    await workflow.execute(
      projectId: 'p1',
      target: const ResolvedExportTarget(
        destinationPath: '/tmp/out.pdf',
        formatLabel: 'PDF',
        exportComicArchive: false,
        exportPdf: true,
      ),
      deleteProjectAfterExport: true,
    );

    expect(gateway.lastDeleteProjectAfterExport, isTrue);
  });
}
