import 'package:comic_book_maker/src/rust/api/metadata.dart' as metadata_api;
import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/ui/create_project/create_project_draft.dart';
import 'package:comic_book_maker/ui/create_project/create_project_wizard_dialog.dart';
import 'package:comic_book_maker/ui/design_system/design_system.dart';
import 'package:flutter/material.dart';
/// 打开新建项目向导；成功返回新 [ProjectSummary]，取消返回 `null`。
Future<ProjectSummary?> runCreateProjectWizard({
  required BuildContext context,
}) async {
  final draft = await showAppFeatureDialog<CreateProjectDraft>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => const CreateProjectWizardDialog(),
  );
  if (draft == null || !context.mounted || !draft.canCreate) {
    return null;
  }

  ProjectSummary? created;
  try {
    created = await runAppBlockingOperation(
      context: context,
      message: '正在创建项目…',
      operation: () => _createProjectFromDraft(draft),
    );
  } catch (e) {
    if (!context.mounted) return null;
    await showAppOperationFailure(
      context,
      title: '创建失败',
      message: e.toString(),
      nextStepHint: '请确认文件未损坏且格式受支持，然后重试。',
    );
    return null;
  }

  return created;
}

Future<ProjectSummary> _createProjectFromDraft(CreateProjectDraft draft) async {
  final settingsUpdate = draft.toSettingsUpdate();
  final title = draft.effectiveTitle;
  final source = draft.importSource!;

  switch (source) {
    case CreateProjectImageImport(:final sourcePaths):
      final project = createProject(title: title);
      addPageImages(projectId: project.id, sourcePaths: sourcePaths);
      updateProjectSettings(projectId: project.id, update: settingsUpdate);
      return _projectWithTitle(project, title);

    case CreateProjectArchiveImport(:final format, :final sourcePath):
      final imported = await Future(
        () => switch (format) {
          ImportArchiveFormat.cbz => importCbz(sourcePath: sourcePath),
          ImportArchiveFormat.cbr => importCbr(sourcePath: sourcePath),
          ImportArchiveFormat.epub => importEpub(sourcePath: sourcePath),
        },
      );
      updateProjectSettings(
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

Future<void> _renameProjectTitle(String projectId, String title) async {
  final metadata = metadata_api.getProjectMetadata(projectId: projectId);
  metadata_api.updateProjectMetadata(
    projectId: projectId,
    metadata: metadata_api.Metadata(
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
