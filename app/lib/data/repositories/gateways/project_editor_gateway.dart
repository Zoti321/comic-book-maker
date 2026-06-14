import 'package:comic_book_maker/data/repositories/core_gateway_types.dart';
import 'package:comic_book_maker/domain/models/project_page_structure.dart';

/// 项目编辑：页面结构、Cover、编辑页快照。
abstract class ProjectEditorGateway {
  ProjectEditorSnapshot loadProjectEditorSnapshot({required String projectId});

  MetadataEditingContext loadMetadataEditingContext({
    required String projectId,
  });

  ProjectPageStructure loadPageStructure({required String projectId});

  List<PageSummary> listPages({required String projectId});

  ProjectPageStructure deletePage({
    required String projectId,
    required String pageId,
  });

  ProjectPageStructure replacePageImage({
    required String projectId,
    required String pageId,
    required String sourcePath,
  });

  ProjectPageStructure reorderPages({
    required String projectId,
    required List<String> orderedPageIds,
  });

  int setProjectCoverPage({
    required String projectId,
    required int coverPageIndex,
  });
}
