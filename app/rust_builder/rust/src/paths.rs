use std::path::{Path, PathBuf};

pub fn library_db_path(app_data_dir: &Path) -> PathBuf {
    app_data_dir.join("library.db")
}

pub fn projects_root(app_data_dir: &Path) -> PathBuf {
    app_data_dir.join("projects")
}

pub fn project_storage_dir(app_data_dir: &Path, project_id: &str) -> PathBuf {
    projects_root(app_data_dir).join(project_id)
}

pub fn project_assets_dir(storage_dir: &Path) -> PathBuf {
    storage_dir.join("assets")
}

pub fn project_cache_dir(storage_dir: &Path) -> PathBuf {
    storage_dir.join(".cache")
}

pub const IMPORT_METADATA_XML_FILE: &str = "import-metadata.xml";
pub const IMPORT_METADATA_KIND_FILE: &str = "import-metadata.kind";

pub fn import_metadata_xml_path(storage_dir: &Path) -> PathBuf {
    storage_dir.join(IMPORT_METADATA_XML_FILE)
}

pub fn import_metadata_kind_path(storage_dir: &Path) -> PathBuf {
    storage_dir.join(IMPORT_METADATA_KIND_FILE)
}

pub fn ensure_project_storage(storage_dir: &Path) -> Result<(), String> {
    std::fs::create_dir_all(project_assets_dir(storage_dir))
        .map_err(|error| format!("create assets dir: {error}"))?;
    std::fs::create_dir_all(project_cache_dir(storage_dir))
        .map_err(|error| format!("create cache dir: {error}"))?;
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn project_storage_paths_are_under_app_data() {
        let root = PathBuf::from("/data/app");
        assert_eq!(
            project_storage_dir(&root, "abc"),
            PathBuf::from("/data/app/projects/abc")
        );
        assert_eq!(
            project_assets_dir(&project_storage_dir(&root, "abc")),
            PathBuf::from("/data/app/projects/abc/assets")
        );
    }
}
