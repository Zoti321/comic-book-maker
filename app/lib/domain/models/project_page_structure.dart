import 'package:comic_book_maker/data/repositories/core_gateway.dart';

/// [Page](CONTEXT.md) 序列与 [Cover](CONTEXT.md) 索引的同步快照。
class ProjectPageStructure {
  const ProjectPageStructure({
    required this.pages,
    required this.coverPageIndex,
  });

  final List<PageSummary> pages;
  final int coverPageIndex;

  int get pageCount => pages.length;
}

/// [Metadata](CONTEXT.md) 保存后需同步到工作区的字段。
class MetadataWorkspacePatch {
  const MetadataWorkspacePatch({
    required this.projectTitle,
    required this.coverPageIndex,
  });

  final String projectTitle;
  final int coverPageIndex;
}

/// 项目编辑会话初始加载结果。
class ProjectEditorLoadResult {
  const ProjectEditorLoadResult({
    required this.pages,
    required this.settings,
    required this.coverPageIndex,
  });

  final List<PageSummary> pages;
  final ProjectSettings settings;
  final int coverPageIndex;
}
