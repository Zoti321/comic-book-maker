import 'package:comic_book_maker/data/repositories/core_gateway_types.dart';

/// 项目 Export / Import 设置（`ProjectSettings`）。
abstract class ProjectSettingsGateway {
  ProjectSettings getProjectSettings({required String projectId});

  ProjectSettings updateProjectSettings({
    required String projectId,
    required ProjectSettingsUpdate update,
  });

  ProjectSettings changeProjectInferredImportKind({
    required String projectId,
    required InferredImportKindFrb inferredImportKind,
  });
}
