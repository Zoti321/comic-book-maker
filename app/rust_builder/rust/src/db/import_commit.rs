use rusqlite::{params, TransactionBehavior};

use crate::paths::project_storage_dir;

use super::library::{now_ms, Library};
use super::metadata::{update_metadata, MetadataRecord};
use super::storage::remove_project_storage;

impl Library {
    pub(crate) fn commit_import_project(
        &mut self,
        project_id: &str,
        metadata: &MetadataRecord,
        pages: &[crate::import_shared::StagedImportPage],
    ) -> Result<(), String> {
        let page_count = pages.len() as i32;
        metadata.validate(page_count)?;

        let transaction = self
            .connection
            .transaction_with_behavior(TransactionBehavior::Immediate)
            .map_err(|error| format!("begin import transaction: {error}"))?;

        for page in pages {
            transaction
                .execute(
                    "INSERT INTO pages (id, project_id, sort_index, asset_path)
                     VALUES (?1, ?2, ?3, ?4)",
                    params![page.page_id, project_id, page.sort_index, page.asset_path],
                )
                .map_err(|error| format!("insert imported page: {error}"))?;
        }

        update_metadata(&transaction, project_id, metadata, page_count)?;

        transaction
            .commit()
            .map_err(|error| format!("commit import transaction: {error}"))?;

        Ok(())
    }

    pub(crate) fn commit_append_pages(
        &mut self,
        project_id: &str,
        pages: &[crate::import_shared::StagedImportPage],
    ) -> Result<(), String> {
        if pages.is_empty() {
            return Ok(());
        }

        if !self.project_exists(project_id)? {
            return Err(format!("project not found: {project_id}"));
        }

        let transaction = self
            .connection
            .transaction_with_behavior(TransactionBehavior::Immediate)
            .map_err(|error| format!("begin append import transaction: {error}"))?;

        for page in pages {
            transaction
                .execute(
                    "INSERT INTO pages (id, project_id, sort_index, asset_path)
                     VALUES (?1, ?2, ?3, ?4)",
                    params![page.page_id, project_id, page.sort_index, page.asset_path],
                )
                .map_err(|error| format!("insert appended page: {error}"))?;
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
            .map_err(|error| format!("commit append import transaction: {error}"))?;

        Ok(())
    }

    pub(crate) fn abandon_import_project(&mut self, project_id: &str) -> Result<(), String> {
        let storage_dir = project_storage_dir(&self.app_data_dir, project_id);
        let _ = remove_project_storage(&storage_dir);
        self.connection
            .execute("DELETE FROM projects WHERE id = ?1", params![project_id])
            .map_err(|error| format!("abandon import project: {error}"))?;
        Ok(())
    }
}
