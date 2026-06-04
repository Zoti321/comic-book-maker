import 'package:comic_book_maker/application/archive_import_runner.dart';
import 'package:comic_book_maker/application/core_gateway.dart';
import 'package:comic_book_maker/ui/create_project/create_project_draft.dart';
import 'package:comic_book_maker/ui/design_system/import_archive_sheet.dart';

export 'core_gateway.dart' show ImportCbzResult, Metadata, ProjectSummary;
export 'package:comic_book_maker/ui/design_system/import_archive_sheet.dart'
    show ImportArchiveFormat;

/// 漫画库领域操作：Create Project、Import、打开记录、删除与列表刷新。
class LibraryOperations {
  LibraryOperations({
    CoreGateway? gateway,
    void Function()? onLibraryChanged,
  })  : _gateway = gateway ?? const FrbCoreGateway(),
        _archiveImport = ArchiveImportRunner(
          gateway: gateway ?? const FrbCoreGateway(),
        ),
        _onLibraryChanged = onLibraryChanged;

  final CoreGateway _gateway;
  final ArchiveImportRunner _archiveImport;
  final void Function()? _onLibraryChanged;

  List<ProjectSummary> listProjects() => _gateway.listProjects();

  /// 打开 Project 前更新最近打开时间并刷新库列表。
  void recordProjectOpened({required String projectId}) {
    _gateway.touchProject(projectId: projectId);
    _notifyLibraryChanged();
  }

  void removeProject({required String projectId}) {
    _gateway.deleteProject(projectId: projectId);
    _notifyLibraryChanged();
  }

  void refreshLibraryCatalog() => _notifyLibraryChanged();

  Future<ProjectSummary> createFromDraft(CreateProjectDraft draft) async {
    final created = await _createFromDraft(draft);
    _notifyLibraryChanged();
    return created;
  }

  Future<ImportCbzResult> importArchive({
    required ImportArchiveFormat format,
    required String sourcePath,
  }) async {
    final imported = await _performArchiveImport(
      format: format,
      sourcePath: sourcePath,
    );
    _notifyLibraryChanged();
    return imported;
  }

  void _notifyLibraryChanged() => _onLibraryChanged?.call();

  Future<ImportCbzResult> _performArchiveImport({
    required ImportArchiveFormat format,
    required String sourcePath,
  }) {
    return Future(
      () => _archiveImport.importNewProject(
        format: format,
        sourcePath: sourcePath,
      ),
    );
  }

  Future<ProjectSummary> _createFromDraft(CreateProjectDraft draft) async {
    final settingsUpdate = draft.toSettingsUpdate();
    final title = draft.effectiveTitle;
    final source = draft.importSource!;

    switch (source) {
      case CreateProjectImageImport(:final sourcePaths):
        final project = _gateway.createProject(title: title);
        _gateway.addPageImages(
          projectId: project.id,
          sourcePaths: sourcePaths,
        );
        _gateway.updateProjectSettings(
          projectId: project.id,
          update: settingsUpdate,
        );
        return _projectWithTitle(project, title);

      case CreateProjectArchiveImport(:final format, :final sourcePath):
        final imported = await _performArchiveImport(
          format: format,
          sourcePath: sourcePath,
        );
        _gateway.updateProjectSettings(
          projectId: imported.project.id,
          update: settingsUpdate,
        );
        if (title != null && title != imported.project.title) {
          await _renameProjectTitle(imported.project.id, title);
          return ProjectSummary(
            id: imported.project.id,
            title: title,
            updatedAtMs: imported.project.updatedAtMs,
            coverThumbnailPath: imported.project.coverThumbnailPath,
          );
        }
        return imported.project;
    }
  }

  Future<void> _renameProjectTitle(String projectId, String title) async {
    final metadata = _gateway.getProjectMetadata(projectId: projectId);
    _gateway.updateProjectMetadata(
      projectId: projectId,
      metadata: Metadata(
        title: title,
        series: metadata.series,
        issueNumber: metadata.issueNumber,
        seriesCount: metadata.seriesCount,
        volume: metadata.volume,
        alternateSeries: metadata.alternateSeries,
        alternateNumber: metadata.alternateNumber,
        alternateCount: metadata.alternateCount,
        summary: metadata.summary,
        notes: metadata.notes,
        year: metadata.year,
        month: metadata.month,
        day: metadata.day,
        writer: metadata.writer,
        penciller: metadata.penciller,
        inker: metadata.inker,
        colorist: metadata.colorist,
        letterer: metadata.letterer,
        coverArtist: metadata.coverArtist,
        editor: metadata.editor,
        translator: metadata.translator,
        publisher: metadata.publisher,
        imprint: metadata.imprint,
        genre: metadata.genre,
        tags: metadata.tags,
        web: metadata.web,
        languageIso: metadata.languageIso,
        format: metadata.format,
        blackAndWhite: metadata.blackAndWhite,
        manga: metadata.manga,
        characters: metadata.characters,
        teams: metadata.teams,
        locations: metadata.locations,
        mainCharacterOrTeam: metadata.mainCharacterOrTeam,
        scanInformation: metadata.scanInformation,
        storyArc: metadata.storyArc,
        storyArcNumber: metadata.storyArcNumber,
        seriesGroup: metadata.seriesGroup,
        ageRating: metadata.ageRating,
        communityRating: metadata.communityRating,
        review: metadata.review,
        gtin: metadata.gtin,
        coverPageIndex: metadata.coverPageIndex,
        pageCount: metadata.pageCount,
      ),
    );
  }
}

ProjectSummary _projectWithTitle(ProjectSummary project, String? title) {
  if (title == null || title == project.title) {
    return project;
  }
  return ProjectSummary(
    id: project.id,
    title: title,
    updatedAtMs: project.updatedAtMs,
    coverThumbnailPath: project.coverThumbnailPath,
  );
}
