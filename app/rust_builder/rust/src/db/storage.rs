use std::path::Path;

pub(crate) fn restore_staged_project_storage(
    staged_dir: &Path,
    storage_dir: &Path,
) -> Result<(), String> {
    if staged_dir.exists() && !storage_dir.exists() {
        std::fs::rename(staged_dir, storage_dir).map_err(|error| {
            format!(
                "restore project storage {}: {error}",
                storage_dir.display()
            )
        })?;
    }
    Ok(())
}

pub(crate) fn remove_project_storage(storage_dir: &Path) -> Result<(), String> {
    if storage_dir.exists() {
        std::fs::remove_dir_all(storage_dir).map_err(|error| {
            format!(
                "remove project storage {}: {error}",
                storage_dir.display()
            )
        })?;
    }
    Ok(())
}
