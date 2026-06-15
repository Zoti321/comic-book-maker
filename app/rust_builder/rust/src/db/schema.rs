pub const SCHEMA: &str = "
CREATE TABLE IF NOT EXISTS projects (
    id TEXT PRIMARY KEY NOT NULL,
    title TEXT NOT NULL,
    series TEXT,
    number TEXT,
    series_count TEXT,
    published_date TEXT,
    language_iso TEXT,
    author TEXT,
    tags TEXT,
    characters TEXT,
    age_rating TEXT,
    description TEXT,
    cover_page_index INTEGER NOT NULL DEFAULT 0,
    export_format TEXT NOT NULL DEFAULT 'comic_archive',
    inferred_import_kind TEXT NOT NULL DEFAULT 'images',
    delete_project_after_export INTEGER NOT NULL DEFAULT 0,
    use_default_export_directory INTEGER NOT NULL DEFAULT 1,
    export_directory TEXT,
    comic_archive_container TEXT NOT NULL DEFAULT 'zip',
    use_comic_archive_extension INTEGER NOT NULL DEFAULT 1,
    created_at_ms INTEGER NOT NULL,
    updated_at_ms INTEGER NOT NULL,
    last_opened_at_ms INTEGER
);

CREATE TABLE IF NOT EXISTS pages (
    id TEXT PRIMARY KEY NOT NULL,
    project_id TEXT NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    sort_index INTEGER NOT NULL,
    asset_path TEXT NOT NULL,
    UNIQUE(project_id, sort_index)
);

CREATE INDEX IF NOT EXISTS idx_pages_project_sort ON pages(project_id, sort_index);
";

pub const DEFAULT_PROJECT_TITLE: &str = "未命名";
