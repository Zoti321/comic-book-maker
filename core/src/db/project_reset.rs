//! Clear project content when the user changes inferred import kind.

use rusqlite::params;

use crate::paths::project_storage_dir;
use crate::project_format::InferredImportKind;

use super::library::{now_ms, Library};
use super::metadata::{update_metadata, MetadataRecord};
use super::records::ProjectSettingsRecord;

impl Library {
    pub(crate) fn change_inferred_import_kind_inner(
        &mut self,
        project_id: &str,
        new_kind: InferredImportKind,
    ) -> Result<ProjectSettingsRecord, String> {
        if !self.project_exists(project_id)? {
            return Err(format!("project not found: {project_id}"));
        }

        let current = self.get_project_settings_inner(project_id)?;
        if current.inferred_import_kind == new_kind {
            return Ok(current);
        }

        self.clear_all_pages_inner(project_id)?;

        let title: String = self
            .connection
            .query_row(
                "SELECT title FROM projects WHERE id = ?1",
                params![project_id],
                |row| row.get(0),
            )
            .map_err(|error| format!("load project title: {error}"))?;

        let metadata = MetadataRecord {
            title,
            cover_page_index: 0,
            page_count: 0,
            ..MetadataRecord::default()
        };
        update_metadata(&self.connection, project_id, &metadata, 0)?;

        let now = now_ms();
        self.connection
            .execute(
                "UPDATE projects SET inferred_import_kind = ?1, cover_page_index = 0, updated_at_ms = ?2 WHERE id = ?3",
                params![new_kind.as_str(), now, project_id],
            )
            .map_err(|error| format!("update inferred import kind: {error}"))?;

        self.refresh_cover_thumbnail(project_id)?;

        self.get_project_settings_inner(project_id)
    }

    fn clear_all_pages_inner(&mut self, project_id: &str) -> Result<(), String> {
        let pages = self.list_pages_inner(project_id)?;
        let storage_dir = project_storage_dir(&self.app_data_dir, project_id);

        for page in &pages {
            let asset_file = storage_dir.join(&page.asset_path);
            if asset_file.is_file() {
                std::fs::remove_file(&asset_file).map_err(|error| {
                    format!("delete page asset {}: {error}", asset_file.display())
                })?;
            }
        }

        self.connection
            .execute(
                "DELETE FROM pages WHERE project_id = ?1",
                params![project_id],
            )
            .map_err(|error| format!("delete all pages: {error}"))?;

        Ok(())
    }
}
