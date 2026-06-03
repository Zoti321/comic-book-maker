use std::collections::HashSet;
use std::path::PathBuf;

use rusqlite::{params, TransactionBehavior};
use uuid::Uuid;

use crate::page_image::{
    absolute_asset_path, asset_file_name, normalize_extension, relative_asset_path,
};
use crate::paths::{ensure_project_storage, project_assets_dir, project_storage_dir};

use super::library::{now_ms, Library};
use super::records::PageRecord;

impl Library {
    pub(crate) fn add_page_images_inner(
        &mut self,
        project_id: &str,
        source_paths: Vec<String>,
    ) -> Result<Vec<PageRecord>, String> {
        if source_paths.is_empty() {
            return Ok(Vec::new());
        }

        if !self.project_exists(project_id)? {
            return Err(format!("project not found: {project_id}"));
        }

        let storage_dir = project_storage_dir(&self.app_data_dir, project_id);
        ensure_project_storage(&storage_dir)?;
        let assets_dir = project_assets_dir(&storage_dir);

        let mut validated_sources = Vec::with_capacity(source_paths.len());
        for source_path in source_paths {
            let path = PathBuf::from(&source_path);
            if !path.is_file() {
                return Err(format!("file not found: {source_path}"));
            }
            let extension = normalize_extension(&path)?;
            validated_sources.push((path, extension));
        }

        let mut next_sort_index = self.next_page_sort_index(project_id)?;
        let now = now_ms();
        let transaction = self
            .connection
            .transaction_with_behavior(TransactionBehavior::Immediate)
            .map_err(|error| format!("begin page insert transaction: {error}"))?;

        let mut inserted = Vec::with_capacity(validated_sources.len());
        for (source_path, extension) in validated_sources {
            let page_id = Uuid::new_v4().to_string();
            let file_name = asset_file_name(&page_id, &extension);
            let asset_path = relative_asset_path(&file_name);
            let destination = assets_dir.join(&file_name);

            std::fs::copy(&source_path, &destination)
                .map_err(|error| format!("copy page image {}: {error}", source_path.display()))?;

            transaction
                .execute(
                    "INSERT INTO pages (id, project_id, sort_index, asset_path)
                     VALUES (?1, ?2, ?3, ?4)",
                    params![page_id, project_id, next_sort_index, asset_path],
                )
                .map_err(|error| format!("insert page: {error}"))?;

            let absolute_path = absolute_asset_path(&storage_dir, &asset_path)
                .to_string_lossy()
                .into_owned();

            inserted.push(PageRecord {
                id: page_id,
                sort_index: next_sort_index,
                asset_path,
                absolute_path,
            });
            next_sort_index += 1;
        }

        transaction
            .execute(
                "UPDATE projects SET updated_at_ms = ?1 WHERE id = ?2",
                params![now, project_id],
            )
            .map_err(|error| format!("update project timestamp: {error}"))?;

        transaction
            .commit()
            .map_err(|error| format!("commit page insert transaction: {error}"))?;

        self.refresh_cover_thumbnail(project_id)?;

        Ok(inserted)
    }

    pub(crate) fn list_pages_inner(&self, project_id: &str) -> Result<Vec<PageRecord>, String> {
        if !self.project_exists(project_id)? {
            return Err(format!("project not found: {project_id}"));
        }

        let storage_dir = project_storage_dir(&self.app_data_dir, project_id);
        let mut statement = self
            .connection
            .prepare(
                "SELECT id, sort_index, asset_path
                 FROM pages
                 WHERE project_id = ?1
                 ORDER BY sort_index ASC",
            )
            .map_err(|error| format!("prepare list pages: {error}"))?;

        let rows = statement
            .query_map(params![project_id], |row| {
                let id: String = row.get(0)?;
                let sort_index: i32 = row.get(1)?;
                let asset_path: String = row.get(2)?;
                let absolute_path = absolute_asset_path(&storage_dir, &asset_path)
                    .to_string_lossy()
                    .into_owned();

                Ok(PageRecord {
                    id,
                    sort_index,
                    asset_path,
                    absolute_path,
                })
            })
            .map_err(|error| format!("query pages: {error}"))?;

        rows.collect::<Result<Vec<_>, _>>()
            .map_err(|error| format!("collect pages: {error}"))
    }

    pub(crate) fn delete_page_inner(&mut self, project_id: &str, page_id: &str) -> Result<(), String> {
        if !self.project_exists(project_id)? {
            return Err(format!("project not found: {project_id}"));
        }

        let storage_dir = project_storage_dir(&self.app_data_dir, project_id);
        let (removed_sort_index, asset_path) = self.page_asset(project_id, page_id)?;

        let asset_file = storage_dir.join(&asset_path);
        if asset_file.is_file() {
            std::fs::remove_file(&asset_file)
                .map_err(|error| format!("delete page asset {}: {error}", asset_file.display()))?;
        }

        let deleted = self
            .connection
            .execute(
                "DELETE FROM pages WHERE project_id = ?1 AND id = ?2",
                params![project_id, page_id],
            )
            .map_err(|error| format!("delete page: {error}"))?;

        if deleted == 0 {
            return Err(format!("page not found: {page_id}"));
        }

        self.renormalize_page_sort_indices(project_id)?;
        self.adjust_cover_after_page_removed(project_id, removed_sort_index)?;
        self.touch_project_updated(project_id)?;
        self.refresh_cover_thumbnail(project_id)?;

        Ok(())
    }

    pub(crate) fn replace_page_image_inner(
        &mut self,
        project_id: &str,
        page_id: &str,
        source_path: String,
    ) -> Result<PageRecord, String> {
        if !self.project_exists(project_id)? {
            return Err(format!("project not found: {project_id}"));
        }

        let source = PathBuf::from(&source_path);
        if !source.is_file() {
            return Err(format!("file not found: {source_path}"));
        }
        let extension = normalize_extension(&source)?;

        let storage_dir = project_storage_dir(&self.app_data_dir, project_id);
        ensure_project_storage(&storage_dir)?;
        let assets_dir = project_assets_dir(&storage_dir);

        let (sort_index, old_asset_path) = self.page_asset(project_id, page_id)?;
        let old_asset_file = storage_dir.join(&old_asset_path);

        let file_name = asset_file_name(page_id, &extension);
        let new_asset_path = relative_asset_path(&file_name);
        let destination = assets_dir.join(&file_name);

        std::fs::copy(&source, &destination)
            .map_err(|error| format!("copy replacement page image: {error}"))?;

        if old_asset_file != destination && old_asset_file.is_file() {
            std::fs::remove_file(&old_asset_file)
                .map_err(|error| format!("delete replaced page asset: {error}"))?;
        }

        self.connection
            .execute(
                "UPDATE pages SET asset_path = ?1 WHERE project_id = ?2 AND id = ?3",
                params![new_asset_path, project_id, page_id],
            )
            .map_err(|error| format!("update page asset reference: {error}"))?;

        self.touch_project_updated(project_id)?;
        self.refresh_cover_thumbnail(project_id)?;

        Ok(PageRecord {
            id: page_id.to_string(),
            sort_index,
            asset_path: new_asset_path.clone(),
            absolute_path: absolute_asset_path(&storage_dir, &new_asset_path)
                .to_string_lossy()
                .into_owned(),
        })
    }

    pub(crate) fn reorder_pages_inner(
        &mut self,
        project_id: &str,
        ordered_page_ids: Vec<String>,
    ) -> Result<Vec<PageRecord>, String> {
        if !self.project_exists(project_id)? {
            return Err(format!("project not found: {project_id}"));
        }

        let current_pages = self.list_pages_inner(project_id)?;
        if ordered_page_ids.len() != current_pages.len() {
            return Err("page order must include every page exactly once".to_string());
        }

        let current_ids: HashSet<_> = current_pages.iter().map(|page| page.id.as_str()).collect();
        let ordered_ids: HashSet<_> = ordered_page_ids.iter().map(String::as_str).collect();
        if current_ids != ordered_ids {
            return Err("page order must include every page exactly once".to_string());
        }

        let cover_page_id = self.cover_page_id(project_id)?;

        let transaction = self
            .connection
            .transaction_with_behavior(TransactionBehavior::Immediate)
            .map_err(|error| format!("begin reorder transaction: {error}"))?;

        transaction
            .execute(
                "UPDATE pages SET sort_index = sort_index + 100000 WHERE project_id = ?1",
                params![project_id],
            )
            .map_err(|error| format!("stage page reorder: {error}"))?;

        for (sort_index, page_id) in ordered_page_ids.iter().enumerate() {
            let updated = transaction
                .execute(
                    "UPDATE pages SET sort_index = ?1 WHERE project_id = ?2 AND id = ?3",
                    params![sort_index as i32, project_id, page_id],
                )
                .map_err(|error| format!("update page sort index: {error}"))?;

            if updated == 0 {
                return Err(format!("page not found in project: {page_id}"));
            }
        }

        if let Some(cover_page_id) = cover_page_id {
            let new_cover_index = ordered_page_ids
                .iter()
                .position(|page_id| page_id == &cover_page_id)
                .unwrap_or(0) as i32;
            transaction
                .execute(
                    "UPDATE projects SET cover_page_index = ?1 WHERE id = ?2",
                    params![new_cover_index, project_id],
                )
                .map_err(|error| format!("update cover page index: {error}"))?;
        }

        let now = now_ms();
        transaction
            .execute(
                "UPDATE projects SET updated_at_ms = ?1 WHERE id = ?2",
                params![now, project_id],
            )
            .map_err(|error| format!("update project timestamp: {error}"))?;

        transaction
            .commit()
            .map_err(|error| format!("commit reorder transaction: {error}"))?;

        self.refresh_cover_thumbnail(project_id)?;

        self.list_pages_inner(project_id)
    }

    pub(crate) fn next_page_sort_index(&self, project_id: &str) -> Result<i32, String> {
        self.connection
            .query_row(
                "SELECT COALESCE(MAX(sort_index), -1) + 1 FROM pages WHERE project_id = ?1",
                params![project_id],
                |row| row.get(0),
            )
            .map_err(|error| format!("query next page sort index: {error}"))
    }

    fn page_asset(&self, project_id: &str, page_id: &str) -> Result<(i32, String), String> {
        self.connection
            .query_row(
                "SELECT sort_index, asset_path FROM pages WHERE project_id = ?1 AND id = ?2",
                params![project_id, page_id],
                |row| Ok((row.get(0)?, row.get(1)?)),
            )
            .map_err(|error| format!("load page asset: {error}"))
    }

    fn renormalize_page_sort_indices(&mut self, project_id: &str) -> Result<(), String> {
        let page_ids = self.list_page_ids(project_id)?;
        for (sort_index, page_id) in page_ids.iter().enumerate() {
            self.connection
                .execute(
                    "UPDATE pages SET sort_index = ?1 WHERE project_id = ?2 AND id = ?3",
                    params![sort_index as i32, project_id, page_id],
                )
                .map_err(|error| format!("renormalize page sort index: {error}"))?;
        }
        Ok(())
    }

    pub(crate) fn list_page_ids(&self, project_id: &str) -> Result<Vec<String>, String> {
        let mut statement = self
            .connection
            .prepare("SELECT id FROM pages WHERE project_id = ?1 ORDER BY sort_index ASC")
            .map_err(|error| format!("prepare page ids: {error}"))?;

        let rows = statement
            .query_map(params![project_id], |row| row.get(0))
            .map_err(|error| format!("query page ids: {error}"))?;

        rows.collect::<Result<Vec<_>, _>>()
            .map_err(|error| format!("collect page ids: {error}"))
    }
}
