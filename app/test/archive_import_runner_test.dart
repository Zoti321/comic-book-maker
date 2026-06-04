import 'package:comic_book_maker/application/archive_import_runner.dart';
import 'package:comic_book_maker/application/core_gateway.dart';
import 'package:comic_book_maker/ui/design_system/import_archive_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/in_memory_core_gateway.dart';

void main() {
  late InMemoryCoreGateway gateway;
  late ArchiveImportRunner runner;

  setUp(() {
    gateway = InMemoryCoreGateway.emptyLibrary();
    runner = ArchiveImportRunner(gateway: gateway);
  });

  test('displayName and allowedExtensions match format', () {
    expect(
      ArchiveImportRunner.displayName(ImportArchiveFormat.cbz),
      'CBZ',
    );
    expect(
      ArchiveImportRunner.allowedExtensions(ImportArchiveFormat.epub),
      ['epub'],
    );
  });

  test('importNewProject delegates to gateway by format', () {
    final result = runner.importNewProject(
      format: ImportArchiveFormat.cbz,
      sourcePath: r'C:\comic.cbz',
    );

    expect(result.project.id, 'imported-1');
    expect(gateway.projects, isEmpty);
  });

  test('appendToProject delegates to gateway by format', () {
    gateway.projects.add(
      ProjectSummary(
        id: 'p1',
        title: '测试',
        updatedAtMs: 1,
        coverThumbnailPath: null,
      ),
    );

    final result = runner.appendToProject(
      projectId: 'p1',
      format: ImportArchiveFormat.cbr,
      sourcePath: r'C:\comic.cbr',
    );

    expect(result.addedPageCount, 0);
    expect(result.warnings, isEmpty);
  });
}
