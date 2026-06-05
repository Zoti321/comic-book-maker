import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/use_cases/archive_export_runner.dart';
import 'package:comic_book_maker/domain/use_cases/export_workflow_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/data/repositories/in_memory_core_gateway.dart';

class _RecordingCoreGateway extends InMemoryCoreGateway {
  _RecordingCoreGateway() : super();

  String? lastExportApi;

  @override
  Future<void> exportCbz({
    required String projectId,
    required String destinationPath,
    required bool deleteProjectAfterExport,
  }) async {
    lastExportApi = 'cbz';
  }

  @override
  Future<void> exportCbr({
    required String projectId,
    required String destinationPath,
    required bool deleteProjectAfterExport,
  }) async {
    lastExportApi = 'cbr';
  }

  @override
  Future<void> exportEpub({
    required String projectId,
    required String destinationPath,
    required bool deleteProjectAfterExport,
  }) async {
    lastExportApi = 'epub';
  }
}

void main() {
  late _RecordingCoreGateway gateway;
  late ArchiveExportRunner runner;

  setUp(() {
    gateway = _RecordingCoreGateway();
    runner = ArchiveExportRunner(gateway: gateway);
  });

  test('routes ZIP comic archive to exportCbz', () async {
    await runner.exportProject(
      projectId: 'p1',
      target: const ResolvedExportTarget(
        destinationPath: '/tmp/out.cbz',
        formatLabel: 'CBZ',
        exportComicArchive: true,
        comicArchiveContainer: ComicArchiveContainerFrb.zip,
      ),
      deleteProjectAfterExport: false,
    );

    expect(gateway.lastExportApi, 'cbz');
  });

  test('routes RAR comic archive to exportCbr', () async {
    await runner.exportProject(
      projectId: 'p1',
      target: const ResolvedExportTarget(
        destinationPath: '/tmp/out.cbr',
        formatLabel: 'CBR',
        exportComicArchive: true,
        comicArchiveContainer: ComicArchiveContainerFrb.rar,
      ),
      deleteProjectAfterExport: false,
    );

    expect(gateway.lastExportApi, 'cbr');
  });

  test('routes EPUB to exportEpub', () async {
    await runner.exportProject(
      projectId: 'p1',
      target: const ResolvedExportTarget(
        destinationPath: '/tmp/out.epub',
        formatLabel: 'EPUB',
        exportComicArchive: false,
      ),
      deleteProjectAfterExport: false,
    );

    expect(gateway.lastExportApi, 'epub');
  });
}
