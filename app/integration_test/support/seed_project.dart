import 'dart:io';

import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/ui/core/project_settings_update.dart';
import 'package:path/path.dart' as p;

import 'fixtures.dart';

/// 从 `integration_test/fixtures/two_pages.cbz` 导入并配置导出目录。
SeededIntegrationProject seedTwoPagesProject({
  required Directory appDataDir,
  required Directory exportDir,
}) {
  ensureIntegrationFixtureCbz();
  final fixturePath = integrationFixtureCbzPath();

  resetLibraryForTesting();
  initLibrary(appDataDir: appDataDir.path);

  final imported = importCbz(sourcePath: fixturePath);
  final projectId = imported.project.id;
  final settings = getProjectSettings(projectId: projectId);

  updateProjectSettings(
    projectId: projectId,
    update: projectSettingsUpdateFrom(
      settings,
      useDefaultExportDirectory: false,
      exportDirectory: exportDir.path,
      deleteProjectAfterExport: false,
    ),
  );

  return SeededIntegrationProject(
    projectId: projectId,
    catalogTitle: imported.project.title,
    fixturePath: fixturePath,
    exportDir: exportDir,
  );
}

class SeededIntegrationProject {
  const SeededIntegrationProject({
    required this.projectId,
    required this.catalogTitle,
    required this.fixturePath,
    required this.exportDir,
  });

  final String projectId;
  final String catalogTitle;
  final String fixturePath;
  final Directory exportDir;

  String get expectedExportBaseName => '$catalogTitle.cbz';

  File get expectedExportFile => File(p.join(exportDir.path, expectedExportBaseName));
}
