import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/use_cases/project_editing_session.dart';
import 'package:comic_book_maker/providers/core_gateway_provider.dart';
import 'package:comic_book_maker/ui/core/project_settings_update.dart';
import 'package:comic_book_maker/ui/features/project_editor/providers/project_workspace_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'project_workspace_provider.g.dart';

/// 单个 [Project](CONTEXT.md) 编辑工作区：状态由 [ProjectEditingSession] 协调。
@Riverpod(keepAlive: false)
class ProjectWorkspace extends _$ProjectWorkspace {
  ProjectEditingSession get _session =>
      ProjectEditingSession(gateway: ref.read(coreGatewayProvider));

  @override
  ProjectWorkspaceState build(String projectId) {
    return ProjectWorkspaceState.uninitialized(projectId);
  }

  void initialize(ProjectSummary project) {
    if (state.initialized && state.project.id == project.id) {
      return;
    }
    state = _stateFromLoad(project);
  }

  void clearError() {
    if (state.error != null) {
      state = state.copyWith(clearError: true);
    }
  }

  void reportError(String message) {
    state = state.copyWith(error: message);
  }

  void reloadPages() {
    state = _withPageStructure(
      state,
      _session.refreshPageStructure(state.projectId),
    );
  }

  Future<void> saveProjectSettings(ProjectSettingsUpdate update) async {
    if (state.savingExportFormat) return;

    state = state.copyWith(savingExportFormat: true, clearError: true);
    try {
      final settings = _session.saveProjectSettings(
        projectId: state.projectId,
        update: update,
      );
      state = state.copyWith(settings: settings, savingExportFormat: false);
    } catch (e) {
      state = state.copyWith(
        savingExportFormat: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> updateExportFormat(ExportFormatFrb format) async {
    final current = state.settings;
    if (current == null) return;
    await saveProjectSettings(
      projectSettingsUpdateFrom(current, exportFormat: format),
    );
  }

  Future<void> changeInferredImportKind(
    InferredImportKindFrb inferredImportKind,
  ) async {
    if (state.savingExportFormat) return;

    state = state.copyWith(savingExportFormat: true, clearError: true);
    try {
      final settings = _session.changeInferredImportKind(
        projectId: state.projectId,
        inferredImportKind: inferredImportKind,
      );
      state = _stateFromLoad(state.project).copyWith(
        settings: settings,
        savingExportFormat: false,
      );
    } catch (e) {
      state = state.copyWith(
        savingExportFormat: false,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> addPageImages(List<String> sourcePaths) async {
    if (sourcePaths.isEmpty) {
      state = state.copyWith(error: '无法读取所选文件路径');
      return;
    }

    try {
      final structure = await _session.addPageImages(
        projectId: state.projectId,
        sourcePaths: sourcePaths,
      );
      state = _withPageStructure(state.copyWith(clearError: true), structure);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<AppendImportResult> appendArchive({
    required ArchiveFormatKind format,
    required String sourcePath,
  }) {
    return _runAppendImport(() async {
      final outcome = await _session.appendArchive(
        projectId: state.projectId,
        format: format,
        sourcePath: sourcePath,
      );
      state = _withPageStructure(state, outcome.structure);
      return outcome.result;
    });
  }

  Future<AppendImportResult> _runAppendImport(
    Future<AppendImportResult> Function() append,
  ) async {
    if (state.appendingImport) {
      throw StateError('append import already in progress');
    }

    state = state.copyWith(appendingImport: true, clearError: true);
    try {
      return await append();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    } finally {
      state = state.copyWith(appendingImport: false);
    }
  }

  Future<void> replacePage(String pageId, String sourcePath) async {
    try {
      final structure = await _session.replacePageImage(
        projectId: state.projectId,
        pageId: pageId,
        sourcePath: sourcePath,
      );
      state = _withPageStructure(state.copyWith(clearError: true), structure);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deletePage(String pageId) async {
    try {
      final structure = await _session.deletePage(
        projectId: state.projectId,
        pageId: pageId,
      );
      state = _withPageStructure(state.copyWith(clearError: true), structure);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> reorderPages(List<String> orderedPageIds) async {
    try {
      final structure = await _session.reorderPages(
        projectId: state.projectId,
        orderedPageIds: orderedPageIds,
      );
      state = state.copyWith(
        pages: structure.pages,
        coverPageIndex: structure.coverPageIndex,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> movePageEarlier(PageSummary page) async {
    final ids = _session.pageIdsAfterSwap(
      state.pages,
      page.id,
      moveEarlier: true,
    );
    await reorderPages(ids);
  }

  Future<void> movePageLater(PageSummary page) async {
    final ids = _session.pageIdsAfterSwap(
      state.pages,
      page.id,
      moveEarlier: false,
    );
    await reorderPages(ids);
  }

  Future<void> setCoverPage(int sortIndex) async {
    try {
      final coverPageIndex = _session.setCoverPage(
        projectId: state.projectId,
        sortIndex: sortIndex,
        pageCount: state.pages.length,
      );
      state = state.copyWith(
        coverPageIndex: coverPageIndex,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void applyMetadataSaved(Metadata metadata) {
    final patch = _session.metadataWorkspacePatch(metadata);
    state = state.copyWith(
      project: ProjectSummary(
        id: state.projectId,
        title: patch.projectTitle,
        updatedAtMs: state.project.updatedAtMs,
        createdAtMs: state.project.createdAtMs,
        lastOpenedAtMs: state.project.lastOpenedAtMs,
        coverThumbnailPath: state.project.coverThumbnailPath,
      ),
      coverPageIndex: patch.coverPageIndex,
    );
  }

  ProjectWorkspaceState _stateFromLoad(ProjectSummary project) {
    try {
      final load = _session.loadEditor(project.id);
      return ProjectWorkspaceState(
        project: project,
        pages: load.pages,
        settings: load.settings,
        coverPageIndex: load.coverPageIndex,
        initialized: true,
      );
    } catch (e) {
      return ProjectWorkspaceState(
        project: project,
        error: e.toString(),
        initialized: true,
      );
    }
  }

  ProjectWorkspaceState _withPageStructure(
    ProjectWorkspaceState current,
    ProjectPageStructure structure,
  ) {
    return current.copyWith(
      pages: structure.pages,
      coverPageIndex: structure.coverPageIndex,
    );
  }
}
