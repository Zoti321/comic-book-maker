import 'package:comic_book_maker/data/repositories/core_gateway_types.dart';
import 'package:comic_book_maker/domain/models/project_page_structure.dart';

/// Archive Format 导入与向项目追加页面。
abstract class ArchiveGateway {
  ImportCbzResult importArchive({
    required ArchiveFormatFrb format,
    required String sourcePath,
  });

  AppendImportResult appendArchive({
    required String projectId,
    required ArchiveFormatFrb format,
    required String sourcePath,
  });

  ProjectPageStructure addPageImages({
    required String projectId,
    required List<String> sourcePaths,
  });
}
