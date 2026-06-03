use rusqlite::params;
use uuid::Uuid;

use crate::cover_thumbnail::cover_thumbnail_absolute_path;
use crate::paths::{ensure_project_storage, project_storage_dir, projects_root};
use crate::project_format::{ExportFormat, InferredImportKind};
use crate::project_workflow::{ComicArchiveContainer, ProjectWorkflowDefaults};

use super::library::{now_ms, Library};
use super::metadata::{get_metadata, normalize_metadata, update_metadata, MetadataRecord};
use super::records::{ProjectRecord, ProjectSettingsPatch, ProjectSettingsRecord};
use super::schema;
use super::storage::{remove_project_storage, restore_staged_project_storage};

fn sqlite_bool(value: i64) -> bool {
    value != 0
}

fn normalize_export_directory(value: Option<String>) -> Option<String> {
    value.and_then(|raw| {
        let trimmed = raw.trim().to_string();
        if trimmed.is_empty() {
            None
        } else {
            Some(trimmed)
        }
    })
}

fn parse_settings_row(row: &rusqlite::Row<'_>) -> Result<ProjectSettingsRecord, String> {
    let export_raw: String = row
        .get(0)
        .map_err(|error| format!("read export_format: {error}"))?;
    let inferred_raw: String = row
        .get(1)
        .map_err(|error| format!("read inferred_import_kind: {error}"))?;
    let delete_after: i64 = row
        .get(2)
        .map_err(|error| format!("read delete_project_after_export: {error}"))?;
    let use_default_dir: i64 = row
        .get(3)
        .map_err(|error| format!("read use_default_export_directory: {error}"))?;
    let export_dir: Option<String> = row
        .get(4)
        .map_err(|error| format!("read export_directory: {error}"))?;
    let container_raw: String = row
        .get(5)
        .map_err(|error| format!("read comic_archive_container: {error}"))?;
    let use_comic_ext: i64 = row
        .get(6)
        .map_err(|error| format!("read use_comic_archive_extension: {error}"))?;

    Ok(ProjectSettingsRecord {
        export_format: ExportFormat::from_db(&export_raw)?,
        inferred_import_kind: InferredImportKind::from_db(&inferred_raw)?,
        delete_project_after_export: sqlite_bool(delete_after),
        use_default_export_directory: sqlite_bool(use_default_dir),
        export_directory: normalize_export_directory(export_dir),
        comic_archive_container: ComicArchiveContainer::from_db(&container_raw)?,
        use_comic_archive_extension: sqlite_bool(use_comic_ext),
    })
}

impl Library {
    pub(crate) fn create_project_for_import(
        &mut self,
        title: String,
        inferred_import_kind: InferredImportKind,
        export_format: ExportFormat,
    ) -> Result<ProjectRecord, String> {
        self.create_project_inner_with_formats(
            Some(title),
            inferred_import_kind,
            export_format,
        )
    }

    pub(crate) fn find_project(&self, project_id: &str) -> Result<ProjectRecord, String> {
        let storage_dir = project_storage_dir(&self.app_data_dir, project_id);
        self.connection
            .query_row(
                "SELECT id, title, updated_at_ms FROM projects WHERE id = ?1",
                params![project_id],
                |row| {
                    Ok(ProjectRecord {
                        id: row.get(0)?,
                        title: row.get(1)?,
                        updated_at_ms: row.get(2)?,
                        cover_thumbnail_path: cover_thumbnail_absolute_path(&storage_dir),
                    })
                },
            )
            .map_err(|error| format!("load project: {error}"))
    }

    pub(crate) fn create_project_inner(
        &mut self,
        title: Option<String>,
    ) -> Result<ProjectRecord, String> {
        self.create_project_inner_with_formats(
            title,
            InferredImportKind::default(),
            ExportFormat::default(),
        )
    }

    fn create_project_inner_with_formats(
        &mut self,
        title: Option<String>,
        inferred_import_kind: InferredImportKind,
        export_format: ExportFormat,
    ) -> Result<ProjectRecord, String> {
        let id = Uuid::new_v4().to_string();
        let now = now_ms();
        let title = title
            .filter(|value| !value.trim().is_empty())
            .unwrap_or_else(|| schema::DEFAULT_PROJECT_TITLE.to_string());

        let storage_dir = project_storage_dir(&self.app_data_dir, &id);
        ensure_project_storage(&storage_dir)?;

        let workflow = ProjectWorkflowDefaults::default();

        self.connection
            .execute(
                "INSERT INTO projects (
                    id, title, cover_page_index, export_format, inferred_import_kind,
                    delete_project_after_export, use_default_export_directory, export_directory,
                    comic_archive_container, use_comic_archive_extension,
                    created_at_ms, updated_at_ms, last_opened_at_ms
                ) VALUES (?1, ?2, 0, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?10, NULL)",
                params![
                    id,
                    title,
                    export_format.as_str(),
                    inferred_import_kind.as_str(),
                    i32::from(workflow.delete_project_after_export),
                    i32::from(workflow.use_default_export_directory),
                    workflow.export_directory,
                    workflow.comic_archive_container.as_str(),
                    i32::from(workflow.use_comic_archive_extension),
                    now,
                ],
            )
            .map_err(|error| format!("insert project: {error}"))?;

        Ok(ProjectRecord {
            id,
            title,
            updated_at_ms: now,
            cover_thumbnail_path: None,
        })
    }

    pub(crate) fn get_project_settings_inner(
        &self,
        project_id: &str,
    ) -> Result<ProjectSettingsRecord, String> {
        self.connection
            .query_row(
                "SELECT export_format, inferred_import_kind,
                        delete_project_after_export, use_default_export_directory,
                        export_directory, comic_archive_container, use_comic_archive_extension
                 FROM projects WHERE id = ?1",
                params![project_id],
                |row| {
                    parse_settings_row(row).map_err(|message| {
                        rusqlite::Error::ToSqlConversionFailure(message.into())
                    })
                },
            )
            .map_err(|error| format!("load project settings: {error}"))
    }

    pub(crate) fn update_project_settings_inner(
        &mut self,
        project_id: &str,
        patch: ProjectSettingsPatch,
    ) -> Result<ProjectSettingsRecord, String> {
        if !self.project_exists(project_id)? {
            return Err(format!("project not found: {project_id}"));
        }

        let export_directory = normalize_export_directory(patch.export_directory);
        let now = now_ms();
        self.connection
            .execute(
                "UPDATE projects SET
                    export_format = ?1,
                    delete_project_after_export = ?2,
                    use_default_export_directory = ?3,
                    export_directory = ?4,
                    comic_archive_container = ?5,
                    use_comic_archive_extension = ?6,
                    updated_at_ms = ?7
                 WHERE id = ?8",
                params![
                    patch.export_format.as_str(),
                    i32::from(patch.delete_project_after_export),
                    i32::from(patch.use_default_export_directory),
                    export_directory,
                    patch.comic_archive_container.as_str(),
                    i32::from(patch.use_comic_archive_extension),
                    now,
                    project_id,
                ],
            )
            .map_err(|error| format!("update project settings: {error}"))?;

        self.get_project_settings_inner(project_id)
    }

    pub(crate) fn update_project_export_format_inner(
        &mut self,
        project_id: &str,
        export_format: ExportFormat,
    ) -> Result<ProjectSettingsRecord, String> {
        let current = self.get_project_settings_inner(project_id)?;
        self.update_project_settings_inner(
            project_id,
            ProjectSettingsPatch {
                export_format,
                delete_project_after_export: current.delete_project_after_export,
                use_default_export_directory: current.use_default_export_directory,
                export_directory: current.export_directory,
                comic_archive_container: current.comic_archive_container,
                use_comic_archive_extension: current.use_comic_archive_extension,
            },
        )
    }

    pub(crate) fn list_projects_inner(&self) -> Result<Vec<ProjectRecord>, String> {
        let mut statement = self
            .connection
            .prepare(
                "SELECT id, title, COALESCE(last_opened_at_ms, updated_at_ms) AS activity_ms
                 FROM projects
                 ORDER BY activity_ms DESC",
            )
            .map_err(|error| format!("prepare list projects: {error}"))?;

        let rows = statement
            .query_map([], |row| {
                let id: String = row.get(0)?;
                let title: String = row.get(1)?;
                let updated_at_ms: i64 = row.get(2)?;
                let storage_dir = project_storage_dir(&self.app_data_dir, &id);
                Ok(ProjectRecord {
                    id,
                    title,
                    updated_at_ms,
                    cover_thumbnail_path: cover_thumbnail_absolute_path(&storage_dir),
                })
            })
            .map_err(|error| format!("query projects: {error}"))?;

        rows.collect::<Result<Vec<_>, _>>()
            .map_err(|error| format!("collect projects: {error}"))
    }

    pub(crate) fn delete_project_inner(&mut self, project_id: &str) -> Result<(), String> {
        if !self.project_exists(project_id)? {
            return Err(format!("project not found: {project_id}"));
        }

        let storage_dir = project_storage_dir(&self.app_data_dir, project_id);
        let staging_parent = projects_root(&self.app_data_dir).join(".delete-staging");
        let staged_dir = staging_parent.join(Uuid::new_v4().to_string());

        let storage_staged = if storage_dir.exists() {
            std::fs::create_dir_all(&staging_parent).map_err(|error| {
                format!("create delete staging dir: {error}")
            })?;
            std::fs::rename(&storage_dir, &staged_dir).map_err(|error| {
                format!(
                    "stage project storage {}: {error}",
                    storage_dir.display()
                )
            })?;
            true
        } else {
            false
        };

        let db_result = self.connection.execute(
            "DELETE FROM projects WHERE id = ?1",
            params![project_id],
        );

        match db_result {
            Ok(0) => {
                if storage_staged {
                    restore_staged_project_storage(&staged_dir, &storage_dir)?;
                }
                Err(format!("project not found: {project_id}"))
            }
            Ok(_) => {
                if storage_staged {
                    remove_project_storage(&staged_dir)?;
                }
                Ok(())
            }
            Err(error) => {
                if storage_staged {
                    let _ = restore_staged_project_storage(&staged_dir, &storage_dir);
                }
                Err(format!("delete project: {error}"))
            }
        }
    }

    pub(crate) fn touch_project_inner(&mut self, project_id: &str) -> Result<(), String> {
        let now = now_ms();
        let updated = self
            .connection
            .execute(
                "UPDATE projects SET last_opened_at_ms = ?1 WHERE id = ?2",
                params![now, project_id],
            )
            .map_err(|error| format!("touch project: {error}"))?;

        if updated == 0 {
            return Err(format!("project not found: {project_id}"));
        }

        Ok(())
    }

    pub(crate) fn get_project_metadata_inner(
        &self,
        project_id: &str,
    ) -> Result<MetadataRecord, String> {
        if !self.project_exists(project_id)? {
            return Err(format!("project not found: {project_id}"));
        }
        let page_count = self.page_count(project_id)?;
        get_metadata(&self.connection, project_id, page_count)
    }

    pub(crate) fn update_project_metadata_inner(
        &mut self,
        project_id: &str,
        metadata: MetadataRecord,
    ) -> Result<MetadataRecord, String> {
        if !self.project_exists(project_id)? {
            return Err(format!("project not found: {project_id}"));
        }
        let page_count = self.page_count(project_id)?;
        let metadata = normalize_metadata(metadata);
        update_metadata(&self.connection, project_id, &metadata, page_count)?;
        self.refresh_cover_thumbnail(project_id)?;
        get_metadata(&self.connection, project_id, page_count)
    }

    pub(crate) fn project_exists(&self, project_id: &str) -> Result<bool, String> {
        self.connection
            .query_row(
                "SELECT COUNT(1) FROM projects WHERE id = ?1",
                params![project_id],
                |row| row.get(0),
            )
            .map_err(|error| format!("check project exists: {error}"))
    }

    pub(crate) fn touch_project_updated(&mut self, project_id: &str) -> Result<(), String> {
        let now = now_ms();
        self.connection
            .execute(
                "UPDATE projects SET updated_at_ms = ?1 WHERE id = ?2",
                params![now, project_id],
            )
            .map_err(|error| format!("update project timestamp: {error}"))?;
        Ok(())
    }

    pub(crate) fn page_count(&self, project_id: &str) -> Result<i32, String> {
        self.connection
            .query_row(
                "SELECT COUNT(1) FROM pages WHERE project_id = ?1",
                params![project_id],
                |row| row.get(0),
            )
            .map_err(|error| format!("count pages: {error}"))
    }
}
