import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/models/project_page_structure.dart';

export 'package:comic_book_maker/domain/models/project_page_structure.dart'
    show MetadataWorkspacePatch, ProjectEditorLoadResult, ProjectPageStructure;

/// [Project](CONTEXT.md) 编辑会话：统一 pages、Cover、Metadata 标题与 ProjectSettings。
class ProjectEditingSession {
  ProjectEditingSession({CoreGateway? gateway})
      : _gateway = gateway ?? const FrbCoreGateway();

  final CoreGateway _gateway;

  ProjectEditorLoadResult loadEditor(String projectId) {
    final snapshot = _gateway.loadProjectEditorSnapshot(projectId: projectId);
    return ProjectEditorLoadResult(
      pages: snapshot.pages,
      settings: snapshot.settings,
      coverPageIndex: snapshot.coverPageIndex,
    );
  }

  ProjectPageStructure refreshPageStructure(String projectId) {
    final snapshot = _gateway.loadProjectEditorSnapshot(projectId: projectId);
    return ProjectPageStructure(
      pages: snapshot.pages,
      coverPageIndex: snapshot.coverPageIndex,
    );
  }

  MetadataWorkspacePatch metadataWorkspacePatch(Metadata metadata) {
    return MetadataWorkspacePatch(
      coverPageIndex: metadata.coverPageIndex,
    );
  }

  ProjectSummary renameProjectTitle({
    required String projectId,
    required String title,
  }) {
    return _gateway.updateProjectTitle(projectId: projectId, title: title);
  }

  ProjectSettings saveProjectSettings({
    required String projectId,
    required ProjectSettingsUpdate update,
  }) =>
      _gateway.updateProjectSettings(projectId: projectId, update: update);

  ProjectSettings changeInferredImportKind({
    required String projectId,
    required InferredImportKindFrb inferredImportKind,
  }) =>
      _gateway.changeProjectInferredImportKind(
        projectId: projectId,
        inferredImportKind: inferredImportKind,
      );

  Future<ProjectPageStructure> addPageImages({
    required String projectId,
    required List<String> sourcePaths,
  }) async {
    _gateway.addPageImages(projectId: projectId, sourcePaths: sourcePaths);
    return refreshPageStructure(projectId);
  }

  Future<({AppendImportResult result, ProjectPageStructure structure})>
      appendArchive({
    required String projectId,
    required ArchiveFormatKind format,
    required String sourcePath,
  }) async {
    final result = _gateway.appendArchive(
      projectId: projectId,
      format: format,
      sourcePath: sourcePath,
    );
    final structure = refreshPageStructure(projectId);
    return (result: result, structure: structure);
  }

  Future<ProjectPageStructure> replacePageImage({
    required String projectId,
    required String pageId,
    required String sourcePath,
  }) async {
    _gateway.replacePageImage(
      projectId: projectId,
      pageId: pageId,
      sourcePath: sourcePath,
    );
    return refreshPageStructure(projectId);
  }

  Future<ProjectPageStructure> deletePage({
    required String projectId,
    required String pageId,
  }) async {
    _gateway.deletePage(projectId: projectId, pageId: pageId);
    return refreshPageStructure(projectId);
  }

  Future<ProjectPageStructure> reorderPages({
    required String projectId,
    required List<String> orderedPageIds,
  }) async {
    final pages = _gateway.reorderPages(
      projectId: projectId,
      orderedPageIds: orderedPageIds,
    );
    final coverPageIndex =
        _gateway.loadProjectEditorSnapshot(projectId: projectId).coverPageIndex;
    return ProjectPageStructure(
      pages: pages,
      coverPageIndex: coverPageIndex,
    );
  }

  int setCoverPage({
    required String projectId,
    required int sortIndex,
    required int pageCount,
  }) =>
      _gateway.setProjectCoverPage(
        projectId: projectId,
        coverPageIndex: sortIndex,
        pageCount: pageCount,
      );

  List<PageSummary> sortedPages(List<PageSummary> pages) {
    return List<PageSummary>.from(pages)
      ..sort((a, b) => a.sortIndex.compareTo(b.sortIndex));
  }

  List<String> pageIdsAfterSwap(
    List<PageSummary> pages,
    String pageId, {
    required bool moveEarlier,
  }) {
    final sorted = sortedPages(pages);
    final index = sorted.indexWhere((p) => p.id == pageId);
    if (index < 0) return sorted.map((p) => p.id).toList();
    if (moveEarlier && index <= 0) {
      return sorted.map((p) => p.id).toList();
    }
    if (!moveEarlier && index >= sorted.length - 1) {
      return sorted.map((p) => p.id).toList();
    }
    final ids = sorted.map((p) => p.id).toList();
    final swapIndex = moveEarlier ? index - 1 : index + 1;
    final otherId = ids[swapIndex];
    ids[swapIndex] = ids[index];
    ids[index] = otherId;
    return ids;
  }
}
