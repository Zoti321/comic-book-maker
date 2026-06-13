//! ComicInfo → project metadata mapping for archive imports.

use crate::comicinfo::{
    cover_page_index_from_pages, page_count_from_parsed, parse_comicinfo_xml, ParsedComicInfo,
};
use crate::db::{normalize_metadata, MetadataRecord};
use crate::published_date::merge_year_month_day;

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

    let year = parse_optional_int(&parsed.year);
    let month = parse_optional_int(&parsed.month);
    let day = parse_optional_int(&parsed.day);
    let published_date = merge_year_month_day(year, month, day);

    MetadataRecord {
        title,
        series: optional_copy(&parsed.series),
        number: optional_copy(&parsed.issue_number),
        series_count: optional_copy(&parsed.series_count),
        published_date,
        language_iso: optional_copy(&parsed.language_iso),
        author: join_non_empty(&[
            parsed.writer.as_deref(),
            parsed.penciller.as_deref(),
            parsed.cover_artist.as_deref(),
            parsed.inker.as_deref(),
            parsed.colorist.as_deref(),
            parsed.letterer.as_deref(),
        ]),
        tags: optional_copy(&parsed.tags),
        characters: optional_copy(&parsed.characters),
        age_rating: optional_copy(&parsed.age_rating),
        description: optional_copy(&parsed.summary),
        cover_page_index: cover_page_index_from_pages(&parsed.pages, page_count, page_paths),
        page_count,
    }
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

fn join_non_empty(values: &[Option<&str>]) -> Option<String> {
    let parts: Vec<String> = values
        .iter()
        .filter_map(|value| value.map(str::trim))
        .filter(|value| !value.is_empty())
        .map(str::to_string)
        .collect();
    if parts.is_empty() {
        None
    } else {
        Some(parts.join(", "))
    }
}
