import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/use_cases/archive_import_runner.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/data/repositories/in_memory_core_gateway.dart';

class _RecordingCoreGateway extends InMemoryCoreGateway {
  _RecordingCoreGateway() : super();

  ArchiveFormatFrb? lastImportFormat;
  ArchiveFormatFrb? lastAppendFormat;

  @override
  ImportCbzResult importArchive({
    required ArchiveFormatFrb format,
    required String sourcePath,
  }) {
    lastImportFormat = format;
    return super.importArchive(format: format, sourcePath: sourcePath);
  }

  @override
  AppendImportResult appendArchive({
    required String projectId,
    required ArchiveFormatFrb format,
    required String sourcePath,
  }) {
    lastAppendFormat = format;
    return super.appendArchive(
      projectId: projectId,
      format: format,
      sourcePath: sourcePath,
    );
  }
}

void main() {
  late InMemoryCoreGateway gateway;
  late ArchiveImportRunner runner;

  setUp(() {
    gateway = InMemoryCoreGateway.emptyLibrary();
    runner = ArchiveImportRunner(gateway: gateway);
  });

  test('importNewProject delegates to gateway by format', () {
    final result = runner.importNewProject(
      format: ArchiveFormatFrb.cbz,
      sourcePath: r'C:\comic.cbz',
    );

    expect(result.project.id, 'imported-1');
    expect(result.project.title, 'comic');
    expect(gateway.projects, hasLength(1));
    expect(gateway.projects.single.id, 'imported-1');
  });

  test('importNewProject delegates CB7 to gateway', () {
    final recording = _RecordingCoreGateway();
    final cb7Runner = ArchiveImportRunner(gateway: recording);

    cb7Runner.importNewProject(
      format: ArchiveFormatFrb.cb7,
      sourcePath: r'C:\comic.cb7',
    );

    expect(recording.lastImportFormat, ArchiveFormatFrb.cb7);
  });

  test('appendToProject delegates to gateway by format', () {
    gateway.projects.add(
      ProjectSummary(
        id: 'p1',
        title: '测试',
        updatedAtMs: 1,
        createdAtMs: 1,
        coverThumbnailPath: null,
      ),
    );

    final result = runner.appendToProject(
      projectId: 'p1',
      format: ArchiveFormatFrb.cbr,
      sourcePath: r'C:\comic.cbr',
    );

    expect(result.addedPageCount, 1);
    expect(gateway.pages, hasLength(1));
    expect(result.warnings, isEmpty);
  });

  test('appendToProject delegates CB7 to gateway', () {
    final recording = _RecordingCoreGateway();
    recording.projects.add(
      ProjectSummary(
        id: 'p1',
        title: '测试',
        updatedAtMs: 1,
        createdAtMs: 1,
        coverThumbnailPath: null,
      ),
    );
    final cb7Runner = ArchiveImportRunner(gateway: recording);

    cb7Runner.appendToProject(
      projectId: 'p1',
      format: ArchiveFormatFrb.cb7,
      sourcePath: r'C:\comic.7z',
    );

    expect(recording.lastAppendFormat, ArchiveFormatFrb.cb7);
  });
}
