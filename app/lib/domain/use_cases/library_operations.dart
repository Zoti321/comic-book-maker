import 'package:comic_book_maker/domain/models/create_project_draft.dart';
import 'package:comic_book_maker/domain/use_cases/archive_import_runner.dart';
import 'package:comic_book_maker/domain/use_cases/create_project_workflow.dart';
import 'package:comic_book_maker/data/repositories/core_gateway.dart';

export 'package:comic_book_maker/data/repositories/core_gateway.dart'
    show ImportCbzResult, Metadata, ProjectSummary;
export 'package:comic_book_maker/domain/models/create_project_command.dart'
    show CreateProjectCommand, CreateProjectValidationException;
export 'package:comic_book_maker/domain/models/create_project_draft.dart'
    show CreateProjectDraft;
export 'package:comic_book_maker/domain/models/create_project_import_source.dart'
    show
        CreateProjectArchiveImport,
        CreateProjectImageImport,
        CreateProjectImportSource;
export 'package:comic_book_maker/domain/models/import_archive_format.dart'
    show ImportArchiveFormat;
export 'package:comic_book_maker/domain/use_cases/create_project_workflow.dart'
    show CreateProjectWorkflow;

/// 漫画库编排：Create Project、Import、目录变更通知。
class LibraryOperations {
  LibraryOperations({
    CoreGateway? gateway,
    void Function()? onLibraryChanged,
    CreateProjectWorkflow? createProject,
  })  : _gateway = gateway ?? const FrbCoreGateway(),
        _createProject = createProject ??
            CreateProjectWorkflow(gateway: gateway ?? const FrbCoreGateway()),
        _archiveImport = ArchiveImportRunner(
          gateway: gateway ?? const FrbCoreGateway(),
        ),
        _onLibraryChanged = onLibraryChanged;

  final CoreGateway _gateway;
  final CreateProjectWorkflow _createProject;
  final ArchiveImportRunner _archiveImport;
  final void Function()? _onLibraryChanged;

  List<ProjectSummary> listProjects() => _gateway.listProjects();

  /// 打开 Project 时更新 Library Database 中的最近访问时间。
  void recordProjectOpened({required String projectId}) {
    _gateway.touchProject(projectId: projectId);
    _notifyLibraryChanged();
  }

  void removeProject({required String projectId}) {
    _gateway.deleteProject(projectId: projectId);
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
    required ImportArchiveFormat format,
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
    required ImportArchiveFormat format,
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
