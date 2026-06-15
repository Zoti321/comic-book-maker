import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/models/project_page_structure.dart';

export 'package:comic_book_maker/domain/models/project_page_structure.dart'
    show MetadataWorkspacePatch, ProjectEditorLoadResult, ProjectPageStructure;

/// [Project](CONTEXT.md) 编辑域逻辑：页序推算与 workspace 补丁映射。
class ProjectEditingSession {
  ProjectEditingSession({ProjectEditorGateway? editor})
      : _editor = editor ?? const FrbCoreGateway();

  final ProjectEditorGateway _editor;

  ProjectEditorLoadResult loadEditor(String projectId) {
    final snapshot = _editor.loadProjectEditorSnapshot(projectId: projectId);
    return ProjectEditorLoadResult(
      pages: snapshot.pages,
      settings: snapshot.settings,
      coverPageIndex: snapshot.coverPageIndex,
    );
  }

  MetadataWorkspacePatch metadataWorkspacePatch(Metadata metadata) {
    return MetadataWorkspacePatch(
      coverPageIndex: metadata.coverPageIndex,
    );
  }

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
