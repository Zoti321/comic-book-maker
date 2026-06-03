//! Shared outcome types for archive import.

pub struct ImportArchiveOutcome {
    pub project_id: String,
    pub title: String,
    pub updated_at_ms: i64,
    pub cover_thumbnail_path: Option<String>,
    pub warnings: Vec<String>,
}

pub struct AppendImportOutcome {
    pub warnings: Vec<String>,
    pub added_page_count: i32,
}

/// Page written to disk during import; database rows are committed in one transaction.
pub struct StagedImportPage {
    pub page_id: String,
    pub sort_index: i32,
    pub asset_path: String,
}
