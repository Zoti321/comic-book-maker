use rusqlite::{params, Connection, Row};

use crate::comicinfo;

#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct MetadataRecord {
    pub title: String,
    pub series: Option<String>,
    pub issue_number: Option<String>,
    pub series_count: Option<String>,
    pub volume: Option<String>,
    pub alternate_series: Option<String>,
    pub alternate_number: Option<String>,
    pub alternate_count: Option<String>,
    pub summary: Option<String>,
    pub notes: Option<String>,
    pub year: Option<i32>,
    pub month: Option<i32>,
    pub day: Option<i32>,
    pub writer: Option<String>,
    pub penciller: Option<String>,
    pub inker: Option<String>,
    pub colorist: Option<String>,
    pub letterer: Option<String>,
    pub cover_artist: Option<String>,
    pub editor: Option<String>,
    pub translator: Option<String>,
    pub publisher: Option<String>,
    pub imprint: Option<String>,
    pub genre: Option<String>,
    pub tags: Option<String>,
    pub web: Option<String>,
    pub language_iso: Option<String>,
    pub format: Option<String>,
    pub black_and_white: Option<String>,
    pub manga: Option<String>,
    pub characters: Option<String>,
    pub teams: Option<String>,
    pub locations: Option<String>,
    pub main_character_or_team: Option<String>,
    pub scan_information: Option<String>,
    pub story_arc: Option<String>,
    pub story_arc_number: Option<String>,
    pub series_group: Option<String>,
    pub age_rating: Option<String>,
    pub community_rating: Option<String>,
    pub review: Option<String>,
    pub gtin: Option<String>,
    pub cover_page_index: i32,
    pub page_count: i32,
}

impl MetadataRecord {
    pub fn validate(&self, page_count: i32) -> Result<(), String> {
        if self.title.trim().is_empty() {
            return Err("title must not be empty".to_string());
        }

        if let Some(year) = self.year {
            comicinfo::validate_year(year)?;
        }
        if let Some(month) = self.month {
            comicinfo::validate_month(month)?;
        }
        if let Some(day) = self.day {
            comicinfo::validate_day(day)?;
        }
        if let Some(value) = &self.black_and_white {
            comicinfo::validate_black_and_white(value)?;
        }
        if let Some(value) = &self.manga {
            comicinfo::validate_manga(value)?;
        }
        if let Some(value) = &self.community_rating {
            comicinfo::validate_community_rating(value)?;
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
                title, series, issue_number, series_count, volume,
                alternate_series, alternate_number, alternate_count,
                summary, notes, year, month, day,
                writer, penciller, inker, colorist, letterer, cover_artist, editor, translator,
                publisher, imprint, genre, tags, web, language_iso, format,
                black_and_white, manga, characters, teams, locations, main_character_or_team,
                scan_information, story_arc, story_arc_number, series_group,
                age_rating, community_rating, review, gtin, cover_page_index
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
                issue_number = ?3,
                series_count = ?4,
                volume = ?5,
                alternate_series = ?6,
                alternate_number = ?7,
                alternate_count = ?8,
                summary = ?9,
                notes = ?10,
                year = ?11,
                month = ?12,
                day = ?13,
                writer = ?14,
                penciller = ?15,
                inker = ?16,
                colorist = ?17,
                letterer = ?18,
                cover_artist = ?19,
                editor = ?20,
                translator = ?21,
                publisher = ?22,
                imprint = ?23,
                genre = ?24,
                tags = ?25,
                web = ?26,
                language_iso = ?27,
                format = ?28,
                black_and_white = ?29,
                manga = ?30,
                characters = ?31,
                teams = ?32,
                locations = ?33,
                main_character_or_team = ?34,
                scan_information = ?35,
                story_arc = ?36,
                story_arc_number = ?37,
                series_group = ?38,
                age_rating = ?39,
                community_rating = ?40,
                review = ?41,
                gtin = ?42,
                cover_page_index = ?43,
                updated_at_ms = ?44
             WHERE id = ?45",
            params![
                metadata.title,
                metadata.series,
                metadata.issue_number,
                metadata.series_count,
                metadata.volume,
                metadata.alternate_series,
                metadata.alternate_number,
                metadata.alternate_count,
                metadata.summary,
                metadata.notes,
                metadata.year,
                metadata.month,
                metadata.day,
                metadata.writer,
                metadata.penciller,
                metadata.inker,
                metadata.colorist,
                metadata.letterer,
                metadata.cover_artist,
                metadata.editor,
                metadata.translator,
                metadata.publisher,
                metadata.imprint,
                metadata.genre,
                metadata.tags,
                metadata.web,
                metadata.language_iso,
                metadata.format,
                metadata.black_and_white,
                metadata.manga,
                metadata.characters,
                metadata.teams,
                metadata.locations,
                metadata.main_character_or_team,
                metadata.scan_information,
                metadata.story_arc,
                metadata.story_arc_number,
                metadata.series_group,
                metadata.age_rating,
                metadata.community_rating,
                metadata.review,
                metadata.gtin,
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
    Ok(MetadataRecord {
        title: row.get(0)?,
        series: row.get(1)?,
        issue_number: row.get(2)?,
        series_count: row.get(3)?,
        volume: row.get(4)?,
        alternate_series: row.get(5)?,
        alternate_number: row.get(6)?,
        alternate_count: row.get(7)?,
        summary: row.get(8)?,
        notes: row.get(9)?,
        year: row.get(10)?,
        month: row.get(11)?,
        day: row.get(12)?,
        writer: row.get(13)?,
        penciller: row.get(14)?,
        inker: row.get(15)?,
        colorist: row.get(16)?,
        letterer: row.get(17)?,
        cover_artist: row.get(18)?,
        editor: row.get(19)?,
        translator: row.get(20)?,
        publisher: row.get(21)?,
        imprint: row.get(22)?,
        genre: row.get(23)?,
        tags: row.get(24)?,
        web: row.get(25)?,
        language_iso: row.get(26)?,
        format: row.get(27)?,
        black_and_white: row.get(28)?,
        manga: row.get(29)?,
        characters: row.get(30)?,
        teams: row.get(31)?,
        locations: row.get(32)?,
        main_character_or_team: row.get(33)?,
        scan_information: row.get(34)?,
        story_arc: row.get(35)?,
        story_arc_number: row.get(36)?,
        series_group: row.get(37)?,
        age_rating: row.get(38)?,
        community_rating: row.get(39)?,
        review: row.get(40)?,
        gtin: row.get(41)?,
        cover_page_index: row.get(42)?,
        page_count,
    })
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
    metadata.issue_number = optional_string(metadata.issue_number);
    metadata.series_count = optional_string(metadata.series_count);
    metadata.volume = optional_string(metadata.volume);
    metadata.alternate_series = optional_string(metadata.alternate_series);
    metadata.alternate_number = optional_string(metadata.alternate_number);
    metadata.alternate_count = optional_string(metadata.alternate_count);
    metadata.summary = optional_string(metadata.summary);
    metadata.notes = optional_string(metadata.notes);
    metadata.writer = optional_string(metadata.writer);
    metadata.penciller = optional_string(metadata.penciller);
    metadata.inker = optional_string(metadata.inker);
    metadata.colorist = optional_string(metadata.colorist);
    metadata.letterer = optional_string(metadata.letterer);
    metadata.cover_artist = optional_string(metadata.cover_artist);
    metadata.editor = optional_string(metadata.editor);
    metadata.translator = optional_string(metadata.translator);
    metadata.publisher = optional_string(metadata.publisher);
    metadata.imprint = optional_string(metadata.imprint);
    metadata.genre = optional_string(metadata.genre);
    metadata.tags = optional_string(metadata.tags);
    metadata.web = optional_string(metadata.web);
    metadata.language_iso = optional_string(metadata.language_iso);
    metadata.format = optional_string(metadata.format);
    metadata.black_and_white = optional_string(metadata.black_and_white);
    metadata.manga = optional_string(metadata.manga);
    metadata.characters = optional_string(metadata.characters);
    metadata.teams = optional_string(metadata.teams);
    metadata.locations = optional_string(metadata.locations);
    metadata.main_character_or_team = optional_string(metadata.main_character_or_team);
    metadata.scan_information = optional_string(metadata.scan_information);
    metadata.story_arc = optional_string(metadata.story_arc);
    metadata.story_arc_number = optional_string(metadata.story_arc_number);
    metadata.series_group = optional_string(metadata.series_group);
    metadata.age_rating = optional_string(metadata.age_rating);
    metadata.community_rating = optional_string(metadata.community_rating);
    metadata.review = optional_string(metadata.review);
    metadata.gtin = optional_string(metadata.gtin);
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
            issue_number: Some("12".to_string()),
            writer: Some("Writer A".to_string()),
            penciller: Some("Artist B".to_string()),
            language_iso: Some("zh-CN".to_string()),
            year: Some(2024),
            month: Some(5),
            day: Some(31),
            ..Default::default()
        };
        metadata = normalize_metadata(metadata);

        update_metadata(&connection, "p1", &metadata, 0).expect("update metadata");
        let loaded = get_metadata(&connection, "p1", 0).expect("get metadata");
        assert_eq!(loaded.title, "Test Title");
        assert_eq!(loaded.series.as_deref(), Some("Series"));
        assert_eq!(loaded.writer.as_deref(), Some("Writer A"));
        assert_eq!(loaded.year, Some(2024));
    }
}
