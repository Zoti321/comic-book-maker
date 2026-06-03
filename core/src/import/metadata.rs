//! ComicInfo → project metadata mapping for archive imports.

use crate::comicinfo::{
    cover_page_index_from_pages, page_count_from_parsed, parse_comicinfo_xml, ParsedComicInfo,
    validate_community_rating, validate_day, validate_month, validate_year, BLACK_AND_WHITE_VALUES,
    MANGA_VALUES,
};
use crate::db::{normalize_metadata, MetadataRecord};

pub fn build_import_metadata(
    comicinfo_xml: &Option<String>,
    fallback_title: &str,
    page_count: i32,
    page_paths: &[String],
) -> (MetadataRecord, Option<i32>, Vec<String>) {
    let mut warnings = Vec::new();
    let (metadata, parsed_page_count) = if let Some(xml) = comicinfo_xml {
        if let Ok(parsed) = parse_comicinfo_xml(xml) {
            let page_count_hint = page_count_from_parsed(&parsed);
            let metadata = comicinfo_to_metadata(&parsed, page_count, fallback_title, page_paths);
            (metadata, page_count_hint)
        } else {
            (
                MetadataRecord {
                    title: fallback_title.to_string(),
                    page_count,
                    ..Default::default()
                },
                None,
            )
        }
    } else {
        (
            MetadataRecord {
                title: fallback_title.to_string(),
                page_count,
                ..Default::default()
            },
            None,
        )
    };

    if let Some(expected) = parsed_page_count {
        if expected != page_count {
            warnings.push(format!(
                "ComicInfo PageCount ({expected}) 与实际页数 ({page_count}) 不符"
            ));
        }
    }

    (normalize_metadata(metadata), parsed_page_count, warnings)
}

fn comicinfo_to_metadata(
    parsed: &ParsedComicInfo,
    page_count: i32,
    fallback_title: &str,
    page_paths: &[String],
) -> MetadataRecord {
    let title = parsed
        .title
        .as_deref()
        .filter(|value| !value.trim().is_empty())
        .unwrap_or(fallback_title)
        .trim()
        .to_string();

    let mut metadata = MetadataRecord {
        title,
        series: optional_copy(&parsed.series),
        issue_number: optional_copy(&parsed.issue_number),
        series_count: optional_copy(&parsed.series_count),
        volume: optional_copy(&parsed.volume),
        alternate_series: optional_copy(&parsed.alternate_series),
        alternate_number: optional_copy(&parsed.alternate_number),
        alternate_count: optional_copy(&parsed.alternate_count),
        summary: optional_copy(&parsed.summary),
        notes: optional_copy(&parsed.notes),
        year: parse_optional_int(&parsed.year),
        month: parse_optional_int(&parsed.month),
        day: parse_optional_int(&parsed.day),
        writer: optional_copy(&parsed.writer),
        penciller: optional_copy(&parsed.penciller),
        inker: optional_copy(&parsed.inker),
        colorist: optional_copy(&parsed.colorist),
        letterer: optional_copy(&parsed.letterer),
        cover_artist: optional_copy(&parsed.cover_artist),
        editor: optional_copy(&parsed.editor),
        translator: optional_copy(&parsed.translator),
        publisher: optional_copy(&parsed.publisher),
        imprint: optional_copy(&parsed.imprint),
        genre: optional_copy(&parsed.genre),
        tags: optional_copy(&parsed.tags),
        web: optional_copy(&parsed.web),
        language_iso: optional_copy(&parsed.language_iso),
        format: optional_copy(&parsed.format),
        black_and_white: sanitize_enum(&parsed.black_and_white, BLACK_AND_WHITE_VALUES),
        manga: sanitize_enum(&parsed.manga, MANGA_VALUES),
        characters: optional_copy(&parsed.characters),
        teams: optional_copy(&parsed.teams),
        locations: optional_copy(&parsed.locations),
        main_character_or_team: optional_copy(&parsed.main_character_or_team),
        scan_information: optional_copy(&parsed.scan_information),
        story_arc: optional_copy(&parsed.story_arc),
        story_arc_number: optional_copy(&parsed.story_arc_number),
        series_group: optional_copy(&parsed.series_group),
        age_rating: optional_copy(&parsed.age_rating),
        community_rating: sanitize_community_rating(&parsed.community_rating),
        review: optional_copy(&parsed.review),
        gtin: optional_copy(&parsed.gtin),
        cover_page_index: cover_page_index_from_pages(&parsed.pages, page_count, page_paths),
        page_count,
    };

    if metadata.year.is_some_and(|year| validate_year(year).is_err()) {
        metadata.year = None;
    }
    if metadata.month.is_some_and(|month| validate_month(month).is_err()) {
        metadata.month = None;
    }
    if metadata.day.is_some_and(|day| validate_day(day).is_err()) {
        metadata.day = None;
    }

    metadata
}

fn optional_copy(value: &Option<String>) -> Option<String> {
    value
        .as_ref()
        .map(|text| text.trim().to_string())
        .filter(|text| !text.is_empty())
}

fn parse_optional_int(value: &Option<String>) -> Option<i32> {
    value
        .as_ref()
        .and_then(|text| text.trim().parse::<i32>().ok())
}

fn sanitize_enum(value: &Option<String>, allowed: &[&str]) -> Option<String> {
    value.as_ref().and_then(|text| {
        let trimmed = text.trim();
        if allowed.contains(&trimmed) {
            Some(trimmed.to_string())
        } else {
            None
        }
    })
}

fn sanitize_community_rating(value: &Option<String>) -> Option<String> {
    value.as_ref().and_then(|text| {
        let trimmed = text.trim();
        if validate_community_rating(trimmed).is_ok() {
            Some(trimmed.to_string())
        } else {
            None
        }
    })
}