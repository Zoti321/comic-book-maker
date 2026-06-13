//! PDF Document Info parsing and minimal canonical metadata mapping.

use std::path::Path;

use image::{ImageBuffer, Rgba};
use lopdf::decode_text_string;
use lopdf::{Dictionary, Document, Object, ObjectId, Stream};

use crate::db::MetadataRecord;
use crate::metadata_schema::normalize_comma_separated_tags;
use crate::published_date::merge_year_month_day;

#[derive(Debug, Clone, Default, PartialEq, Eq)]
pub struct ParsedPdfDocumentInfo {
    pub title: Option<String>,
    pub author: Option<String>,
    pub subject: Option<String>,
    pub keywords: Option<String>,
    pub creation_date: Option<String>,
    pub mod_date: Option<String>,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ExtractedPdfPage {
    pub extension: String,
    pub bytes: Vec<u8>,
}

pub fn scan_pdf(path: &Path) -> Result<(ParsedPdfDocumentInfo, Vec<ExtractedPdfPage>), String> {
    let document =
        Document::load(path).map_err(|error| format!("read PDF: {error}"))?;
    let info = parse_pdf_document_info(&document);
    let pages = extract_pdf_pages(&document)?;
    Ok((info, pages))
}

pub fn parse_pdf_document_info(document: &Document) -> ParsedPdfDocumentInfo {
    let mut info = ParsedPdfDocumentInfo::default();
    let Ok(info_id) = document
        .trailer
        .get(b"Info")
        .and_then(Object::as_reference)
    else {
        return info;
    };
    let Ok(dict) = document.get_dictionary(info_id) else {
        return info;
    };

    info.title = read_info_text(dict, b"Title");
    info.author = read_info_text(dict, b"Author");
    info.subject = read_info_text(dict, b"Subject");
    info.keywords = read_info_text(dict, b"Keywords");
    info.creation_date = read_info_text(dict, b"CreationDate");
    info.mod_date = read_info_text(dict, b"ModDate");
    info
}

pub fn metadata_from_pdf_document_info(
    info: &ParsedPdfDocumentInfo,
    fallback_title: &str,
    page_count: i32,
) -> MetadataRecord {
    let title = info
        .title
        .as_deref()
        .filter(|value| !value.trim().is_empty())
        .unwrap_or(fallback_title)
        .trim()
        .to_string();

    let published_date = info
        .creation_date
        .as_deref()
        .and_then(normalize_pdf_date)
        .or_else(|| info.mod_date.as_deref().and_then(normalize_pdf_date));

    MetadataRecord {
        title,
        author: optional_trimmed_copy(&info.author),
        description: optional_trimmed_copy(&info.subject),
        tags: info
            .keywords
            .as_deref()
            .and_then(normalize_comma_separated_tags),
        published_date,
        page_count,
        ..Default::default()
    }
}

fn optional_trimmed_copy(value: &Option<String>) -> Option<String> {
    value
        .as_ref()
        .map(|text| text.trim().to_string())
        .filter(|text| !text.is_empty())
}

fn read_info_text(dict: &Dictionary, key: &[u8]) -> Option<String> {
    let value = dict.get(key).ok()?;
    decode_text_string(value)
        .ok()
        .map(|text| text.trim().to_string())
        .filter(|text| !text.is_empty())
}

pub fn normalize_pdf_date(raw: &str) -> Option<String> {
    let trimmed = raw.trim();
    if trimmed.is_empty() {
        return None;
    }

    let payload = trimmed
        .strip_prefix("D:")
        .unwrap_or(trimmed)
        .trim();
    let digits: String = payload
        .chars()
        .take_while(|character| character.is_ascii_digit())
        .collect();

    match digits.len() {
        4 => {
            let year = digits.parse().ok()?;
            merge_year_month_day(Some(year), None, None)
        }
        6 => {
            let year = digits[..4].parse().ok()?;
            let month = digits[4..6].parse().ok()?;
            merge_year_month_day(Some(year), Some(month), None)
        }
        len if len >= 8 => {
            let year = digits[..4].parse().ok()?;
            let month = digits[4..6].parse().ok()?;
            let day = digits[6..8].parse().ok()?;
            merge_year_month_day(Some(year), Some(month), Some(day))
        }
        _ => None,
    }
}

fn extract_pdf_pages(document: &Document) -> Result<Vec<ExtractedPdfPage>, String> {
    let mut pages = Vec::new();
    for page_id in document.page_iter() {
        let Some(page) = extract_page_image(document, page_id)? else {
            continue;
        };
        pages.push(page);
    }

    if pages.is_empty() {
        return Err("PDF 中未找到可用的 Page Image".to_string());
    }

    Ok(pages)
}

fn extract_page_image(
    document: &Document,
    page_id: ObjectId,
) -> Result<Option<ExtractedPdfPage>, String> {
    let page = document
        .get_dictionary(page_id)
        .map_err(|error| format!("read PDF page dictionary: {error}"))?;
    let resources = page
        .get(b"Resources")
        .and_then(Object::as_reference)
        .map_err(|_| "PDF page missing Resources".to_string())?;
    let resources = document
        .get_dictionary(resources)
        .map_err(|error| format!("read PDF page resources: {error}"))?;
    let xobject = resources
        .get(b"XObject")
        .and_then(Object::as_dict)
        .map_err(|_| "PDF page missing XObject resources".to_string())?;

    for (_, object) in xobject.iter() {
        let stream = match object {
            Object::Reference(reference) => document
                .get_object(*reference)
                .ok()
                .and_then(|value| value.as_stream().ok()),
            Object::Stream(stream) => Some(stream),
            _ => None,
        };
        let Some(stream) = stream else {
            continue;
        };
        if !is_image_xobject(stream) {
            continue;
        }
        return extract_image_xobject(stream).map(Some);
    }

    Ok(None)
}

fn is_image_xobject(stream: &Stream) -> bool {
    stream
        .dict
        .get(b"Subtype")
        .and_then(Object::as_name)
        .ok()
        .is_some_and(|name| name == b"Image")
}

fn extract_image_xobject(stream: &Stream) -> Result<ExtractedPdfPage, String> {
    match stream_filter_name(&stream.dict).as_deref() {
        Some(b"DCTDecode") => Ok(ExtractedPdfPage {
            extension: "jpg".to_string(),
            bytes: stream.content.clone(),
        }),
        Some(b"FlateDecode") => {
            let width = stream
                .dict
                .get(b"Width")
                .and_then(Object::as_i64)
                .map_err(|_| "PDF image missing Width".to_string())? as u32;
            let height = stream
                .dict
                .get(b"Height")
                .and_then(Object::as_i64)
                .map_err(|_| "PDF image missing Height".to_string())? as u32;
            let expected_len = (width as usize)
                .checked_mul(height as usize)
                .and_then(|value| value.checked_mul(3))
                .ok_or_else(|| "PDF image dimensions overflow".to_string())?;
            let rgb = match stream.decompressed_content() {
                Ok(data) if data.len() == expected_len => data,
                _ => stream.content.clone(),
            };
            if rgb.len() != expected_len {
                return Err(format!(
                    "PDF image stream length mismatch: expected {expected_len}, got {}",
                    rgb.len()
                ));
            }

            let mut rgba = Vec::with_capacity(width as usize * height as usize * 4);
            for chunk in rgb.chunks_exact(3) {
                rgba.extend_from_slice(&[chunk[0], chunk[1], chunk[2], 255]);
            }
            let image = ImageBuffer::<Rgba<u8>, _>::from_raw(width, height, rgba)
                .ok_or_else(|| "construct PDF image buffer".to_string())?;
            let mut buffer = std::io::Cursor::new(Vec::new());
            image
                .write_to(&mut buffer, image::ImageFormat::Png)
                .map_err(|error| format!("encode PDF page PNG: {error}"))?;
            Ok(ExtractedPdfPage {
                extension: "png".to_string(),
                bytes: buffer.into_inner(),
            })
        }
        other => Err(format!(
            "unsupported PDF page image filter: {}",
            other.map(|name| String::from_utf8_lossy(name).into_owned())
                .unwrap_or_else(|| "unknown".to_string())
        )),
    }
}

fn stream_filter_name(dict: &Dictionary) -> Option<Vec<u8>> {
    match dict.get(b"Filter").ok()? {
        Object::Name(name) => Some(name.clone()),
        Object::Array(values) => values
            .first()
            .and_then(|value| value.as_name().ok())
            .map(|name| name.to_vec()),
        _ => None,
    }
}

#[cfg(test)]
pub(crate) fn write_test_pdf_with_document_info(
    path: &Path,
    info: &ParsedPdfDocumentInfo,
    jpeg_bytes: &[u8],
) {
    use lopdf::{text_string, Dictionary, Object};

    let mut document = Document::with_version("1.5");
    let pages_id = document.new_object_id();
    let catalog_id = document.new_object_id();

    let image_id = document.add_object(Object::Stream(Stream::new(
        Dictionary::from_iter(vec![
            ("Type", Object::Name(b"XObject".to_vec())),
            ("Subtype", Object::Name(b"Image".to_vec())),
            ("Width", Object::Integer(8)),
            ("Height", Object::Integer(12)),
            ("ColorSpace", Object::Name(b"DeviceRGB".to_vec())),
            ("BitsPerComponent", Object::Integer(8)),
            ("Filter", Object::Name(b"DCTDecode".to_vec())),
        ]),
        jpeg_bytes.to_vec(),
    )));

    let content_id = document.add_object(Object::Stream(Stream::new(
        Dictionary::from_iter(vec![("Length", Object::Integer(0))]),
        Vec::new(),
    )));
    let resources_id = document.add_object(Object::Dictionary(Dictionary::from_iter(vec![(
        "XObject",
        Object::Dictionary(Dictionary::from_iter(vec![(
            "Im1",
            Object::Reference(image_id),
        )])),
    )])));
    let page_id = document.add_object(Object::Dictionary(Dictionary::from_iter(vec![
        ("Type", Object::Name(b"Page".to_vec())),
        ("Parent", Object::Reference(pages_id)),
        (
            "MediaBox",
            Object::Array(vec![
                Object::Real(0.0),
                Object::Real(0.0),
                Object::Real(8.0),
                Object::Real(12.0),
            ]),
        ),
        ("Resources", Object::Reference(resources_id)),
        ("Contents", Object::Reference(content_id)),
    ])));

    document.objects.insert(
        pages_id,
        Object::Dictionary(Dictionary::from_iter(vec![
            ("Type", Object::Name(b"Pages".to_vec())),
            (
                "Kids",
                Object::Array(vec![Object::Reference(page_id)]),
            ),
            ("Count", Object::Integer(1)),
        ])),
    );
    document.objects.insert(
        catalog_id,
        Object::Dictionary(Dictionary::from_iter(vec![
            ("Type", Object::Name(b"Catalog".to_vec())),
            ("Pages", Object::Reference(pages_id)),
        ])),
    );

    let mut info_dict = Dictionary::new();
    if let Some(title) = info.title.as_deref() {
        info_dict.set("Title", text_string(title));
    }
    if let Some(author) = info.author.as_deref() {
        info_dict.set("Author", text_string(author));
    }
    if let Some(subject) = info.subject.as_deref() {
        info_dict.set("Subject", text_string(subject));
    }
    if let Some(keywords) = info.keywords.as_deref() {
        info_dict.set("Keywords", text_string(keywords));
    }
    if let Some(creation_date) = info.creation_date.as_deref() {
        info_dict.set("CreationDate", text_string(creation_date));
    }
    let info_id = document.add_object(Object::Dictionary(info_dict));
    document.trailer.set("Root", Object::Reference(catalog_id));
    document.trailer.set("Info", Object::Reference(info_id));
    document.save(path).expect("save test pdf");
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::io::Cursor;
    use uuid::Uuid;

    fn temp_dir(name: &str) -> std::path::PathBuf {
        let dir = std::env::temp_dir().join(format!("cbm-pdf-{name}-{}", Uuid::new_v4()));
        std::fs::create_dir_all(&dir).expect("create temp dir");
        dir
    }

    fn jpeg_bytes() -> Vec<u8> {
        let img: ImageBuffer<image::Rgb<u8>, Vec<u8>> =
            ImageBuffer::from_fn(8, 12, |_, _| image::Rgb([200u8, 100, 50]));
        let mut buffer = Cursor::new(Vec::new());
        img.write_to(&mut buffer, image::ImageFormat::Jpeg)
            .expect("encode jpeg");
        buffer.into_inner()
    }

    #[test]
    fn parse_pdf_document_info_reads_minimal_fields() {
        let dir = temp_dir("parse");
        let pdf = dir.join("meta.pdf");
        write_test_pdf_with_document_info(
            &pdf,
            &ParsedPdfDocumentInfo {
                title: Some("PDF Title".to_string()),
                author: Some("Author Name".to_string()),
                subject: Some("About this comic".to_string()),
                keywords: Some("action,drama".to_string()),
                creation_date: Some("D:20240531".to_string()),
                ..Default::default()
            },
            &jpeg_bytes(),
        );

        let (info, pages) = scan_pdf(&pdf).expect("scan");
        assert_eq!(info.title.as_deref(), Some("PDF Title"));
        assert_eq!(info.author.as_deref(), Some("Author Name"));
        assert_eq!(info.subject.as_deref(), Some("About this comic"));
        assert_eq!(info.keywords.as_deref(), Some("action,drama"));
        assert_eq!(pages.len(), 1);
    }

    #[test]
    fn metadata_from_pdf_document_info_maps_canonical_fields() {
        let info = ParsedPdfDocumentInfo {
            title: Some("Title".to_string()),
            author: Some("Alice".to_string()),
            subject: Some("Summary".to_string()),
            keywords: Some("tag1, tag2".to_string()),
            creation_date: Some("D:20240531".to_string()),
            ..Default::default()
        };

        let metadata = metadata_from_pdf_document_info(&info, "Fallback", 2);
        assert_eq!(metadata.title, "Title");
        assert_eq!(metadata.author.as_deref(), Some("Alice"));
        assert_eq!(metadata.description.as_deref(), Some("Summary"));
        assert_eq!(metadata.tags.as_deref(), Some("tag1,tag2"));
        assert_eq!(metadata.published_date.as_deref(), Some("2024-05-31"));
        assert_eq!(metadata.page_count, 2);
        assert!(metadata.series.is_none());
        assert!(metadata.language_iso.is_none());
    }

    #[test]
    fn normalize_pdf_date_supports_graded_iso() {
        assert_eq!(
            normalize_pdf_date("D:2024").as_deref(),
            Some("2024")
        );
        assert_eq!(
            normalize_pdf_date("D:202405").as_deref(),
            Some("2024-05")
        );
        assert_eq!(
            normalize_pdf_date("D:20240531120000Z").as_deref(),
            Some("2024-05-31")
        );
    }
}
