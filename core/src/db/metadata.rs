use rusqlite::{params, Connection, Row};

use crate::published_date::validate_published_date;

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct MetadataRecord {
    pub title: String,
    pub series: Option<String>,
    pub number: Option<String>,
    pub series_count: Option<String>,
    pub published_date: Option<String>,
    pub language_iso: Option<String>,
    pub author: Option<String>,
    pub tags: Option<String>,
    pub characters: Option<String>,
    pub age_rating: Option<String>,
    pub description: Option<String>,
    pub cover_page_index: i32,
    pub page_count: i32,
}

impl MetadataRecord {
    pub fn validate(&self, page_count: i32) -> Result<(), String> {
        if self.title.trim().is_empty() {
            return Err("title must not be empty".to_string());
        }

        if let Some(value) = &self.published_date {
            validate_published_date(value)?;
        }

        if page_count == 0 {
            if self.cover_page_index != 0 {
                return Err("cover_page_index must be 0 when project has no pages".to_string());
            }
        } else if self.cover_page_index < 0 || self.cover_page_index >= page_count {
            return Err(format!(
                "cover_page_index must be between 0 and {}",
                page_count - 1
            ));
        }

        Ok(())
    }
}

pub fn get_metadata(
    connection: &Connection,
    project_id: &str,
    page_count: i32,
) -> Result<MetadataRecord, String> {
    connection
        .query_row(
            "SELECT
                title, series, number, series_count, published_date,
                language_iso, author, tags, characters, age_rating, description,
                cover_page_index
             FROM projects WHERE id = ?1",
            params![project_id],
            |row| metadata_from_row(row, page_count),
        )
        .map_err(|error| format!("load metadata: {error}"))
}

pub fn update_metadata(
    connection: &Connection,
    project_id: &str,
    metadata: &MetadataRecord,
    page_count: i32,
) -> Result<(), String> {
    metadata.validate(page_count)?;

    let updated = connection
        .execute(
            "UPDATE projects SET
                title = ?1,
                series = ?2,
                number = ?3,
                series_count = ?4,
                published_date = ?5,
                language_iso = ?6,
                author = ?7,
                tags = ?8,
                characters = ?9,
                age_rating = ?10,
                description = ?11,
                cover_page_index = ?12,
                updated_at_ms = ?13
             WHERE id = ?14",
            params![
                metadata.title,
                metadata.series,
                metadata.number,
                metadata.series_count,
                metadata.published_date,
                metadata.language_iso,
                metadata.author,
                metadata.tags,
                metadata.characters,
                metadata.age_rating,
                metadata.description,
                metadata.cover_page_index,
                crate::db::now_ms(),
                project_id,
            ],
        )
        .map_err(|error| format!("update metadata: {error}"))?;

    if updated == 0 {
        return Err(format!("project not found: {project_id}"));
    }

    Ok(())
}

fn metadata_from_row(row: &Row<'_>, page_count: i32) -> Result<MetadataRecord, rusqlite::Error> {
    let mut record = MetadataRecord {
        title: row.get(0)?,
        series: row.get(1)?,
        number: row.get(2)?,
        series_count: row.get(3)?,
        published_date: row.get(4)?,
        language_iso: row.get(5)?,
        author: row.get(6)?,
        tags: row.get(7)?,
        characters: row.get(8)?,
        age_rating: row.get(9)?,
        description: row.get(10)?,
        cover_page_index: row.get(11)?,
        page_count,
    };
    record.age_rating = crate::age_rating::normalize(record.age_rating.as_deref());
    Ok(record)
}

fn optional_string(value: Option<String>) -> Option<String> {
    value.and_then(|text| {
        let trimmed = text.trim().to_string();
        if trimmed.is_empty() {
            None
        } else {
            Some(trimmed)
        }
    })
}

pub fn normalize_metadata(mut metadata: MetadataRecord) -> MetadataRecord {
    metadata.title = metadata.title.trim().to_string();
    metadata.series = optional_string(metadata.series);
    metadata.number = optional_string(metadata.number);
    metadata.series_count = optional_string(metadata.series_count);
    metadata.published_date = optional_string(metadata.published_date);
    metadata.language_iso = optional_string(metadata.language_iso);
    metadata.author = optional_string(metadata.author);
    metadata.tags = optional_string(metadata.tags);
    metadata.characters = optional_string(metadata.characters);
    metadata.age_rating = crate::age_rating::normalize(metadata.age_rating.as_deref());
    metadata.description = optional_string(metadata.description);
    metadata
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::db::schema::DEFAULT_PROJECT_TITLE;
    use rusqlite::Connection;

    #[test]
    fn metadata_roundtrip() {
        let connection = Connection::open_in_memory().expect("open memory db");
        connection
            .execute_batch(crate::db::schema::SCHEMA)
            .expect("create schema");
        connection
            .execute(
                "INSERT INTO projects (id, title, cover_page_index, created_at_ms, updated_at_ms)
                 VALUES ('p1', ?1, 0, 1, 1)",
                params![DEFAULT_PROJECT_TITLE],
            )
            .expect("insert project");

        let mut metadata = MetadataRecord {
            title: "Test Title".to_string(),
            series: Some("Series".to_string()),
            number: Some("12".to_string()),
            author: Some("Writer A".to_string()),
            language_iso: Some("zh-CN".to_string()),
            published_date: Some("2024-05-31".to_string()),
            ..Default::default()
        };
        metadata = normalize_metadata(metadata);

        update_metadata(&connection, "p1", &metadata, 0).expect("update metadata");
        let loaded = get_metadata(&connection, "p1", 0).expect("get metadata");
        assert_eq!(loaded.title, "Test Title");
        assert_eq!(loaded.series.as_deref(), Some("Series"));
        assert_eq!(loaded.author.as_deref(), Some("Writer A"));
        assert_eq!(loaded.published_date.as_deref(), Some("2024-05-31"));
    }

    #[test]
    fn validate_rejects_invalid_published_date() {
        let metadata = MetadataRecord {
            title: "Title".to_string(),
            published_date: Some("2024-13-01".to_string()),
            ..Default::default()
        };
        assert!(metadata.validate(0).is_err());
    }
}
