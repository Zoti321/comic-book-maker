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
            parsed.editor.as_deref(),
            parsed.translator.as_deref(),
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

#[cfg(test)]
mod tests {
    use super::*;

    const FULL_COMICINFO: &str = r#"<?xml version="1.0"?>
<ComicInfo>
  <Title>Imported Title</Title>
  <Series>Sample Series</Series>
  <Number>7</Number>
  <Count>12</Count>
  <Year>2024</Year>
  <Month>5</Month>
  <Day>31</Day>
  <LanguageISO>zh-CN</LanguageISO>
  <Writer>Alice</Writer>
  <Penciller>Bob</Penciller>
  <CoverArtist>Carol</CoverArtist>
  <Tags>tag1,tag2</Tags>
  <Characters>CharA</Characters>
  <AgeRating>Everyone</AgeRating>
  <Summary>A summary</Summary>
  <PageCount>2</PageCount>
  <Pages>
    <Page Image="0" Type="FrontCover"/>
    <Page Image="1"/>
  </Pages>
</ComicInfo>"#;

    #[test]
    fn maps_comicinfo_to_canonical_metadata() {
        let page_paths = vec!["0.png".to_string(), "1.png".to_string()];
        let (metadata, _, warnings) = build_import_metadata(
            &Some(FULL_COMICINFO.to_string()),
            "fallback.cbz",
            2,
            &page_paths,
        );

        assert!(warnings.is_empty());
        assert_eq!(metadata.title, "Imported Title");
        assert_eq!(metadata.series.as_deref(), Some("Sample Series"));
        assert_eq!(metadata.number.as_deref(), Some("7"));
        assert_eq!(metadata.series_count.as_deref(), Some("12"));
        assert_eq!(metadata.published_date.as_deref(), Some("2024-05-31"));
        assert_eq!(metadata.language_iso.as_deref(), Some("zh-CN"));
        assert_eq!(metadata.tags.as_deref(), Some("tag1,tag2"));
        assert_eq!(metadata.characters.as_deref(), Some("CharA"));
        assert_eq!(metadata.age_rating.as_deref(), Some("Everyone"));
        assert_eq!(metadata.description.as_deref(), Some("A summary"));
        assert_eq!(metadata.page_count, 2);
        assert_eq!(metadata.cover_page_index, 0);
    }

    #[test]
    fn joins_multiple_credit_roles_into_author() {
        let page_paths = vec!["001.png".to_string()];
        let xml = r#"<ComicInfo>
  <Title>T</Title>
  <Writer>Alice</Writer>
  <Penciller>Bob</Penciller>
  <CoverArtist>Carol</CoverArtist>
  <Editor>Dana</Editor>
</ComicInfo>"#;
        let (metadata, _, _) =
            build_import_metadata(&Some(xml.to_string()), "fallback", 1, &page_paths);
        assert_eq!(
            metadata.author.as_deref(),
            Some("Alice, Bob, Carol, Dana")
        );
    }

    #[test]
    fn published_date_supports_graded_iso_on_import() {
        let page_paths = vec!["001.png".to_string()];

        let year_only = r#"<ComicInfo><Title>T</Title><Year>2024</Year></ComicInfo>"#;
        let (year_metadata, _, _) =
            build_import_metadata(&Some(year_only.to_string()), "fallback", 1, &page_paths);
        assert_eq!(year_metadata.published_date.as_deref(), Some("2024"));

        let year_month = r#"<ComicInfo><Title>T</Title><Year>2024</Year><Month>5</Month></ComicInfo>"#;
        let (month_metadata, _, _) =
            build_import_metadata(&Some(year_month.to_string()), "fallback", 1, &page_paths);
        assert_eq!(month_metadata.published_date.as_deref(), Some("2024-05"));
    }

    #[test]
    fn pagecount_mismatch_emits_warning() {
        let page_paths = vec!["001.png".to_string()];
        let xml = r#"<ComicInfo><Title>T</Title><PageCount>99</PageCount></ComicInfo>"#;
        let (_, _, warnings) =
            build_import_metadata(&Some(xml.to_string()), "fallback", 1, &page_paths);
        assert_eq!(warnings.len(), 1);
        assert!(warnings[0].contains("PageCount"));
    }

    #[test]
    fn uses_filename_fallback_when_title_missing() {
        let page_paths = vec!["001.png".to_string()];
        let xml = r#"<ComicInfo><Series>S</Series></ComicInfo>"#;
        let (metadata, _, _) =
            build_import_metadata(&Some(xml.to_string()), "My Comic", 1, &page_paths);
        assert_eq!(metadata.title, "My Comic");
    }
}
