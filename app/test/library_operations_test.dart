import 'package:comic_book_maker/domain/use_cases/library_operations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/data/repositories/in_memory_core_gateway.dart';

void main() {
  late InMemoryCoreGateway gateway;
  var changeCount = 0;

  setUp(() {
    gateway = InMemoryCoreGateway.emptyLibrary();
    changeCount = 0;
  });

  LibraryOperations operations() => LibraryOperations(
        gateway: gateway,
        onLibraryChanged: () => changeCount++,
      );

  test('listProjects reads backend catalog', () {
    gateway.projects.add(
      ProjectSummary(
        id: 'p1',
        title: '测试',
        updatedAtMs: 1,
        coverThumbnailPath: null,
      ),
    );

    expect(operations().listProjects(), hasLength(1));
    expect(changeCount, 0);
  });

  test('removeProject deletes and notifies library changed', () {
    gateway.projects.add(
      ProjectSummary(
        id: 'p1',
        title: '待删',
        updatedAtMs: 1,
        coverThumbnailPath: null,
      ),
    );

    operations().removeProject(projectId: 'p1');

    expect(gateway.projects, isEmpty);
    expect(changeCount, 1);
  });

  test('createFromDraft with image import creates project', () async {
    final library = operations();
    final draft = CreateProjectDraft()
      ..applyImportSource(
        const CreateProjectImageImport([r'C:\img\1.png']),
      );

    final created = await library.createFromDraft(draft);

    expect(created.title, '未命名');
    expect(gateway.projects, hasLength(1));
    expect(gateway.pages, hasLength(1));
    expect(changeCount, 1);
  });

  test('createFromDraft with archive import and title', () async {
    final library = operations();
    final draft = CreateProjectDraft(projectTitle: '库漫画')
      ..applyImportSource(
        const CreateProjectArchiveImport(
          format: ImportArchiveFormat.cbz,
          sourcePath: r'C:\comic.cbz',
        ),
      );

    final created = await library.createFromDraft(draft);

    expect(created.title, '库漫画');
    expect(gateway.metadataByProjectId[created.id]?.title, '库漫画');
    expect(changeCount, 1);
  });

  test('importArchive adds project and notifies', () async {
    final library = operations();

    final result = await library.importArchive(
      format: ImportArchiveFormat.cbz,
      sourcePath: r'C:\comic.cbz',
    );

    expect(result.project.id, 'imported-1');
    expect(changeCount, 1);
  });
}
