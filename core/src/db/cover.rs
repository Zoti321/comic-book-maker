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

    pub(crate) fn load_cover_page_index(&self, project_id: &str) -> Result<i32, String> {
        self.connection
            .query_row(
                "SELECT cover_page_index FROM projects WHERE id = ?1",
                params![project_id],
                |row| row.get(0),
            )
            .map_err(|error| format!("load cover page index: {error}"))
    }

    /// 原子设置 [Cover](CONTEXT.md)：`cover_page_index` 持久化并刷新 Cover Thumbnail。
    pub(crate) fn set_cover_page_inner(
        &mut self,
        project_id: &str,
        cover_page_index: i32,
    ) -> Result<i32, String> {
        if !self.project_exists(project_id)? {
            return Err(format!("project not found: {project_id}"));
        }

        let page_count = self.page_count(project_id)?;
        if page_count == 0 {
            if cover_page_index != 0 {
                return Err("cover_page_index must be 0 when project has no pages".to_string());
            }
        } else if cover_page_index < 0 || cover_page_index >= page_count {
            return Err(format!(
                "cover_page_index must be between 0 and {}",
                page_count - 1
            ));
        } else {
            let page_exists = self
                .connection
                .query_row(
                    "SELECT 1 FROM pages WHERE project_id = ?1 AND sort_index = ?2",
                    params![project_id, cover_page_index],
                    |_| Ok(()),
                )
                .is_ok();
            if !page_exists {
                return Err(format!("no page at sort_index {cover_page_index}"));
            }
        }

        let now = super::library::now_ms();
        self.connection
            .execute(
                "UPDATE projects SET cover_page_index = ?1, updated_at_ms = ?2 WHERE id = ?3",
                params![cover_page_index, now, project_id],
            )
            .map_err(|error| format!("update cover page index: {error}"))?;

        self.refresh_cover_thumbnail(project_id)?;
        Ok(cover_page_index)
    }

    fn cover_page_asset_path(&self, project_id: &str) -> Result<Option<String>, String> {
        let page_count = self.page_count(project_id)?;
        if page_count == 0 {
            return Ok(None);
        }

        let cover_index = self.load_cover_page_index(project_id)?;
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

#[cfg(test)]
mod tests {
    use crate::cover_thumbnail::COVER_THUMBNAIL_FILE;
    use crate::db::library::Library;
    use crate::paths::{project_cache_dir, project_storage_dir};
    use image::{ImageBuffer, Rgba};
    use std::fs;
    use std::time::{SystemTime, UNIX_EPOCH};

    fn temp_dir(label: &str) -> std::path::PathBuf {
        let nanos = SystemTime::now()
            .duration_since(UNIX_EPOCH)
            .expect("clock")
            .as_nanos();
        std::env::temp_dir().join(format!("cbm-cover-{label}-{nanos}"))
    }

    fn write_test_png(dir: &std::path::Path, name: &str) -> std::path::PathBuf {
        fs::create_dir_all(dir).expect("create dir");
        let path = dir.join(name);
        let img = ImageBuffer::from_fn(32, 48, |_, _| Rgba([80u8, 140, 220, 255]));
        img.save(&path).expect("save test png");
        path
    }

    #[test]
    fn set_cover_page_updates_index_and_thumbnail() {
        let app_data = temp_dir("set-cover");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let project = library.create_project_inner(None).expect("create project");
        let fixtures = temp_dir("set-cover-fixtures");
        let first = write_test_png(&fixtures, "one.png");
        let second = write_test_png(&fixtures, "two.png");

        library
            .add_page_images_inner(
                &project.id,
                vec![
                    first.to_string_lossy().into_owned(),
                    second.to_string_lossy().into_owned(),
                ],
            )
            .expect("add pages");

        let updated = library
            .set_cover_page_inner(&project.id, 1)
            .expect("set cover");
        assert_eq!(updated, 1);
        assert_eq!(
            library.load_cover_page_index(&project.id).expect("load"),
            1
        );

        let storage = project_storage_dir(&app_data, &project.id);
        let thumb_path = project_cache_dir(&storage).join(COVER_THUMBNAIL_FILE);
        assert!(thumb_path.is_file(), "thumbnail should exist after cover change");
    }
}
