use rusqlite::{Connection, OptionalExtension};

pub fn migrate(connection: &Connection) -> Result<(), String> {
    migrate_legacy_columns(connection)?;
    migrate_comicinfo_columns(connection)?;
    migrate_library_shell_columns(connection)?;
    migrate_project_format_columns(connection)?;
    migrate_project_workflow_columns(connection)?;
    copy_legacy_metadata(connection)?;
    migrate_canonical_metadata(connection)?;
    migrate_project_display_title(connection)?;
    Ok(())
}

fn migrate_project_display_title(connection: &Connection) -> Result<(), String> {
    add_column_if_missing(connection, "project_title", "TEXT")?;
    connection
        .execute(
            "UPDATE projects SET project_title = title
             WHERE project_title IS NULL OR project_title = ''",
            [],
        )
        .map_err(|error| format!("backfill project_title: {error}"))?;
    Ok(())
}

fn migrate_comicinfo_columns(connection: &Connection) -> Result<(), String> {
    if column_exists(connection, "number")? {
        return Ok(());
    }

    let columns = [
        ("series", "TEXT"),
        ("issue_number", "TEXT"),
        ("series_count", "TEXT"),
        ("volume", "TEXT"),
        ("alternate_series", "TEXT"),
        ("alternate_number", "TEXT"),
        ("alternate_count", "TEXT"),
        ("summary", "TEXT"),
        ("notes", "TEXT"),
        ("year", "INTEGER"),
        ("month", "INTEGER"),
        ("day", "INTEGER"),
        ("writer", "TEXT"),
        ("penciller", "TEXT"),
        ("inker", "TEXT"),
        ("colorist", "TEXT"),
        ("letterer", "TEXT"),
        ("cover_artist", "TEXT"),
        ("editor", "TEXT"),
        ("translator", "TEXT"),
        ("publisher", "TEXT"),
        ("imprint", "TEXT"),
        ("genre", "TEXT"),
        ("tags", "TEXT"),
        ("web", "TEXT"),
        ("language_iso", "TEXT"),
        ("format", "TEXT"),
        ("black_and_white", "TEXT"),
        ("manga", "TEXT"),
        ("characters", "TEXT"),
        ("teams", "TEXT"),
        ("locations", "TEXT"),
        ("main_character_or_team", "TEXT"),
        ("scan_information", "TEXT"),
        ("story_arc", "TEXT"),
        ("story_arc_number", "TEXT"),
        ("series_group", "TEXT"),
        ("age_rating", "TEXT"),
        ("community_rating", "TEXT"),
        ("review", "TEXT"),
        ("gtin", "TEXT"),
    ];

    for (name, kind) in columns {
        add_column_if_missing(connection, name, kind)?;
    }

    Ok(())
}

fn migrate_legacy_columns(connection: &Connection) -> Result<(), String> {
    let legacy_columns = [
        ("series_name", "TEXT"),
        ("volume_number", "TEXT"),
        ("author", "TEXT"),
        ("publication_date", "TEXT"),
        ("language", "TEXT"),
    ];

    for (name, kind) in legacy_columns {
        add_column_if_missing(connection, name, kind)?;
    }

    Ok(())
}

fn migrate_library_shell_columns(connection: &Connection) -> Result<(), String> {
    add_column_if_missing(connection, "last_opened_at_ms", "INTEGER")
}

fn migrate_project_format_columns(connection: &Connection) -> Result<(), String> {
    add_column_if_missing(
        connection,
        "export_format",
        "TEXT NOT NULL DEFAULT 'comic_archive'",
    )?;
    add_column_if_missing(
        connection,
        "inferred_import_kind",
        "TEXT NOT NULL DEFAULT 'images'",
    )?;
    Ok(())
}

fn migrate_project_workflow_columns(connection: &Connection) -> Result<(), String> {
    add_column_if_missing(
        connection,
        "delete_project_after_export",
        "INTEGER NOT NULL DEFAULT 0",
    )?;
    add_column_if_missing(
        connection,
        "use_default_export_directory",
        "INTEGER NOT NULL DEFAULT 1",
    )?;
    add_column_if_missing(connection, "export_directory", "TEXT")?;
    add_column_if_missing(
        connection,
        "comic_archive_container",
        "TEXT NOT NULL DEFAULT 'zip'",
    )?;
    add_column_if_missing(
        connection,
        "use_comic_archive_extension",
        "INTEGER NOT NULL DEFAULT 1",
    )?;
    Ok(())
}

fn copy_legacy_metadata(connection: &Connection) -> Result<(), String> {
    if column_exists(connection, "number")? {
        return Ok(());
    }

    if column_exists(connection, "series_name")? {
        connection
            .execute_batch(
                "
                UPDATE projects SET series = series_name
                WHERE (series IS NULL OR series = '') AND series_name IS NOT NULL;

                UPDATE projects SET volume = volume_number
                WHERE (volume IS NULL OR volume = '') AND volume_number IS NOT NULL;

                UPDATE projects SET writer = author
                WHERE (writer IS NULL OR writer = '') AND author IS NOT NULL;

                UPDATE projects SET language_iso = language
                WHERE (language_iso IS NULL OR language_iso = '') AND language IS NOT NULL;
                ",
            )
            .map_err(|error| format!("copy legacy metadata: {error}"))?;
    }

    Ok(())
}

fn migrate_canonical_metadata(connection: &Connection) -> Result<(), String> {
    if column_exists(connection, "number")? {
        return Ok(());
    }

    if !column_exists(connection, "issue_number")? {
        add_canonical_columns(connection)?;
        return Ok(());
    }

    let published_date_expr = published_date_migration_expr(connection)?;
    let author_expr = author_migration_expr(connection)?;

    connection
        .execute_batch(
            &format!(
                "
                CREATE TABLE projects_canonical (
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

                INSERT INTO projects_canonical (
                    id, title, series, number, series_count, published_date,
                    language_iso, author, tags, characters, age_rating, description,
                    cover_page_index, export_format, inferred_import_kind,
                    delete_project_after_export, use_default_export_directory,
                    export_directory, comic_archive_container, use_comic_archive_extension,
                    created_at_ms, updated_at_ms, last_opened_at_ms
                )
                SELECT
                    id,
                    title,
                    series,
                    issue_number,
                    series_count,
                    {published_date_expr},
                    language_iso,
                    {author_expr},
                    tags,
                    characters,
                    age_rating,
                    summary,
                    cover_page_index,
                    export_format,
                    inferred_import_kind,
                    delete_project_after_export,
                    use_default_export_directory,
                    export_directory,
                    comic_archive_container,
                    use_comic_archive_extension,
                    created_at_ms,
                    updated_at_ms,
                    last_opened_at_ms
                FROM projects;

                DROP TABLE projects;
                ALTER TABLE projects_canonical RENAME TO projects;
                "
            ),
        )
        .map_err(|error| format!("migrate canonical metadata: {error}"))?;

    Ok(())
}

fn add_canonical_columns(connection: &Connection) -> Result<(), String> {
    let columns = [
        ("number", "TEXT"),
        ("published_date", "TEXT"),
        ("author", "TEXT"),
        ("description", "TEXT"),
    ];

    for (name, kind) in columns {
        add_column_if_missing(connection, name, kind)?;
    }

    Ok(())
}

fn published_date_migration_expr(connection: &Connection) -> Result<String, String> {
    if column_exists(connection, "year")? {
        let when_year_null = if column_exists(connection, "publication_date")? {
            "CASE WHEN publication_date IS NOT NULL AND TRIM(publication_date) != '' THEN TRIM(publication_date) ELSE NULL END"
        } else {
            "NULL"
        };
        Ok(format!(
            "CASE
                    WHEN year IS NULL THEN {when_year_null}
                    WHEN month IS NULL THEN CAST(year AS TEXT)
                    WHEN day IS NULL THEN printf('%04d-%02d', year, month)
                    ELSE printf('%04d-%02d-%02d', year, month, day)
                 END"
        ))
    } else if column_exists(connection, "publication_date")? {
        Ok(
            "CASE
                WHEN publication_date IS NOT NULL AND TRIM(publication_date) != '' THEN TRIM(publication_date)
                ELSE NULL
             END"
                .to_string(),
        )
    } else {
        Ok("NULL".to_string())
    }
}

fn author_migration_expr(connection: &Connection) -> Result<String, String> {
    let has_writer = column_exists(connection, "writer")?;
    let has_legacy_author = column_exists(connection, "author")?;

    match (has_writer, has_legacy_author) {
        (true, true) => Ok(
            "COALESCE(NULLIF(TRIM(writer), ''), NULLIF(TRIM(author), ''))".to_string(),
        ),
        (true, false) => Ok("writer".to_string()),
        (false, true) => Ok("author".to_string()),
        (false, false) => Ok("NULL".to_string()),
    }
}

fn add_column_if_missing(
    connection: &Connection,
    name: &str,
    kind: &str,
) -> Result<(), String> {
    if column_exists(connection, name)? {
        return Ok(());
    }

    let sql = format!("ALTER TABLE projects ADD COLUMN {name} {kind}");
    connection
        .execute(&sql, [])
        .map_err(|error| format!("add column {name}: {error}"))?;
    Ok(())
}

fn column_exists(connection: &Connection, name: &str) -> Result<bool, String> {
    connection
        .prepare("SELECT 1 FROM pragma_table_info('projects') WHERE name = ?1")
        .map_err(|error| format!("prepare table info: {error}"))?
        .query_row([name], |_| Ok(()))
        .optional()
        .map(|value| value.is_some())
        .map_err(|error| format!("query table info: {error}"))
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::published_date::merge_year_month_day;
    use rusqlite::Connection;

    fn create_legacy_projects_table(connection: &Connection) {
        connection
            .execute_batch(
                "CREATE TABLE projects (
                    id TEXT PRIMARY KEY NOT NULL,
                    title TEXT NOT NULL,
                    series_name TEXT,
                    author TEXT,
                    cover_page_index INTEGER NOT NULL DEFAULT 0,
                    created_at_ms INTEGER NOT NULL,
                    updated_at_ms INTEGER NOT NULL
                );",
            )
            .expect("create legacy table");
    }

    #[test]
    fn migrate_adds_workflow_columns_on_legacy_db() {
        let connection = Connection::open_in_memory().expect("open memory db");
        create_legacy_projects_table(&connection);

        migrate(&connection).expect("migrate");

        assert!(column_exists(&connection, "number").expect("check number"));
        assert!(column_exists(&connection, "published_date").expect("check published_date"));
        assert!(column_exists(&connection, "author").expect("check author"));
        assert!(
            column_exists(&connection, "delete_project_after_export")
                .expect("check delete after export")
        );
        assert!(!column_exists(&connection, "issue_number").expect("check issue_number removed"));
        assert!(!column_exists(&connection, "writer").expect("check writer removed"));
    }

    #[test]
    fn migrate_renames_and_merges_metadata_columns() {
        let connection = Connection::open_in_memory().expect("open memory db");
        connection
            .execute_batch(
                "CREATE TABLE projects (
                    id TEXT PRIMARY KEY NOT NULL,
                    title TEXT NOT NULL,
                    series TEXT,
                    issue_number TEXT,
                    series_count TEXT,
                    summary TEXT,
                    year INTEGER,
                    month INTEGER,
                    day INTEGER,
                    writer TEXT,
                    language_iso TEXT,
                    tags TEXT,
                    characters TEXT,
                    age_rating TEXT,
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
                );",
            )
            .expect("create comicinfo table");

        connection
            .execute(
                "INSERT INTO projects (
                    id, title, series, issue_number, series_count, summary,
                    year, month, day, writer, language_iso, cover_page_index,
                    created_at_ms, updated_at_ms
                 ) VALUES (
                    'p1', 'Title', 'Series', '7', '12', 'Summary text',
                    2024, 5, NULL, 'Alice', 'zh-CN', 0, 1, 1
                 )",
                [],
            )
            .expect("insert project");

        migrate_canonical_metadata(&connection).expect("migrate canonical");

        let (number, published_date, author, description): (Option<String>, Option<String>, Option<String>, Option<String>) =
            connection
                .query_row(
                    "SELECT number, published_date, author, description FROM projects WHERE id = 'p1'",
                    [],
                    |row| Ok((row.get(0)?, row.get(1)?, row.get(2)?, row.get(3)?)),
                )
                .expect("load migrated row");

        assert_eq!(number.as_deref(), Some("7"));
        assert_eq!(published_date.as_deref(), Some("2024-05"));
        assert_eq!(author.as_deref(), Some("Alice"));
        assert_eq!(description.as_deref(), Some("Summary text"));
    }

    #[test]
    fn merge_year_month_day_matches_migration_rules() {
        assert_eq!(
            merge_year_month_day(Some(2024), None, None).as_deref(),
            Some("2024")
        );
        assert_eq!(
            merge_year_month_day(Some(2024), Some(5), None).as_deref(),
            Some("2024-05")
        );
        assert_eq!(
            merge_year_month_day(Some(2024), Some(5), Some(31)).as_deref(),
            Some("2024-05-31")
        );
    }
}
