import 'package:comic_book_maker/data/repositories/core_gateway_types.dart';

/// 漫画库目录：列表、打开记录、删除、Create Project、项目标题。
abstract class LibraryGateway {
  List<ProjectSummary> listProjects();

  void touchProject({required String projectId});

  void deleteProject({required String projectId});

  ProjectSummary createProjectWithImport(
    CreateProjectWithImportRequest request,
  );

  /// 仅更新 Metadata 标题并持久化（遗留；创建项目请用 [updateProjectTitle]）。
  void patchProjectMetadataTitle({
    required String projectId,
    required String title,
  });

  /// 更新库内项目标题（`projects.project_title`），不影响元数据漫画标题。
  ProjectSummary updateProjectTitle({
    required String projectId,
    required String title,
  });
}
