use rusqlite::{Connection, OptionalExtension};

pub fn migrate(connection: &Connection) -> Result<(), String> {
    migrate_legacy_columns(connection)?;
    migrate_comicinfo_columns(connection)?;
    migrate_library_shell_columns(connection)?;
    migrate_project_format_columns(connection)?;
    migrate_project_workflow_columns(connection)?;
    copy_legacy_metadata(connection)?;
    Ok(())
}

fn migrate_comicinfo_columns(connection: &Connection) -> Result<(), String> {
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
    use rusqlite::Connection;

    #[test]
    fn migrate_adds_comicinfo_columns() {
        let connection = Connection::open_in_memory().expect("open memory db");
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

        migrate(&connection).expect("migrate");

        assert!(column_exists(&connection, "writer").expect("check writer"));
        assert!(column_exists(&connection, "language_iso").expect("check language"));
        assert!(column_exists(&connection, "story_arc").expect("check story arc"));
        assert!(
            column_exists(&connection, "last_opened_at_ms").expect("check last opened")
        );
        assert!(
            column_exists(&connection, "export_format").expect("check export format")
        );
        assert!(
            column_exists(&connection, "inferred_import_kind").expect("check inferred import")
        );
        assert!(
            column_exists(&connection, "delete_project_after_export")
                .expect("check delete after export")
        );
        assert!(
            column_exists(&connection, "comic_archive_container")
                .expect("check comic archive container")
        );
    }
}
