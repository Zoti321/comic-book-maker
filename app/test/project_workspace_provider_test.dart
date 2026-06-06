import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/data/repositories/in_memory_core_gateway.dart';
import 'support/provider/project_workspace_scope.dart';

void main() {
  late InMemoryCoreGateway gateway;
  late ProviderContainer container;

  setUp(() {
    gateway = InMemoryCoreGateway.editorProject();
    container = projectWorkspaceContainer(gateway: gateway);
  });

  tearDown(() {
    container.dispose();
  });

  ProjectWorkspace workspace(String projectId) =>
      container.read(projectWorkspaceProvider(projectId).notifier);

  ProjectSummary fixtureProject() => gateway.projects.single;

  group('ProjectWorkspace.initialize', () {
    test('loads pages settings and cover from editor snapshot', () {
      workspace(fixtureProject().id).initialize(fixtureProject());

      final state = container.read(projectWorkspaceProvider(fixtureProject().id));
      expect(state.initialized, isTrue);
      expect(state.pages, hasLength(1));
      expect(state.settings?.exportFormat, ExportFormatFrb.comicArchive);
      expect(state.coverPageIndex, 0);
      expect(state.project.title, '测试项目');
    });

    test('skips reload when same project already initialized', () {
      final notifier = workspace(fixtureProject().id);
      notifier.initialize(fixtureProject());
      notifier.reportError('stale');

      notifier.initialize(fixtureProject());

      expect(
        container.read(projectWorkspaceProvider(fixtureProject().id)).error,
        'stale',
      );
    });
  });

  group('ProjectWorkspace.applyMetadataSaved', () {
    test('syncs project title and cover page index', () {
      final notifier = workspace(fixtureProject().id);
      notifier.initialize(fixtureProject());

      notifier.applyMetadataSaved(
        const Metadata(
          title: '元数据标题',
          coverPageIndex: 0,
          pageCount: 1,
        ),
      );

      final state = container.read(projectWorkspaceProvider(fixtureProject().id));
      expect(state.project.title, '元数据标题');
      expect(state.coverPageIndex, 0);
    });
  });

  group('ProjectWorkspace page operations', () {
    test('addPageImages refreshes page list', () async {
      gateway = InMemoryCoreGateway.editorProject();
      container.dispose();
      container = projectWorkspaceContainer(gateway: gateway);

      final notifier = workspace(fixtureProject().id);
      notifier.initialize(fixtureProject());

      await notifier.addPageImages([r'C:\new.png']);

      final state = container.read(projectWorkspaceProvider(fixtureProject().id));
      expect(state.pages, hasLength(2));
      expect(state.error, isNull);
    });

    test('movePageLater swaps page order', () async {
      gateway = InMemoryCoreGateway.editorProject(pageCount: 2);
      container.dispose();
      container = projectWorkspaceContainer(gateway: gateway);

      final notifier = workspace(fixtureProject().id);
      notifier.initialize(fixtureProject());
      final firstPage = container.read(projectWorkspaceProvider(fixtureProject().id)).pages
          .firstWhere((page) => page.sortIndex == 0);

      await notifier.movePageLater(firstPage);

      final ids = container
          .read(projectWorkspaceProvider(fixtureProject().id))
          .pages
          .map((page) => page.id)
          .toList();
      expect(ids, ['page-2', 'page-1']);
    });

    test('setCoverPage updates cover index', () async {
      gateway = InMemoryCoreGateway.editorProject(pageCount: 2);
      container.dispose();
      container = projectWorkspaceContainer(gateway: gateway);

      final notifier = workspace(fixtureProject().id);
      notifier.initialize(fixtureProject());

      await notifier.setCoverPage(1);

      final state = container.read(projectWorkspaceProvider(fixtureProject().id));
      expect(state.coverPageIndex, 1);
      expect(gateway.metadataFor(fixtureProject().id).coverPageIndex, 1);
    });

    test('appendArchive toggles appendingImport and reloads pages', () async {
      final notifier = workspace(fixtureProject().id);
      notifier.initialize(fixtureProject());

      final appendFuture = notifier.appendArchive(
        format: ArchiveFormatKind.cbz,
        sourcePath: r'C:\append.cbz',
      );

      expect(
        container.read(projectWorkspaceProvider(fixtureProject().id)).appendingImport,
        isTrue,
      );

      await appendFuture;

      final state = container.read(projectWorkspaceProvider(fixtureProject().id));
      expect(state.appendingImport, isFalse);
      expect(state.pages, hasLength(2));
    });
  });

  group('ProjectWorkspaceState gates', () {
    test('canExport false when pages empty', () {
      gateway = InMemoryCoreGateway(
        projects: [fixtureProject()],
        pages: [],
      );
      container.dispose();
      container = projectWorkspaceContainer(gateway: gateway);

      workspace(fixtureProject().id).initialize(fixtureProject());

      expect(
        container.read(projectWorkspaceProvider(fixtureProject().id)).canExport,
        isFalse,
      );
    });

    test('canAppendImport false for pdf inferred kind', () {
      gateway.defaultSettings = const ProjectSettings(
        exportFormat: ExportFormatFrb.comicArchive,
        inferredImportKind: InferredImportKindFrb.pdf,
        deleteProjectAfterExport: false,
        useDefaultExportDirectory: true,
        exportDirectory: null,
        comicArchiveContainer: ComicArchiveContainerFrb.zip,
        useComicArchiveExtension: true,
      );

      workspace(fixtureProject().id).initialize(fixtureProject());

      expect(
        container.read(projectWorkspaceProvider(fixtureProject().id)).canAppendImport,
        isFalse,
      );
    });
  });
}
