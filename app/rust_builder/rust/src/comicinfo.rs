//! ComicInfo field mapping aligned with the Anansi Project schema documentation.
//! https://anansi-project.github.io/docs/comicinfo/documentation

use std::collections::HashMap;

use quick_xml::events::Event;
use quick_xml::Reader;

pub const BLACK_AND_WHITE_VALUES: &[&str] = &["Yes", "No", "Unknown"];
pub const MANGA_VALUES: &[&str] = &["Yes", "No", "YesAndRightToLeft", "Unknown"];
pub const COMICINFO_XML_NAMES: &[&str] = &["ComicInfo.xml", "comicinfo.xml"];

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ParsedComicInfo {
    pub title: Option<String>,
    pub series: Option<String>,
    pub issue_number: Option<String>,
    pub series_count: Option<String>,
    pub volume: Option<String>,
    pub alternate_series: Option<String>,
    pub alternate_number: Option<String>,
    pub alternate_count: Option<String>,
    pub summary: Option<String>,
    pub notes: Option<String>,
    pub year: Option<String>,
    pub month: Option<String>,
    pub day: Option<String>,
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
    pub page_count: Option<String>,
    pub pages: Vec<ParsedComicInfoPage>,
}

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ParsedComicInfoPage {
    pub image: String,
    pub page_type: Option<String>,
    pub image_size: Option<String>,
}

pub fn cover_page_index_from_pages(
    pages: &[ParsedComicInfoPage],
    page_count: i32,
    page_paths: &[String],
) -> i32 {
    let Some(front) = pages.iter().find(|page| {
        page.page_type
            .as_deref()
            .is_some_and(|value| value.eq_ignore_ascii_case("FrontCover"))
    }) else {
        return 0;
    };

    let image = front.image.trim();

    if !page_paths.is_empty() {
        if let Some(index) = page_paths.iter().position(|path| {
            std::path::Path::new(path.as_str())
                .file_stem()
                .and_then(|stem| stem.to_str())
                .is_some_and(|stem| stem == image)
        }) {
            let index = index as i32;
            if (0..page_count).contains(&index) {
                return index;
            }
        }
    }

    if let Ok(index) = image.parse::<i32>() {
        if (0..page_count).contains(&index) {
            return index;
        }
    }

    0
}

pub fn validate_year(year: i32) -> Result<(), String> {
    if (1000..=9999).contains(&year) {
        Ok(())
    } else {
        Err(format!("Year must be between 1000 and 9999, got {year}"))
    }
}

pub fn validate_month(month: i32) -> Result<(), String> {
    if (1..=12).contains(&month) {
        Ok(())
    } else {
        Err(format!("Month must be between 1 and 12, got {month}"))
    }
}

pub fn validate_day(day: i32) -> Result<(), String> {
    if (1..=31).contains(&day) {
        Ok(())
    } else {
        Err(format!("Day must be between 1 and 31, got {day}"))
    }
}

pub fn validate_black_and_white(value: &str) -> Result<(), String> {
    if BLACK_AND_WHITE_VALUES.contains(&value) {
        Ok(())
    } else {
        Err(format!(
            "BlackAndWhite must be one of: {}",
            BLACK_AND_WHITE_VALUES.join(", ")
        ))
    }
}

pub fn validate_manga(value: &str) -> Result<(), String> {
    if MANGA_VALUES.contains(&value) {
        Ok(())
    } else {
        Err(format!("Manga must be one of: {}", MANGA_VALUES.join(", ")))
    }
}

pub fn validate_community_rating(value: &str) -> Result<(), String> {
    let parsed: f32 = value
        .parse()
        .map_err(|_| "CommunityRating must be a number between 0.0 and 5.0".to_string())?;
    if (0.0..=5.0).contains(&parsed) {
        Ok(())
    } else {
        Err("CommunityRating must be between 0.0 and 5.0".to_string())
    }
}

pub fn parse_comicinfo_xml(xml: &str) -> Result<ParsedComicInfo, String> {
    let mut reader = Reader::from_str(xml);
    reader.config_mut().trim_text(true);

    let mut buf = Vec::new();
    let mut fields: HashMap<String, String> = HashMap::new();
    let mut pages: Vec<ParsedComicInfoPage> = Vec::new();
    let mut current_tag: Option<String> = None;
    let mut current_text = String::new();

    loop {
        match reader.read_event_into(&mut buf) {
            Ok(Event::Start(e)) => {
                let name = String::from_utf8_lossy(e.name().as_ref()).into_owned();
                if name == "Page" {
                    pages.push(parse_page_element(&e)?);
                } else if name != "ComicInfo" && name != "Pages" {
                    current_tag = Some(name);
                    current_text.clear();
                }
            }
            Ok(Event::Empty(e)) => {
                let name = String::from_utf8_lossy(e.name().as_ref()).into_owned();
                if name == "Page" {
                    pages.push(parse_page_element(&e)?);
                } else if name != "ComicInfo" && name != "Pages" {
                    fields.insert(name, String::new());
                }
            }
            Ok(Event::Text(e)) => {
                if current_tag.is_some() {
                    let text = e
                        .unescape()
                        .map_err(|error| format!("decode ComicInfo text: {error}"))?
                        .into_owned();
                    current_text.push_str(&text);
                }
            }
            Ok(Event::End(e)) => {
                let name = String::from_utf8_lossy(e.name().as_ref()).into_owned();
                if let Some(tag) = current_tag.take() {
                    if tag == name {
                        fields.insert(tag, current_text.trim().to_string());
                        current_text.clear();
                    } else {
                        current_tag = Some(tag);
                    }
                }
            }
            Ok(Event::Eof) => break,
            Ok(_) => {}
            Err(error) => return Err(format!("parse ComicInfo.xml: {error}")),
        }
        buf.clear();
    }

    Ok(map_fields_to_parsed(fields, pages))
}

fn parse_page_element(element: &quick_xml::events::BytesStart) -> Result<ParsedComicInfoPage, String> {
    let mut image = String::new();
    let mut page_type = None;
    let mut image_size = None;

    for attribute in element.attributes() {
        let attribute = attribute.map_err(|error| format!("read Page attribute: {error}"))?;
        let key = String::from_utf8_lossy(attribute.key.as_ref());
        let value = attribute
            .unescape_value()
            .map_err(|error| format!("decode Page attribute: {error}"))?
            .into_owned();

        match key.as_ref() {
            "Image" => image = value,
            "Type" => page_type = Some(value),
            "ImageSize" => image_size = Some(value),
            _ => {}
        }
    }

    Ok(ParsedComicInfoPage {
        image,
        page_type,
        image_size,
    })
}

pub fn page_count_from_parsed(parsed: &ParsedComicInfo) -> Option<i32> {
    parsed
        .page_count
        .as_ref()
        .and_then(|value| value.trim().parse::<i32>().ok())
}

fn map_fields_to_parsed(
    fields: HashMap<String, String>,
    pages: Vec<ParsedComicInfoPage>,
) -> ParsedComicInfo {
    ParsedComicInfo {
        title: fields.get("Title").cloned(),
        series: fields.get("Series").cloned(),
        issue_number: fields.get("Number").cloned(),
        series_count: fields.get("Count").cloned(),
        volume: fields.get("Volume").cloned(),
        alternate_series: fields.get("AlternateSeries").cloned(),
        alternate_number: fields.get("AlternateNumber").cloned(),
        alternate_count: fields.get("AlternateCount").cloned(),
        summary: fields.get("Summary").cloned(),
        notes: fields.get("Notes").cloned(),
        year: fields.get("Year").cloned(),
        month: fields.get("Month").cloned(),
        day: fields.get("Day").cloned(),
        writer: fields.get("Writer").cloned(),
        penciller: fields.get("Penciller").cloned(),
        inker: fields.get("Inker").cloned(),
        colorist: fields.get("Colorist").cloned(),
        letterer: fields.get("Letterer").cloned(),
        cover_artist: fields.get("CoverArtist").cloned(),
        editor: fields.get("Editor").cloned(),
        translator: fields.get("Translator").cloned(),
        publisher: fields.get("Publisher").cloned(),
        imprint: fields.get("Imprint").cloned(),
        genre: fields.get("Genre").cloned(),
        tags: fields.get("Tags").cloned(),
        web: fields.get("Web").cloned(),
        language_iso: fields.get("LanguageISO").cloned(),
        format: fields.get("Format").cloned(),
        black_and_white: fields.get("BlackAndWhite").cloned(),
        manga: fields.get("Manga").cloned(),
        characters: fields.get("Characters").cloned(),
        teams: fields.get("Teams").cloned(),
        locations: fields.get("Locations").cloned(),
        main_character_or_team: fields.get("MainCharacterOrTeam").cloned(),
        scan_information: fields.get("ScanInformation").cloned(),
        story_arc: fields.get("StoryArc").cloned(),
        story_arc_number: fields.get("StoryArcNumber").cloned(),
        series_group: fields.get("SeriesGroup").cloned(),
        age_rating: fields.get("AgeRating").cloned(),
        community_rating: fields.get("CommunityRating").cloned(),
        review: fields.get("Review").cloned(),
        gtin: fields.get("GTIN").cloned(),
        page_count: fields.get("PageCount").cloned(),
        pages,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn validates_comicinfo_enums() {
        assert!(validate_manga("YesAndRightToLeft").is_ok());
        assert!(validate_black_and_white("Unknown").is_ok());
        assert!(validate_community_rating("4.5").is_ok());
        assert!(validate_community_rating("6").is_err());
    }

    #[test]
    fn parses_comicinfo_xml_to_metadata() {
        let xml = r#"<?xml version="1.0"?>
<ComicInfo>
  <Title>Test Comic</Title>
  <Series>Adventures</Series>
  <Number>7</Number>
  <Writer>Alice</Writer>
  <PageCount>2</PageCount>
  <Year>2024</Year>
</ComicInfo>"#;

        let parsed = parse_comicinfo_xml(xml).expect("parse");
        assert_eq!(parsed.title.as_deref(), Some("Test Comic"));
        assert_eq!(parsed.issue_number.as_deref(), Some("7"));
        assert_eq!(page_count_from_parsed(&parsed), Some(2));
    }

    #[test]
    fn parses_pages_and_front_cover_index() {
        let xml = r#"<?xml version="1.0"?>
<ComicInfo>
  <Title>Cover Test</Title>
  <PageCount>3</PageCount>
  <Pages>
    <Page Image="0" Type="Story" ImageSize="100"/>
    <Page Image="1" Type="FrontCover" ImageSize="200"/>
    <Page Image="2" ImageSize="300"/>
  </Pages>
</ComicInfo>"#;

        let parsed = parse_comicinfo_xml(xml).expect("parse");
        assert_eq!(parsed.pages.len(), 3);
        assert_eq!(cover_page_index_from_pages(&parsed.pages, 3, &[]), 1);
    }
}
