import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/use_cases/export_workflow.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/data/repositories/in_memory_core_gateway.dart';

class _RecordingCoreGateway extends InMemoryCoreGateway {
  _RecordingCoreGateway() : super();

  bool? lastExportComicArchive;
  ComicArchiveContainerFrb? lastComicArchiveContainer;

  @override
  Future<void> exportArchive({
    required String projectId,
    required String destinationPath,
    required bool exportComicArchive,
    ComicArchiveContainerFrb? comicArchiveContainer,
    required bool deleteProjectAfterExport,
  }) async {
    lastExportComicArchive = exportComicArchive;
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
      ),
      deleteProjectAfterExport: false,
    );

    expect(gateway.lastExportComicArchive, isTrue);
    expect(gateway.lastComicArchiveContainer, ComicArchiveContainerFrb.zip);
  });

  test('routes RAR comic archive to comic CBR export', () async {
    await workflow.execute(
      projectId: 'p1',
      target: const ResolvedExportTarget(
        destinationPath: '/tmp/out.cbr',
        formatLabel: 'CBR',
        exportComicArchive: true,
        comicArchiveContainer: ComicArchiveContainerFrb.rar,
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
      ),
      deleteProjectAfterExport: false,
    );

    expect(gateway.lastExportComicArchive, isFalse);
    expect(gateway.lastComicArchiveContainer, isNull);
  });
}
