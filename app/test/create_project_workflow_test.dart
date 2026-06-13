import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/models/create_project_draft.dart';
import 'package:comic_book_maker/domain/models/import_archive_format.dart';
import 'package:comic_book_maker/domain/use_cases/create_project_workflow.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/data/repositories/in_memory_core_gateway.dart';

void main() {
  late InMemoryCoreGateway gateway;
  late CreateProjectWorkflow workflow;

  setUp(() {
    gateway = InMemoryCoreGateway.emptyLibrary();
    workflow = CreateProjectWorkflow(gateway: gateway);
  });

  group('CreateProjectDraft.toCommand', () {
    test('throws when import source is missing', () {
      final draft = CreateProjectDraft();

      expect(
        () => draft.toCommand(),
        throwsA(isA<CreateProjectValidationException>()),
      );
    });

    test('throws when dedicated export directory is empty', () {
      final draft = CreateProjectDraft(
        importSource: const CreateProjectImageImport([r'C:\a.png']),
        useDefaultExportDirectory: false,
      );

      expect(
        () => draft.toCommand(),
        throwsA(
          predicate<CreateProjectValidationException>(
            (e) => e.message.contains('专用导出目录'),
          ),
        ),
      );
    });
  });

  group('CreateProjectWorkflow.execute', () {
    test('creates project from page images', () {
      final created = workflow.execute(
        const CreateProjectCommand(
          importSource: CreateProjectImageImport([r'C:\img\1.png']),
          settingsUpdate: ProjectSettingsUpdate(
            exportFormat: ExportFormatFrb.comicArchive,
            deleteProjectAfterExport: false,
            useDefaultExportDirectory: true,
            exportDirectory: null,
            comicArchiveContainer: ComicArchiveContainerFrb.zip,
            useComicArchiveExtension: true,
          ),
        ),
      );

      expect(created.title, '项目A');
      expect(gateway.projects, hasLength(1));
    });

    test('applies custom title on archive import', () {
      final created = workflow.execute(
        CreateProjectCommand(
          title: '我的漫画',
          importSource: const CreateProjectArchiveImport(
            format: ImportArchiveFormat.cbz,
            sourcePath: r'C:\comic.cbz',
          ),
          settingsUpdate: const ProjectSettingsUpdate(
            exportFormat: ExportFormatFrb.comicArchive,
            deleteProjectAfterExport: false,
            useDefaultExportDirectory: true,
            exportDirectory: null,
            comicArchiveContainer: ComicArchiveContainerFrb.zip,
            useComicArchiveExtension: true,
          ),
        ),
      );

      expect(created.title, '我的漫画');
      expect(gateway.metadataByProjectId[created.id]?.title, 'comic');
    });
  });

  group('CreateProjectWorkflow.createFromDraft', () {
    test('maps draft to command and executes', () {
      final draft = CreateProjectDraft()
        ..applyImportSource(
          const CreateProjectImageImport([r'C:\img\2.png']),
        )
        ..projectTitle = '草稿标题';

      final created = workflow.createFromDraft(draft);

      expect(created.title, '草稿标题');
      expect(gateway.projects, hasLength(1));
    });
  });
}
