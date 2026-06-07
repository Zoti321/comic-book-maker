//! Import transaction orchestration: create project, stage assets, commit or rollback.

use crate::db::{Library, MetadataRecord};
use crate::import_metadata_snapshot::ImportMetadataSnapshot;
use crate::project_format::{ExportFormat, InferredImportKind};

use super::staging::remove_staged_page_assets;
use super::types::{AppendImportOutcome, ImportArchiveOutcome, StagedImportPage};

pub fn run_import_with_rollback<F>(
    library: &mut Library,
    title: String,
    inferred_import_kind: InferredImportKind,
    export_format: ExportFormat,
    import_body: F,
) -> Result<ImportArchiveOutcome, String>
where
    F: FnOnce(
        &mut Library,
        &str,
    ) -> Result<
        (
            MetadataRecord,
            Vec<StagedImportPage>,
            Vec<String>,
            ImportMetadataSnapshot,
        ),
        String,
    >,
{
    let project =
        library.create_project_for_import(title, inferred_import_kind, export_format)?;
    match import_body(library, &project.id) {
        Ok((metadata, staged, warnings, snapshot)) => {
            if let Err(error) =
                library.commit_import_project(&project.id, &metadata, &staged, &snapshot)
            {
                let _ = library.abandon_import_project(&project.id);
                return Err(error);
            }
            finalize_import(library, &project.id, warnings)
        }
        Err(error) => {
            let _ = library.abandon_import_project(&project.id);
            Err(error)
        }
    }
}

pub fn run_append_import<F>(
    library: &mut Library,
    project_id: &str,
    expected_kind: InferredImportKind,
    stage: F,
) -> Result<AppendImportOutcome, String>
where
    F: FnOnce(
        &mut Library,
        &str,
        i32,
    ) -> Result<(Vec<StagedImportPage>, Vec<String>, ImportMetadataSnapshot), String>,
{
    if !library.project_exists(project_id)? {
        return Err(format!("project not found: {project_id}"));
    }

    let settings = library.get_project_settings_inner(project_id)?;
    if settings.inferred_import_kind != expected_kind {
        return Err(format!(
            "项目推断导入类型为 {}，无法追加此格式",
            settings.inferred_import_kind.as_str()
        ));
    }

    let start_sort_index = library.next_page_sort_index(project_id)?;
    let (staged, warnings, snapshot) = stage(library, project_id, start_sort_index)?;

    if staged.is_empty() {
        return Err("档案中未找到可用的 Page Image".to_string());
    }

    if let Err(error) = library.commit_append_pages(project_id, &staged, &snapshot) {
        remove_staged_page_assets(library.app_data_dir(), project_id, &staged);
        return Err(error);
    }

    library.refresh_cover_thumbnail_for(project_id)?;

    Ok(AppendImportOutcome {
        warnings,
        added_page_count: staged.len() as i32,
    })
}

pub fn finalize_import(
    library: &mut Library,
    project_id: &str,
    warnings: Vec<String>,
) -> Result<ImportArchiveOutcome, String> {
    library.refresh_cover_thumbnail_for(project_id)?;
    let listed = library.find_project(project_id)?;

    Ok(ImportArchiveOutcome {
        project_id: listed.id,
        title: listed.title,
        updated_at_ms: listed.updated_at_ms,
        created_at_ms: listed.created_at_ms,
        last_opened_at_ms: listed.last_opened_at_ms,
        cover_thumbnail_path: listed.cover_thumbnail_path,
        warnings,
    })
}
