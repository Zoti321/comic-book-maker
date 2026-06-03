import 'package:comic_book_maker/providers/project_workspace_state.dart';
import 'package:comic_book_maker/src/rust/api/metadata.dart' as metadata_api;
import 'package:comic_book_maker/src/rust/api/simple.dart' as rust;
import 'package:comic_book_maker/ui/project_settings_update.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'project_workspace_provider.g.dart';

/// 单个项目编辑会话的 deep controller：封装 FRB 调用与工作区状态。
@Riverpod(keepAlive: false)
class ProjectWorkspace extends _$ProjectWorkspace {
  @override
  ProjectWorkspaceState build(String projectId) {
    return ProjectWorkspaceState.uninitialized(projectId);
  }

  void initialize(rust.ProjectSummary project) {
    if (state.initialized && state.project.id == project.id) {
      return;
    }
    state = _load(project);
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
    state = _withPages(state);
  }

  Future<void> saveProjectSettings(rust.ProjectSettingsUpdate update) async {
    if (state.savingExportFormat) return;

    state = state.copyWith(savingExportFormat: true, clearError: true);
    try {
      final settings = rust.updateProjectSettings(
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

  Future<void> updateExportFormat(rust.ExportFormatFrb format) async {
    final current = state.settings;
    if (current == null) return;
    await saveProjectSettings(
      projectSettingsUpdateFrom(current, exportFormat: format),
    );
  }

  Future<void> changeInferredImportKind(
    rust.InferredImportKindFrb inferredImportKind,
  ) async {
    if (state.savingExportFormat) return;

    state = state.copyWith(savingExportFormat: true, clearError: true);
    try {
      final settings = rust.changeProjectInferredImportKind(
        projectId: state.projectId,
        inferredImportKind: inferredImportKind,
      );
      state = _load(state.project).copyWith(
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
      rust.addPageImages(
        projectId: state.projectId,
        sourcePaths: sourcePaths,
      );
      state = _withPages(state.copyWith(clearError: true));
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<rust.AppendImportResult> appendCbz(String sourcePath) {
    return _runAppendImport(() => rust.appendCbz(
          projectId: state.projectId,
          sourcePath: sourcePath,
        ));
  }

  Future<rust.AppendImportResult> appendCbr(String sourcePath) {
    return _runAppendImport(() => rust.appendCbr(
          projectId: state.projectId,
          sourcePath: sourcePath,
        ));
  }

  Future<rust.AppendImportResult> appendEpub(String sourcePath) {
    return _runAppendImport(() => rust.appendEpub(
          projectId: state.projectId,
          sourcePath: sourcePath,
        ));
  }

  Future<rust.AppendImportResult> _runAppendImport(
    rust.AppendImportResult Function() append,
  ) async {
    if (state.appendingImport) {
      throw StateError('append import already in progress');
    }

    state = state.copyWith(appendingImport: true, clearError: true);
    try {
      final result = append();
      state = _withPages(state);
      return result;
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    } finally {
      state = state.copyWith(appendingImport: false);
    }
  }

  Future<void> replacePage(String pageId, String sourcePath) async {
    try {
      rust.replacePageImage(
        projectId: state.projectId,
        pageId: pageId,
        sourcePath: sourcePath,
      );
      state = _withPages(state.copyWith(clearError: true));
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> deletePage(String pageId) async {
    try {
      rust.deletePage(projectId: state.projectId, pageId: pageId);
      state = _withPages(state.copyWith(clearError: true));
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> reorderPages(List<String> orderedPageIds) async {
    try {
      final pages = rust.reorderPages(
        projectId: state.projectId,
        orderedPageIds: orderedPageIds,
      );
      state = state.copyWith(pages: pages, clearError: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  Future<void> movePageEarlier(rust.PageSummary page) async {
    final sorted = _sortedPages(state.pages);
    final index = sorted.indexWhere((p) => p.id == page.id);
    if (index <= 0) return;
    final ids = sorted.map((p) => p.id).toList();
    final previousId = ids[index - 1];
    ids[index - 1] = ids[index];
    ids[index] = previousId;
    await reorderPages(ids);
  }

  Future<void> movePageLater(rust.PageSummary page) async {
    final sorted = _sortedPages(state.pages);
    final index = sorted.indexWhere((p) => p.id == page.id);
    if (index < 0 || index >= sorted.length - 1) return;
    final ids = sorted.map((p) => p.id).toList();
    final nextId = ids[index + 1];
    ids[index + 1] = ids[index];
    ids[index] = nextId;
    await reorderPages(ids);
  }

  List<rust.PageSummary> _sortedPages(List<rust.PageSummary> pages) {
    return List<rust.PageSummary>.from(pages)
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
  }

  Future<void> setCoverPage(int sortIndex) async {
    try {
      final metadata = metadata_api.getProjectMetadata(
        projectId: state.projectId,
      );
      final patched = metadata_api.metadataWithCoverPageIndex(
        metadata: metadata_api.metadataWithPageCount(
          metadata: metadata,
          pageCount: state.pages.length,
        ),
        coverPageIndex: sortIndex,
      );
      final updated = metadata_api.updateProjectMetadata(
        projectId: state.projectId,
        metadata: patched,
      );
      state = state.copyWith(
        coverPageIndex: updated.coverPageIndex,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    }
  }

  void applyMetadataSaved(metadata_api.Metadata metadata) {
    state = state.copyWith(
      project: rust.ProjectSummary(
        id: state.projectId,
        title: metadata.title,
        updatedAtMs: state.project.updatedAtMs,
        coverThumbnailPath: state.project.coverThumbnailPath,
      ),
      coverPageIndex: metadata.coverPageIndex,
    );
  }

  Future<void> exportCbz({
    required String destinationPath,
    required bool deleteProjectAfterExport,
  }) {
    return _runExport(() => rust.exportCbz(
          projectId: state.projectId,
          destinationPath: destinationPath,
          deleteProjectAfterExport: deleteProjectAfterExport,
        ));
  }

  Future<void> exportEpub({
    required String destinationPath,
    required bool deleteProjectAfterExport,
  }) {
    return _runExport(() => rust.exportEpub(
          projectId: state.projectId,
          destinationPath: destinationPath,
          deleteProjectAfterExport: deleteProjectAfterExport,
        ));
  }

  Future<void> _runExport(Future<void> Function() export) async {
    if (state.exporting) return;
    if (state.pages.isEmpty) {
      state = state.copyWith(error: 'Export 需要至少一页');
      return;
    }

    state = state.copyWith(exporting: true, clearError: true);
    try {
      await export();
    } catch (e) {
      state = state.copyWith(error: e.toString());
      rethrow;
    } finally {
      state = state.copyWith(exporting: false);
    }
  }

  ProjectWorkspaceState _load(rust.ProjectSummary project) {
    try {
      final pages = rust.listPages(projectId: project.id);
      final settings = rust.getProjectSettings(projectId: project.id);
      var coverPageIndex = 0;
      try {
        coverPageIndex =
            metadata_api
                .getProjectMetadata(projectId: project.id)
                .coverPageIndex;
      } catch (_) {}

      return ProjectWorkspaceState(
        project: project,
        pages: pages,
        settings: settings,
        coverPageIndex: coverPageIndex,
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

  ProjectWorkspaceState _withPages(ProjectWorkspaceState current) {
    try {
      final pages = rust.listPages(projectId: current.projectId);
      var coverPageIndex = current.coverPageIndex;
      try {
        coverPageIndex =
            metadata_api
                .getProjectMetadata(projectId: current.projectId)
                .coverPageIndex;
      } catch (_) {
        coverPageIndex = 0;
      }
      return current.copyWith(
        pages: pages,
        coverPageIndex: coverPageIndex,
      );
    } catch (e) {
      return current.copyWith(error: e.toString());
    }
  }
}
