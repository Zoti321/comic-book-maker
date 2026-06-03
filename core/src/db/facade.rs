//! Static entry points delegating to a process-wide [`Library`] instance.

use super::library::Library;
use super::metadata::MetadataRecord;
use super::records::{PageRecord, ProjectRecord, ProjectSettingsPatch, ProjectSettingsRecord};
use crate::import_metadata_snapshot::ImportMetadataSnapshot;
use crate::project_format::{ExportFormat, InferredImportKind};

impl Library {
    pub(crate) fn create_project(title: Option<String>) -> Result<ProjectRecord, String> {
        Self::with_library(|library| library.create_project_inner(title))
    }

    pub(crate) fn list_projects() -> Result<Vec<ProjectRecord>, String> {
        Self::with_library(|library| library.list_projects_inner())
    }

    pub(crate) fn touch_project(project_id: &str) -> Result<(), String> {
        Self::with_library(|library| library.touch_project_inner(project_id))
    }

    pub(crate) fn add_page_images(
        project_id: &str,
        source_paths: Vec<String>,
    ) -> Result<Vec<PageRecord>, String> {
        Self::with_library(|library| library.add_page_images_inner(project_id, source_paths))
    }

    pub(crate) fn list_pages(project_id: &str) -> Result<Vec<PageRecord>, String> {
        Self::with_library(|library| library.list_pages_inner(project_id))
    }

    pub(crate) fn delete_page(project_id: &str, page_id: &str) -> Result<(), String> {
        Self::with_library(|library| library.delete_page_inner(project_id, page_id))
    }

    pub(crate) fn replace_page_image(
        project_id: &str,
        page_id: &str,
        source_path: String,
    ) -> Result<PageRecord, String> {
        Self::with_library(|library| {
            library.replace_page_image_inner(project_id, page_id, source_path)
        })
    }

    pub(crate) fn reorder_pages(
        project_id: &str,
        ordered_page_ids: Vec<String>,
    ) -> Result<Vec<PageRecord>, String> {
        Self::with_library(|library| library.reorder_pages_inner(project_id, ordered_page_ids))
    }

    pub(crate) fn get_project_metadata(project_id: &str) -> Result<MetadataRecord, String> {
        Self::with_library(|library| library.get_project_metadata_inner(project_id))
    }

    pub(crate) fn get_project_settings(
        project_id: &str,
    ) -> Result<ProjectSettingsRecord, String> {
        Self::with_library(|library| library.get_project_settings_inner(project_id))
    }

    pub(crate) fn update_project_export_format(
        project_id: &str,
        export_format: ExportFormat,
    ) -> Result<ProjectSettingsRecord, String> {
        Self::with_library(|library| {
            library.update_project_export_format_inner(project_id, export_format)
        })
    }

    pub(crate) fn update_project_settings(
        project_id: &str,
        patch: ProjectSettingsPatch,
    ) -> Result<ProjectSettingsRecord, String> {
        Self::with_library(|library| library.update_project_settings_inner(project_id, patch))
    }

    pub(crate) fn change_inferred_import_kind(
        project_id: &str,
        inferred_import_kind: InferredImportKind,
    ) -> Result<ProjectSettingsRecord, String> {
        Self::with_library(|library| {
            library.change_inferred_import_kind_inner(project_id, inferred_import_kind)
        })
    }

    pub(crate) fn get_import_metadata_snapshot(
        project_id: &str,
    ) -> Result<ImportMetadataSnapshot, String> {
        Self::with_library(|library| library.get_import_metadata_snapshot_inner(project_id))
    }

    pub(crate) fn update_project_metadata(
        project_id: &str,
        metadata: MetadataRecord,
    ) -> Result<MetadataRecord, String> {
        Self::with_library(|library| library.update_project_metadata_inner(project_id, metadata))
    }

    pub(crate) fn import_cbz(
        source_path: &str,
    ) -> Result<crate::import_cbz::ImportCbzOutcome, String> {
        Self::with_library(|library| crate::import_cbz::import_cbz(library, source_path))
    }

    pub(crate) fn import_cbr(
        source_path: &str,
    ) -> Result<crate::import_shared::ImportArchiveOutcome, String> {
        Self::with_library(|library| crate::import_cbr::import_cbr(library, source_path))
    }

    pub(crate) fn import_epub(
        source_path: &str,
    ) -> Result<crate::import_shared::ImportArchiveOutcome, String> {
        Self::with_library(|library| crate::import_epub::import_epub(library, source_path))
    }

    pub(crate) fn export_cbz(
        project_id: &str,
        destination_path: &str,
        delete_project_after_export: bool,
    ) -> Result<(), String> {
        Self::with_library(|library| {
            crate::export_cbz::export_cbz(library, project_id, destination_path)?;
            if delete_project_after_export {
                library.delete_project_inner(project_id)?;
            }
            Ok(())
        })
    }

    pub(crate) fn export_epub(
        project_id: &str,
        destination_path: &str,
        delete_project_after_export: bool,
    ) -> Result<(), String> {
        Self::with_library(|library| {
            crate::export_epub::export_epub(library, project_id, destination_path)?;
            if delete_project_after_export {
                library.delete_project_inner(project_id)?;
            }
            Ok(())
        })
    }

    pub(crate) fn append_cbz(
        project_id: &str,
        source_path: &str,
    ) -> Result<crate::import_shared::AppendImportOutcome, String> {
        Self::with_library(|library| {
            crate::import_cbz::append_cbz(library, project_id, source_path)
        })
    }

    pub(crate) fn append_cbr(
        project_id: &str,
        source_path: &str,
    ) -> Result<crate::import_shared::AppendImportOutcome, String> {
        Self::with_library(|library| {
            crate::import_cbr::append_cbr(library, project_id, source_path)
        })
    }

    pub(crate) fn append_epub(
        project_id: &str,
        source_path: &str,
    ) -> Result<crate::import_shared::AppendImportOutcome, String> {
        Self::with_library(|library| {
            crate::import_epub::append_epub(library, project_id, source_path)
        })
    }

    pub(crate) fn delete_project(project_id: &str) -> Result<(), String> {
        Self::with_library(|library| library.delete_project_inner(project_id))
    }
}
