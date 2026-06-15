import 'package:comic_book_maker/domain/models/create_project_draft.dart';
import 'package:comic_book_maker/domain/use_cases/archive_import_runner.dart';
import 'package:comic_book_maker/domain/use_cases/create_project_workflow.dart';
import 'package:comic_book_maker/data/repositories/core_gateway.dart';

export 'package:comic_book_maker/data/repositories/core_gateway.dart'
    show ArchiveFormatFrb, ImportCbzResult, Metadata, ProjectSummary;
export 'package:comic_book_maker/domain/models/create_project_command.dart'
    show CreateProjectCommand, CreateProjectValidationException;
export 'package:comic_book_maker/domain/models/create_project_draft.dart'
    show CreateProjectDraft;
export 'package:comic_book_maker/domain/models/create_project_import_source.dart'
    show
        CreateProjectArchiveImport,
        CreateProjectImageImport,
        CreateProjectImportSource;
export 'package:comic_book_maker/domain/use_cases/create_project_workflow.dart'
    show CreateProjectWorkflow;

/// 漫画库编排：Create Project、Import、目录变更通知。
class LibraryOperations {
  LibraryOperations({
    LibraryGateway? library,
    ArchiveGateway? archive,
    void Function()? onLibraryChanged,
    CreateProjectWorkflow? createProject,
    ArchiveImportRunner? archiveImport,
  })  : _library = library ?? const FrbCoreGateway(),
        _createProject = createProject ??
            CreateProjectWorkflow(gateway: library ?? const FrbCoreGateway()),
        _archiveImport = archiveImport ??
            ArchiveImportRunner(
              gateway: archive ??
                  (library ?? const FrbCoreGateway()) as ArchiveGateway,
            ),
        _onLibraryChanged = onLibraryChanged;

  final LibraryGateway _library;
  final CreateProjectWorkflow _createProject;
  final ArchiveImportRunner _archiveImport;
  final void Function()? _onLibraryChanged;

  List<ProjectSummary> listProjects() => _library.listProjects();

  /// 打开 Project 时更新 Library Database 中的最近访问时间。
  void recordProjectOpened({required String projectId}) {
    _library.touchProject(projectId: projectId);
    _notifyLibraryChanged();
  }

  void removeProject({required String projectId}) {
    _library.deleteProject(projectId: projectId);
    _notifyLibraryChanged();
  }

  void refreshLibraryCatalog() => _notifyLibraryChanged();

  /// 从向导 [CreateProjectDraft] 执行 Create Project 事务。
  Future<ProjectSummary> createFromDraft(CreateProjectDraft draft) {
    return Future(() {
      final created = _createProject.createFromDraft(draft);
      _notifyLibraryChanged();
      return created;
    });
  }

  Future<ImportCbzResult> importArchive({
    required ArchiveFormatFrb format,
    required String sourcePath,
  }) async {
    final imported = await _performArchiveImport(
      format: format,
      sourcePath: sourcePath,
    );
    _notifyLibraryChanged();
    return imported;
  }

  void _notifyLibraryChanged() => _onLibraryChanged?.call();

  Future<ImportCbzResult> _performArchiveImport({
    required ArchiveFormatFrb format,
    required String sourcePath,
  }) {
    return Future(
      () => _archiveImport.importNewProject(
        format: format,
        sourcePath: sourcePath,
      ),
    );
  }
}
