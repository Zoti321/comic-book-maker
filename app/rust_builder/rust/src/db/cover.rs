use rusqlite::{params, OptionalExtension};

use crate::cover_thumbnail::{
    cover_thumbnail_path, generate_cover_thumbnail, remove_cover_thumbnail,
};
use crate::page_image::absolute_asset_path;
use crate::paths::{ensure_project_storage, project_cache_dir, project_storage_dir};

use super::library::Library;

impl Library {
    pub(crate) fn refresh_cover_thumbnail_for(&self, project_id: &str) -> Result<(), String> {
        self.refresh_cover_thumbnail(project_id)
    }

    pub(crate) fn cover_page_id(&self, project_id: &str) -> Result<Option<String>, String> {
        let cover_index: i32 = self
            .connection
            .query_row(
                "SELECT cover_page_index FROM projects WHERE id = ?1",
                params![project_id],
                |row| row.get(0),
            )
            .map_err(|error| format!("load cover page index: {error}"))?;

        self.connection
            .query_row(
                "SELECT id FROM pages WHERE project_id = ?1 AND sort_index = ?2",
                params![project_id, cover_index],
                |row| row.get(0),
            )
            .optional()
            .map_err(|error| format!("load cover page id: {error}"))
    }

    pub(crate) fn adjust_cover_after_page_removed(
        &mut self,
        project_id: &str,
        removed_sort_index: i32,
    ) -> Result<(), String> {
        let remaining = self.list_page_ids(project_id)?;
        let new_cover_index = if remaining.is_empty() {
            0
        } else {
            let current_cover: i32 = self
                .connection
                .query_row(
                    "SELECT cover_page_index FROM projects WHERE id = ?1",
                    params![project_id],
                    |row| row.get(0),
                )
                .map_err(|error| format!("load cover page index: {error}"))?;

            if current_cover > removed_sort_index {
                current_cover - 1
            } else if current_cover == removed_sort_index {
                current_cover.min(remaining.len() as i32 - 1).max(0)
            } else {
                current_cover
            }
        };

        self.connection
            .execute(
                "UPDATE projects SET cover_page_index = ?1 WHERE id = ?2",
                params![new_cover_index, project_id],
            )
            .map_err(|error| format!("update cover page index: {error}"))?;

        Ok(())
    }

    fn cover_page_index(&self, project_id: &str) -> Result<i32, String> {
        self.connection
            .query_row(
                "SELECT cover_page_index FROM projects WHERE id = ?1",
                params![project_id],
                |row| row.get(0),
            )
            .map_err(|error| format!("load cover page index: {error}"))
    }

    fn cover_page_asset_path(&self, project_id: &str) -> Result<Option<String>, String> {
        let page_count = self.page_count(project_id)?;
        if page_count == 0 {
            return Ok(None);
        }

        let cover_index = self.cover_page_index(project_id)?;
        let index = cover_index.clamp(0, page_count - 1);

        self.connection
            .query_row(
                "SELECT asset_path FROM pages WHERE project_id = ?1 AND sort_index = ?2",
                params![project_id, index],
                |row| row.get(0),
            )
            .optional()
            .map_err(|error| format!("load cover page asset: {error}"))
    }

    pub(crate) fn refresh_cover_thumbnail(&self, project_id: &str) -> Result<(), String> {
        let storage_dir = project_storage_dir(&self.app_data_dir, project_id);
        ensure_project_storage(&storage_dir)?;
        let cache_dir = project_cache_dir(&storage_dir);

        let Some(asset_path) = self.cover_page_asset_path(project_id)? else {
            return remove_cover_thumbnail(&cache_dir);
        };

        let source = absolute_asset_path(&storage_dir, &asset_path);
        let destination = cover_thumbnail_path(&cache_dir);
        generate_cover_thumbnail(&source, &destination)
    }
}
