use crate::project_format::{ExportFormat, InferredImportKind};
use crate::project_workflow::ComicArchiveContainer;

#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct ProjectRecord {
    pub id: String,
    pub title: String,
    pub updated_at_ms: i64,
    pub cover_thumbnail_path: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct ProjectSettingsRecord {
    pub export_format: ExportFormat,
    pub inferred_import_kind: InferredImportKind,
    pub delete_project_after_export: bool,
    pub use_default_export_directory: bool,
    pub export_directory: Option<String>,
    pub comic_archive_container: ComicArchiveContainer,
    pub use_comic_archive_extension: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct ProjectSettingsPatch {
    pub export_format: ExportFormat,
    pub delete_project_after_export: bool,
    pub use_default_export_directory: bool,
    pub export_directory: Option<String>,
    pub comic_archive_container: ComicArchiveContainer,
    pub use_comic_archive_extension: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub(crate) struct PageRecord {
    pub id: String,
    pub sort_index: i32,
    pub asset_path: String,
    pub absolute_path: String,
}
