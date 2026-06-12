import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/data/repositories/metadata_patch.dart';

import '../../metadata/metadata_clone.dart';
import '../../metadata/metadata_editor_schema.dart';

/// 默认空库元数据（`widget_test` 等）。
const Metadata kEmptyLibraryMetadata = Metadata(
  title: '未命名',
  coverPageIndex: 0,
  pageCount: 0,
);

/// `MetadataPanel` widget 测试用的预置元数据（projectId `p1`）。
const Metadata kMetadataPanelFixture = Metadata(
  title: '初始标题',
  series: '初始系列',
  issueNumber: '01',
  volume: '1',
  summary: '简介',
  writer: '作者',
  publisher: '出版社',
  languageIso: 'zh-CN',
  gtin: '123',
  coverPageIndex: 0,
  pageCount: 3,
);

/// 测试用 in-memory [CoreGateway]；状态与工厂替代臃肿的 FRB mock 实现。
class InMemoryCoreGateway implements CoreGateway {
  InMemoryCoreGateway({
    List<ProjectSummary>? projects,
    Map<String, Metadata>? metadataByProjectId,
    this.defaultMetadata = kEmptyLibraryMetadata,
    ProjectSettings? defaultSettings,
    this.nextMetadataUpdateError,
    List<PageSummary>? pages,
  })  : projects = List.of(projects ?? []),
        metadataByProjectId = Map.of(metadataByProjectId ?? {}),
        pages = List.of(pages ?? []),
        defaultSettings = defaultSettings ??
            const ProjectSettings(
              exportFormat: ExportFormatFrb.comicArchive,
              inferredImportKind: InferredImportKindFrb.images,
              deleteProjectAfterExport: false,
              useDefaultExportDirectory: true,
              exportDirectory: null,
              comicArchiveContainer: ComicArchiveContainerFrb.zip,
              useComicArchiveExtension: true,
            );

  factory InMemoryCoreGateway.emptyLibrary() => InMemoryCoreGateway();

  factory InMemoryCoreGateway.metadataPanel() => InMemoryCoreGateway(
        metadataByProjectId: const {'p1': kMetadataPanelFixture},
      );

  factory InMemoryCoreGateway.editorProject({int pageCount = 1}) {
    final project = ProjectSummary(
      id: 'p1',
      title: '测试项目',
      updatedAtMs: DateTime.utc(2024, 1, 1).millisecondsSinceEpoch,
      createdAtMs: DateTime.utc(2024, 1, 1).millisecondsSinceEpoch,
      coverThumbnailPath: null,
    );
    final pages = List<PageSummary>.generate(
      pageCount,
      (index) => PageSummary(
        id: 'page-${index + 1}',
        sortIndex: index,
        assetPath: 'assets/page-${index + 1}.png',
        absolutePath: r'C:\temp\page-' '${index + 1}.png',
      ),
    );
    return InMemoryCoreGateway(
      projects: [project],
      metadataByProjectId: {
        'p1': Metadata(
          title: '初始标题',
          series: '初始系列',
          issueNumber: '01',
          volume: '1',
          summary: '简介',
          writer: '作者',
          publisher: '出版社',
          languageIso: 'zh-CN',
          gtin: '123',
          coverPageIndex: 0,
          pageCount: pageCount,
        ),
      },
      pages: pages,
      defaultSettings: const ProjectSettings(
        exportFormat: ExportFormatFrb.comicArchive,
        inferredImportKind: InferredImportKindFrb.images,
        deleteProjectAfterExport: false,
        useDefaultExportDirectory: false,
        exportDirectory: r'C:\temp\comic-exports',
        comicArchiveContainer: ComicArchiveContainerFrb.zip,
        useComicArchiveExtension: true,
      ),
    );
  }

  final List<ProjectSummary> projects;
  final Map<String, Metadata> metadataByProjectId;
  final List<PageSummary> pages;
  final Metadata defaultMetadata;
  ProjectSettings defaultSettings;
  Object? nextMetadataUpdateError;
  bool failMetadataUpdates = false;
  int metadataUpdateCallCount = 0;
  int exportCallCount = 0;
  void Function()? onMetadataUpdate;

  Metadata metadataFor(String projectId) =>
      metadataByProjectId[projectId] ?? defaultMetadata;

  @override
  List<ProjectSummary> listProjects() => List.of(projects);

  @override
  void touchProject({required String projectId}) {
    final index = projects.indexWhere((project) => project.id == projectId);
    if (index < 0) return;
    final project = projects[index];
    final now = DateTime.now().millisecondsSinceEpoch;
    projects[index] = ProjectSummary(
      id: project.id,
      title: project.title,
      updatedAtMs: project.updatedAtMs,
      createdAtMs: project.createdAtMs,
      lastOpenedAtMs: now,
      coverThumbnailPath: project.coverThumbnailPath,
    );
  }

  @override
  void deleteProject({required String projectId}) {
    projects.removeWhere((p) => p.id == projectId);
    metadataByProjectId.remove(projectId);
  }

  ProjectSummary _createProject({String? title}) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final project = ProjectSummary(
      id: 'project-${projects.length + 1}',
      title: title ?? '未命名',
      updatedAtMs: now,
      createdAtMs: now,
      coverThumbnailPath: null,
    );
    projects.add(project);
    return project;
  }

  @override
  ProjectSummary createProjectWithImport(CreateProjectWithImportRequest request) {
    final project = switch (request.import) {
      CreateProjectFromImages(:final sourcePaths) => _createFromImages(
          title: request.title,
          sourcePaths: sourcePaths,
          settingsUpdate: request.settingsUpdate,
        ),
      CreateProjectFromArchive(:final format, :final sourcePath) =>
        _createFromArchive(
          format: format,
          sourcePath: sourcePath,
          settingsUpdate: request.settingsUpdate,
        ),
    };

    final title = request.title;
    if (title == null || title == project.title) {
      return project;
    }
    patchProjectMetadataTitle(projectId: project.id, title: title);
    return ProjectSummary(
      id: project.id,
      title: title,
      updatedAtMs: project.updatedAtMs,
      createdAtMs: project.createdAtMs,
      lastOpenedAtMs: project.lastOpenedAtMs,
      coverThumbnailPath: project.coverThumbnailPath,
    );
  }

  ProjectSummary _createFromImages({
    required String? title,
    required List<String> sourcePaths,
    required ProjectSettingsUpdate settingsUpdate,
  }) {
    final created = _createProject(title: title);
    addPageImages(projectId: created.id, sourcePaths: sourcePaths);
    updateProjectSettings(projectId: created.id, update: settingsUpdate);
    return created;
  }

  ProjectSummary _createFromArchive({
    required ArchiveFormatKind format,
    required String sourcePath,
    required ProjectSettingsUpdate settingsUpdate,
  }) {
    final imported = importArchive(format: format, sourcePath: sourcePath);
    updateProjectSettings(
      projectId: imported.project.id,
      update: settingsUpdate,
    );
    return imported.project;
  }

  @override
  void patchProjectMetadataTitle({
    required String projectId,
    required String title,
  }) {
    final metadata = metadataFor(projectId);
    metadataByProjectId[projectId] = metadataWithTitle(metadata, title);
  }

  @override
  ProjectEditorSnapshot loadProjectEditorSnapshot({required String projectId}) {
    var coverPageIndex = 0;
    try {
      coverPageIndex = metadataFor(projectId).coverPageIndex;
    } catch (_) {}
    return ProjectEditorSnapshot(
      pages: listPages(projectId: projectId),
      settings: getProjectSettings(projectId: projectId),
      coverPageIndex: coverPageIndex,
    );
  }

  @override
  MetadataEditingContext loadMetadataEditingContext({
    required String projectId,
  }) {
    return MetadataEditingContext(
      metadata: getProjectMetadata(projectId: projectId),
      importSnapshot: getImportMetadataSnapshot(projectId: projectId),
      inferredImportKind:
          getProjectSettings(projectId: projectId).inferredImportKind,
    );
  }

  @override
  ImportCbzResult importArchive({
    required ArchiveFormatKind format,
    required String sourcePath,
  }) =>
      _importArchive();

  ImportCbzResult _importArchive() => ImportCbzResult(
        project: ProjectSummary(
          id: 'imported-1',
          title: 'Imported',
          updatedAtMs: DateTime.now().millisecondsSinceEpoch,
          createdAtMs: DateTime.now().millisecondsSinceEpoch,
          coverThumbnailPath: null,
        ),
        warnings: const [],
      );

  @override
  List<PageSummary> addPageImages({
    required String projectId,
    required List<String> sourcePaths,
  }) {
    for (final path in sourcePaths) {
      final index = pages.length;
      pages.add(
        PageSummary(
          id: 'page-${index + 1}',
          sortIndex: index,
          assetPath: 'assets/page-${index + 1}.png',
          absolutePath: path,
        ),
      );
    }
    return List.of(pages);
  }

  @override
  ProjectSettings getProjectSettings({required String projectId}) =>
      defaultSettings;

  @override
  ProjectSettings updateProjectSettings({
    required String projectId,
    required ProjectSettingsUpdate update,
  }) {
    defaultSettings = ProjectSettings(
      exportFormat: update.exportFormat,
      inferredImportKind: defaultSettings.inferredImportKind,
      deleteProjectAfterExport: update.deleteProjectAfterExport,
      useDefaultExportDirectory: update.useDefaultExportDirectory,
      exportDirectory: update.exportDirectory,
      comicArchiveContainer: update.comicArchiveContainer,
      useComicArchiveExtension: update.useComicArchiveExtension,
    );
    return defaultSettings;
  }

  @override
  Metadata getProjectMetadata({required String projectId}) =>
      metadataFor(projectId);

  @override
  Metadata updateProjectMetadata({
    required String projectId,
    required Metadata metadata,
  }) {
    metadataUpdateCallCount++;
    if (failMetadataUpdates) {
      throw Exception('磁盘写入失败');
    }
    if (nextMetadataUpdateError != null) {
      final error = nextMetadataUpdateError!;
      nextMetadataUpdateError = null;
      if (error is Exception) throw error;
      throw Exception(error.toString());
    }
    onMetadataUpdate?.call();
    metadataByProjectId[projectId] = metadata;
    return metadata;
  }

  @override
  ImportMetadataSnapshotFrb getImportMetadataSnapshot({
    required String projectId,
  }) =>
      const ImportMetadataSnapshotFrb(
        kind: ImportMetadataKindFrb.none,
        xml: null,
      );

  @override
  MetadataEditorSchemaFrb getMetadataEditorSchema({
    required ExportFormatFrb exportFormat,
  }) =>
      metadataEditorSchemaFixture(exportFormat);

  @override
  Metadata metadataWithPageCount({
    required Metadata metadata,
    required int pageCount,
  }) =>
      mockMetadataWithPageCount(metadata: metadata, pageCount: pageCount);

  @override
  Metadata metadataWithDropdownField({
    required Metadata metadata,
    required String fieldId,
    String? value,
  }) =>
      mockMetadataWithDropdownField(
        metadata: metadata,
        fieldId: fieldId,
        value: value,
      );

  @override
  Metadata metadataWithCoverPageIndex({
    required Metadata metadata,
    required int coverPageIndex,
  }) =>
      mockMetadataWithCoverPageIndex(
        metadata: metadata,
        coverPageIndex: coverPageIndex,
      );

  @override
  String metadataFieldDisplayValue({
    required Metadata metadata,
    required String fieldId,
  }) =>
      mockMetadataFieldDisplayValue(metadata: metadata, fieldId: fieldId);

  @override
  Metadata mergeMetadataFromForm({
    required ExportFormatFrb exportFormat,
    required Metadata base,
    required List<MetadataFieldValueFrb> fieldValues,
    required int pageCount,
  }) =>
      mockMergeMetadataFromForm(
        base: base,
        fieldValues: fieldValues,
        pageCount: pageCount,
      );

  @override
  ProjectSettings changeProjectInferredImportKind({
    required String projectId,
    required InferredImportKindFrb inferredImportKind,
  }) {
    defaultSettings = ProjectSettings(
      exportFormat: defaultSettings.exportFormat,
      inferredImportKind: inferredImportKind,
      deleteProjectAfterExport: defaultSettings.deleteProjectAfterExport,
      useDefaultExportDirectory: defaultSettings.useDefaultExportDirectory,
      exportDirectory: defaultSettings.exportDirectory,
      comicArchiveContainer: defaultSettings.comicArchiveContainer,
      useComicArchiveExtension: defaultSettings.useComicArchiveExtension,
    );
    return defaultSettings;
  }

  @override
  List<PageSummary> listPages({required String projectId}) => List.of(pages);

  @override
  AppendImportResult appendArchive({
    required String projectId,
    required ArchiveFormatKind format,
    required String sourcePath,
  }) {
    final index = pages.length;
    pages.add(
      PageSummary(
        id: 'appended-${index + 1}',
        sortIndex: index,
        assetPath: 'assets/appended-${index + 1}.png',
        absolutePath: sourcePath,
      ),
    );
    return const AppendImportResult(warnings: [], addedPageCount: 1);
  }

  @override
  int setProjectCoverPage({
    required String projectId,
    required int coverPageIndex,
    required int pageCount,
  }) {
    final metadata = metadataFor(projectId);
    final patched = mockMetadataWithCoverPageIndex(
      metadata: mockMetadataWithPageCount(
        metadata: metadata,
        pageCount: pageCount,
      ),
      coverPageIndex: coverPageIndex,
    );
    metadataByProjectId[projectId] = patched;
    return patched.coverPageIndex;
  }

  @override
  void deletePage({required String projectId, required String pageId}) {
    pages.removeWhere((page) => page.id == pageId);
    for (var index = 0; index < pages.length; index++) {
      final page = pages[index];
      pages[index] = PageSummary(
        id: page.id,
        sortIndex: index,
        assetPath: page.assetPath,
        absolutePath: page.absolutePath,
      );
    }
  }

  @override
  PageSummary replacePageImage({
    required String projectId,
    required String pageId,
    required String sourcePath,
  }) =>
      PageSummary(
        id: pageId,
        sortIndex: 0,
        assetPath: 'assets/$pageId.png',
        absolutePath: '/tmp/$pageId.png',
      );

  @override
  List<PageSummary> reorderPages({
    required String projectId,
    required List<String> orderedPageIds,
  }) {
    final byId = {for (final page in pages) page.id: page};
    pages
      ..clear()
      ..addAll([
        for (var index = 0; index < orderedPageIds.length; index++)
          if (byId.containsKey(orderedPageIds[index]))
            PageSummary(
              id: byId[orderedPageIds[index]]!.id,
              sortIndex: index,
              assetPath: byId[orderedPageIds[index]]!.assetPath,
              absolutePath: byId[orderedPageIds[index]]!.absolutePath,
            ),
      ]);
    return List.of(pages);
  }

  @override
  Future<void> exportArchive({
    required String projectId,
    required String destinationPath,
    required bool exportComicArchive,
    ComicArchiveContainerFrb? comicArchiveContainer,
    required bool exportPdf,
    required bool deleteProjectAfterExport,
  }) async {
    exportCallCount++;
  }
}
