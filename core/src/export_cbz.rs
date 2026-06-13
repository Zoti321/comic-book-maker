//! CBZ (ZIP) archive export.

use std::fs::File;
use std::io::{copy, Write};
use std::path::{Path, PathBuf};

use zip::write::SimpleFileOptions;
use zip::{CompressionMethod, ZipWriter};

use crate::db::{Library, MetadataRecord, PageRecord};
use crate::export_atomic::atomic_write_destination;
use crate::export_error::ExportError;
use crate::metadata_schema::normalize_comma_separated_tags;
use crate::page_image::{cbz_zip_entry_name, normalize_extension};
use crate::published_date::{published_date_day, published_date_month, published_date_year};

pub fn export_cbz(
    library: &Library,
    project_id: &str,
    destination_path: &str,
) -> Result<(), ExportError> {
    let pages = library
        .list_pages_inner(project_id)
        .map_err(ExportError::from_library)?;
    if pages.is_empty() {
        return Err(ExportError::no_pages());
    }

    let metadata = library
        .get_project_metadata_inner(project_id)
        .map_err(ExportError::from_library)?;
    let comicinfo_xml = metadata_to_comicinfo_xml(&metadata, &pages);

    let destination = PathBuf::from(destination_path);
    atomic_write_destination(&destination, |temp_path| {
        write_cbz_archive(temp_path, &comicinfo_xml, &pages)
    })
}

fn write_cbz_archive(
    temp_path: &Path,
    comicinfo_xml: &str,
    pages: &[PageRecord],
) -> Result<(), ExportError> {
    let file = File::create(temp_path)
        .map_err(|error| ExportError::map_create_destination(error, temp_path))?;
    let mut zip = ZipWriter::new(file);
    let options = SimpleFileOptions::default().compression_method(CompressionMethod::Deflated);

    zip.start_file("ComicInfo.xml", options)
        .map_err(|error| ExportError::map_archive_write("write ComicInfo.xml", error))?;
    zip.write_all(comicinfo_xml.as_bytes())
        .map_err(|error| ExportError::map_archive_write("write ComicInfo.xml content", error))?;

    let page_count = pages.len();
    for page in pages {
        let extension = normalize_extension(Path::new(&page.asset_path))
            .map_err(ExportError::from_library)?;
        let entry_name = cbz_zip_entry_name(page.sort_index, page_count, &extension);

        zip.start_file(&entry_name, options).map_err(|error| {
            ExportError::map_archive_write(&format!("write page {entry_name}"), error)
        })?;

        let mut source = File::open(&page.absolute_path).map_err(|error| {
            ExportError::map_open_page_asset(error, &page.absolute_path)
        })?;
        copy(&mut source, &mut zip).map_err(|error| {
            ExportError::map_archive_write(&format!("copy page {entry_name} into CBZ"), error)
        })?;
    }

    zip.finish()
        .map_err(|error| ExportError::map_archive_write("finalize CBZ", error))?;

    Ok(())
}

pub(crate) fn metadata_to_comicinfo_xml(metadata: &MetadataRecord, pages: &[PageRecord]) -> String {
    let mut xml = String::from("<?xml version=\"1.0\"?>\n<ComicInfo>\n");

    append_element_always(&mut xml, "Title", Some(metadata.title.as_str()));
    append_optional_element_always(&mut xml, "Series", metadata.series.as_deref());
    append_optional_element_always(&mut xml, "Number", metadata.number.as_deref());
    append_optional_element_if_nonempty(&mut xml, "Count", metadata.series_count.as_deref());
    if let Some(published_date) = metadata.published_date.as_deref() {
        append_int_element_if_present(&mut xml, "Year", published_date_year(published_date));
        append_int_element_if_present(&mut xml, "Month", published_date_month(published_date));
        append_int_element_if_present(&mut xml, "Day", published_date_day(published_date));
    }
    append_optional_element_always(&mut xml, "Penciller", metadata.author.as_deref());
    append_optional_element_always(&mut xml, "Summary", metadata.description.as_deref());
    let normalized_tags = metadata
        .tags
        .as_deref()
        .and_then(normalize_comma_separated_tags);
    append_optional_element_always(&mut xml, "Tags", normalized_tags.as_deref());
    append_element_always(
        &mut xml,
        "PageCount",
        Some(&pages.len().to_string()),
    );
    append_optional_element_always(&mut xml, "LanguageISO", metadata.language_iso.as_deref());
    append_optional_element_always(&mut xml, "Characters", metadata.characters.as_deref());
    append_optional_element_always(&mut xml, "AgeRating", metadata.age_rating.as_deref());

    append_pages_section(&mut xml, pages, metadata.cover_page_index);

    xml.push_str("</ComicInfo>\n");
    xml
}

/// Document Info `Author` for PDF.
pub(crate) fn pdf_document_author(metadata: &MetadataRecord) -> Option<String> {
    metadata
        .author
        .as_deref()
        .map(str::trim)
        .filter(|value| !value.is_empty())
        .map(str::to_string)
}

/// ComicInfo.xml for PDF export: minimal reader-facing fields only.
pub(crate) fn metadata_to_pdf_comicinfo_xml(
    metadata: &MetadataRecord,
    title: &str,
    page_count: usize,
) -> String {
    let mut xml = String::from("<?xml version=\"1.0\"?>\n<ComicInfo>\n");

    append_optional_element_if_nonempty(&mut xml, "Title", Some(title));
    append_optional_element_if_nonempty(&mut xml, "Penciller", metadata.author.as_deref());
    append_optional_element_if_nonempty(&mut xml, "Summary", metadata.description.as_deref());
    let normalized_tags = metadata
        .tags
        .as_deref()
        .and_then(normalize_comma_separated_tags);
    append_optional_element_if_nonempty(&mut xml, "Tags", normalized_tags.as_deref());
    append_element_always(
        &mut xml,
        "PageCount",
        Some(&page_count.to_string()),
    );

    xml.push_str("</ComicInfo>\n");
    xml
}

fn append_pages_section(xml: &mut String, pages: &[PageRecord], cover_page_index: i32) {
    xml.push_str("  <Pages>\n");
    for page in pages {
        let image_size = std::fs::metadata(&page.absolute_path)
            .map(|metadata| metadata.len())
            .unwrap_or(0);

        // ComicInfo Image is the 0-based page index, not the zip file name.
        let image = page.sort_index.to_string();

        xml.push_str("    <Page Image=\"");
        xml.push_str(&escape_xml(&image));
        xml.push('"');

        if page.sort_index == cover_page_index {
            xml.push_str(" Type=\"FrontCover\"");
        }

        xml.push_str(" ImageSize=\"");
        xml.push_str(&image_size.to_string());
        xml.push_str("\"/>\n");
    }
    xml.push_str("  </Pages>\n");
}

fn append_optional_element_always(xml: &mut String, tag: &str, value: Option<&str>) {
    append_element_always(xml, tag, value);
}

fn append_optional_element_if_nonempty(xml: &mut String, tag: &str, value: Option<&str>) {
    if let Some(value) = value.map(str::trim).filter(|text| !text.is_empty()) {
        append_element_always(xml, tag, Some(value));
    }
}

fn append_int_element_if_present(xml: &mut String, tag: &str, value: Option<i32>) {
    if let Some(number) = value {
        append_element_always(xml, tag, Some(&number.to_string()));
    }
}

fn append_element_always(xml: &mut String, tag: &str, value: Option<&str>) {
    let text = value.unwrap_or("").trim();
    xml.push_str("  <");
    xml.push_str(tag);
    xml.push('>');
    xml.push_str(&escape_xml(text));
    xml.push_str("</");
    xml.push_str(tag);
    xml.push_str(">\n");
}

fn escape_xml(value: &str) -> String {
    value
        .replace('&', "&amp;")
        .replace('<', "&lt;")
        .replace('>', "&gt;")
        .replace('"', "&quot;")
        .replace('\'', "&apos;")
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::db::MetadataRecord;
    use crate::export_error::{ExportError, ExportErrorKind};
    use crate::comicinfo::{cover_page_index_from_pages, parse_comicinfo_xml};
    use crate::import_cbz::{import_cbz, scan_cbz_entries};
    use crate::paths::project_assets_dir;
    use image::{ImageBuffer, Rgba};
    use std::io::Cursor;
    use std::path::Path;
    use uuid::Uuid;
    use zip::write::SimpleFileOptions;
    use zip::ZipWriter;

    fn temp_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("cbm-export-{name}-{}", Uuid::new_v4()));
        std::fs::create_dir_all(&dir).expect("create temp dir");
        dir
    }

    fn png_bytes() -> Vec<u8> {
        let img = ImageBuffer::from_fn(8, 12, |_, _| Rgba([30u8, 90, 180, 255]));
        let mut buffer = Cursor::new(Vec::new());
        img.write_to(&mut buffer, image::ImageFormat::Png)
            .expect("encode png");
        buffer.into_inner()
    }

    fn write_test_cbz(path: &Path, pages: &[(&str, Vec<u8>)], comicinfo: Option<&str>) {
        let file = File::create(path).expect("create cbz");
        let mut zip = ZipWriter::new(file);
        let options = SimpleFileOptions::default();

        if let Some(xml) = comicinfo {
            zip.start_file("ComicInfo.xml", options)
                .expect("start comicinfo");
            zip.write_all(xml.as_bytes()).expect("write comicinfo");
        }

        for (name, content) in pages {
            zip.start_file(*name, options).expect("start page");
            zip.write_all(content).expect("write page");
        }

        zip.finish().expect("finish cbz");
    }

    #[test]
    fn pdf_document_author_returns_author_field() {
        let metadata = MetadataRecord {
            author: Some("Alice".to_string()),
            ..MetadataRecord::default()
        };
        assert_eq!(pdf_document_author(&metadata).as_deref(), Some("Alice"));
        assert_eq!(pdf_document_author(&MetadataRecord::default()), None);
    }

    #[test]
    fn serializes_pdf_comicinfo_xml_subset() {
        let metadata = MetadataRecord {
            title: "PDF Title".to_string(),
            series: Some("Series".to_string()),
            number: Some("7".to_string()),
            series_count: Some("24".to_string()),
            author: Some("Writer".to_string()),
            description: Some("Summary".to_string()),
            characters: Some("A,B".to_string()),
            age_rating: Some("Teen".to_string()),
            tags: Some("tag1, tag2".to_string()),
            page_count: 2,
            ..MetadataRecord::default()
        };

        let xml = metadata_to_pdf_comicinfo_xml(&metadata, "PDF Title", 2);
        assert!(xml.contains("<Title>PDF Title</Title>"));
        assert!(xml.contains("<Penciller>Writer</Penciller>"));
        assert!(xml.contains("<Summary>Summary</Summary>"));
        assert!(xml.contains("<Tags>tag1,tag2</Tags>"));
        assert!(xml.contains("<PageCount>2</PageCount>"));
        assert!(!xml.contains("<Writer>"));
        assert!(!xml.contains("<Series>"));
        assert!(!xml.contains("<Number>"));
        assert!(!xml.contains("<Count>"));
        assert!(!xml.contains("<Characters>"));
        assert!(!xml.contains("<AgeRating>"));
    }

    #[test]
    fn serializes_metadata_to_comicinfo_xml() {
        let metadata = MetadataRecord {
            title: "Export Title".to_string(),
            series: Some("Series".to_string()),
            number: Some("3".to_string()),
            author: Some("Alice".to_string()),
            published_date: Some("2024".to_string()),
            page_count: 2,
            cover_page_index: 1,
            ..Default::default()
        };
        let pages = vec![
            PageRecord {
                id: "p0".to_string(),
                sort_index: 0,
                asset_path: "assets/001.png".to_string(),
                absolute_path: temp_dir("page0")
                    .join("001.png")
                    .to_string_lossy()
                    .into_owned(),
            },
            PageRecord {
                id: "p1".to_string(),
                sort_index: 1,
                asset_path: "assets/002.png".to_string(),
                absolute_path: temp_dir("page1")
                    .join("002.png")
                    .to_string_lossy()
                    .into_owned(),
            },
        ];

        let xml = metadata_to_comicinfo_xml(&metadata, &pages);
        assert!(xml.contains("<Series>Series</Series>"));
        assert!(xml.contains("<Number>3</Number>"));
        assert!(xml.contains("<Penciller>Alice</Penciller>"));
        assert!(xml.contains("<Year>2024</Year>"));
        assert!(!xml.contains("<Month>"));
        assert!(!xml.contains("<Day>"));
        assert!(!xml.contains("<Writer>"));
        assert!(!xml.contains("<Notes>"));
        assert!(!xml.contains("<Inker>"));
        assert!(xml.contains("<Page Image=\"1\" Type=\"FrontCover\""));

        let parsed = parse_comicinfo_xml(&xml).expect("parse exported xml");
        assert_eq!(parsed.title.as_deref(), Some("Export Title"));
        assert_eq!(parsed.series.as_deref(), Some("Series"));
        assert_eq!(parsed.penciller.as_deref(), Some("Alice"));
        assert_eq!(parsed.year.as_deref(), Some("2024"));
        assert_eq!(cover_page_index_from_pages(&parsed.pages, 2, &[]), 1);
        assert!(parsed.pages.iter().any(|page| page.image == "1"));
    }

    fn sample_page(sort_index: i32, absolute_path: PathBuf) -> PageRecord {
        PageRecord {
            id: format!("p{sort_index}"),
            sort_index,
            asset_path: format!("assets/{sort_index:03}.png"),
            absolute_path: absolute_path.to_string_lossy().into_owned(),
        }
    }

    #[test]
    fn author_is_written_to_penciller_not_writer() {
        let metadata = MetadataRecord {
            title: "T".to_string(),
            author: Some("Canonical Author".to_string()),
            ..Default::default()
        };
        let xml = metadata_to_comicinfo_xml(&metadata, &[]);
        assert!(xml.contains("<Penciller>Canonical Author</Penciller>"));
        assert!(!xml.contains("<Writer>"));
    }

    #[test]
    fn published_date_export_respects_iso_precision() {
        let page = sample_page(0, temp_dir("date-page").join("001.png"));
        let pages = vec![page];

        let year_only = metadata_to_comicinfo_xml(
            &MetadataRecord {
                title: "T".to_string(),
                published_date: Some("2024".to_string()),
                ..Default::default()
            },
            &pages,
        );
        assert!(year_only.contains("<Year>2024</Year>"));
        assert!(!year_only.contains("<Month>"));
        assert!(!year_only.contains("<Day>"));

        let year_month = metadata_to_comicinfo_xml(
            &MetadataRecord {
                title: "T".to_string(),
                published_date: Some("2024-05".to_string()),
                ..Default::default()
            },
            &pages,
        );
        assert!(year_month.contains("<Year>2024</Year>"));
        assert!(year_month.contains("<Month>5</Month>"));
        assert!(!year_month.contains("<Day>"));

        let full_date = metadata_to_comicinfo_xml(
            &MetadataRecord {
                title: "T".to_string(),
                published_date: Some("2024-05-31".to_string()),
                ..Default::default()
            },
            &pages,
        );
        assert!(full_date.contains("<Year>2024</Year>"));
        assert!(full_date.contains("<Month>5</Month>"));
        assert!(full_date.contains("<Day>31</Day>"));
    }

    #[test]
    fn page_count_uses_actual_pages_not_stale_metadata_field() {
        let metadata = MetadataRecord {
            title: "T".to_string(),
            page_count: 99,
            ..Default::default()
        };
        let pages = vec![
            sample_page(0, temp_dir("pc0").join("001.png")),
            sample_page(1, temp_dir("pc1").join("002.png")),
            sample_page(2, temp_dir("pc2").join("003.png")),
        ];
        let xml = metadata_to_comicinfo_xml(&metadata, &pages);
        assert!(xml.contains("<PageCount>3</PageCount>"));
        assert!(!xml.contains("<PageCount>99</PageCount>"));
    }

    #[test]
    fn cbz_import_edit_export_reimport_preserves_canonical_metadata() {
        let app_data = temp_dir("roundtrip-edit");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let fixtures = temp_dir("roundtrip-edit-fixtures");
        let source_cbz = fixtures.join("source.cbz");
        let png = png_bytes();

        let comicinfo = r#"<?xml version="1.0"?>
<ComicInfo>
  <Title>Original</Title>
  <Series>Series A</Series>
  <Number>1</Number>
  <Count>10</Count>
  <Year>2020</Year>
  <LanguageISO>en</LanguageISO>
  <Writer>Alice</Writer>
  <Penciller>Bob</Penciller>
  <Tags>tag1</Tags>
  <Characters>Hero</Characters>
  <AgeRating>Everyone</AgeRating>
  <Summary>Original summary</Summary>
  <PageCount>2</PageCount>
</ComicInfo>"#;

        write_test_cbz(
            &source_cbz,
            &[("001.png", png.clone()), ("002.png", png)],
            Some(comicinfo),
        );

        let outcome = import_cbz(&mut library, &source_cbz.to_string_lossy()).expect("import");
        let edited = MetadataRecord {
            title: "Edited Title".to_string(),
            series: Some("Series B".to_string()),
            number: Some("7".to_string()),
            series_count: Some("12".to_string()),
            published_date: Some("2024-06-15".to_string()),
            language_iso: Some("zh-CN".to_string()),
            author: Some("Edited Author".to_string()),
            tags: Some("tag2".to_string()),
            characters: Some("Villain".to_string()),
            age_rating: Some("Teen".to_string()),
            description: Some("Edited summary".to_string()),
            cover_page_index: 1,
            page_count: 2,
        };
        library
            .update_project_metadata_inner(&outcome.project_id, edited)
            .expect("update metadata");

        let export_path = temp_dir("roundtrip-edit-out").join("edited.cbz");
        export_cbz(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export");

        let reimport_app_data = temp_dir("roundtrip-edit-reimport");
        let mut reimport_library = Library::open(reimport_app_data).expect("open reimport library");
        let reimport = import_cbz(
            &mut reimport_library,
            &export_path.to_string_lossy(),
        )
        .expect("reimport");

        let metadata = reimport_library
            .get_project_metadata_inner(&reimport.project_id)
            .expect("metadata");
        assert_eq!(metadata.title, "Edited Title");
        assert_eq!(metadata.series.as_deref(), Some("Series B"));
        assert_eq!(metadata.number.as_deref(), Some("7"));
        assert_eq!(metadata.series_count.as_deref(), Some("12"));
        assert_eq!(metadata.published_date.as_deref(), Some("2024-06-15"));
        assert_eq!(metadata.language_iso.as_deref(), Some("zh-CN"));
        assert_eq!(metadata.author.as_deref(), Some("Edited Author"));
        assert_eq!(metadata.tags.as_deref(), Some("tag2"));
        assert_eq!(metadata.characters.as_deref(), Some("Villain"));
        assert_eq!(metadata.age_rating.as_deref(), Some("Teen"));
        assert_eq!(metadata.description.as_deref(), Some("Edited summary"));
        assert_eq!(metadata.page_count, 2);
        assert_eq!(metadata.cover_page_index, 1);

        let (_, comicinfo_xml) = scan_cbz_entries(&export_path).expect("scan export");
        let parsed = parse_comicinfo_xml(&comicinfo_xml.expect("comicinfo")).expect("parse");
        assert_eq!(parsed.penciller.as_deref(), Some("Edited Author"));
        assert!(parsed.writer.is_none());
        assert_eq!(parsed.year.as_deref(), Some("2024"));
        assert_eq!(parsed.month.as_deref(), Some("6"));
        assert_eq!(parsed.day.as_deref(), Some("15"));
        assert_eq!(parsed.page_count.as_deref(), Some("2"));
    }

    #[test]
    fn rejects_export_without_pages() {
        let app_data = temp_dir("empty-export");
        let mut library = Library::open(app_data).expect("open library");
        let project = library
            .create_project_for_import(
                "Empty".to_string(),
                crate::project_format::InferredImportKind::Images,
                crate::project_format::ExportFormat::ComicArchive,
            )
            .expect("create project");
        let export_path = temp_dir("out").join("empty.cbz");

        let error = export_cbz(&library, &project.id, &export_path.to_string_lossy())
            .expect_err("empty project");
        assert!(matches!(error, ExportError { kind: ExportErrorKind::NoPages, .. }));
    }

    #[test]
    fn failed_export_preserves_existing_destination_file() {
        let app_data = temp_dir("atomic-preserve");
        let mut library = Library::open(app_data).expect("open library");
        let fixtures = temp_dir("atomic-fixtures");
        let source_cbz = fixtures.join("source.cbz");
        let png = png_bytes();
        write_test_cbz(&source_cbz, &[("001.png", png)], None);

        let outcome = import_cbz(&mut library, &source_cbz.to_string_lossy()).expect("import");
        let pages = library
            .list_pages_inner(&outcome.project_id)
            .expect("pages");
        let missing_asset = pages[0].absolute_path.clone();
        std::fs::remove_file(&missing_asset).expect("remove page asset");

        let export_path = temp_dir("atomic-out").join("existing.cbz");
        let seed = b"PRE-EXPORT-CONTENT";
        std::fs::write(&export_path, seed).expect("seed destination");

        let error = export_cbz(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect_err("missing page asset should fail export");

        assert_eq!(error.kind, ExportErrorKind::PageAssetMissing);
        assert_eq!(
            std::fs::read(&export_path).expect("read destination"),
            seed
        );
    }

    #[test]
    fn exports_cbz_with_comicinfo_and_pages() {
        let app_data = temp_dir("export");
        let mut library = Library::open(app_data).expect("open library");
        let fixtures = temp_dir("fixtures");
        let source_cbz = fixtures.join("source.cbz");
        let png = png_bytes();

        let comicinfo = r#"<?xml version="1.0"?>
<ComicInfo>
  <Title>Export Me</Title>
  <Series>Exported Series</Series>
  <Writer>Bob</Writer>
  <PageCount>2</PageCount>
  <Pages>
    <Page Image="0" Type="FrontCover" ImageSize="1"/>
    <Page Image="1" ImageSize="1"/>
  </Pages>
</ComicInfo>"#;

        write_test_cbz(
            &source_cbz,
            &[("001.png", png.clone()), ("002.png", png)],
            Some(comicinfo),
        );

        let outcome = import_cbz(&mut library, &source_cbz.to_string_lossy()).expect("import");

        let metadata_before = library
            .get_project_metadata_inner(&outcome.project_id)
            .expect("metadata before");
        let pages_before = library
            .list_pages_inner(&outcome.project_id)
            .expect("pages before");

        let export_path = temp_dir("cbz-out").join("exported.cbz");
        export_cbz(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export");

        let metadata_after = library
            .get_project_metadata_inner(&outcome.project_id)
            .expect("metadata after");
        let pages_after = library
            .list_pages_inner(&outcome.project_id)
            .expect("pages after");
        assert_eq!(metadata_before, metadata_after);
        assert_eq!(pages_before.len(), pages_after.len());

        let (page_paths, comicinfo) = scan_cbz_entries(&export_path).expect("scan export");
        assert_eq!(page_paths.len(), 2);
        assert_eq!(page_paths, vec!["00001.png", "00002.png"]);

        let parsed = parse_comicinfo_xml(&comicinfo.expect("comicinfo")).expect("parse");
        assert_eq!(parsed.title.as_deref(), Some("Export Me"));
        assert_eq!(parsed.series.as_deref(), Some("Exported Series"));
        assert_eq!(parsed.penciller.as_deref(), Some("Bob"));
        assert_eq!(cover_page_index_from_pages(&parsed.pages, 2, &[]), 0);
        assert!(parsed
            .pages
            .iter()
            .any(|page| { page.page_type.as_deref() == Some("FrontCover") && page.image == "0" }));
    }

    #[test]
    fn export_preserves_original_image_bytes() {
        let app_data = temp_dir("bytes");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let fixtures = temp_dir("bytes-fixtures");
        let source_cbz = fixtures.join("single.cbz");
        let png = png_bytes();
        write_test_cbz(&source_cbz, &[("page.png", png)], None);

        let outcome = import_cbz(&mut library, &source_cbz.to_string_lossy()).expect("import");

        let storage = crate::paths::project_storage_dir(&app_data, &outcome.project_id);
        let assets = project_assets_dir(&storage);
        let asset_file = std::fs::read_dir(&assets)
            .expect("read assets")
            .next()
            .expect("one asset")
            .expect("asset entry")
            .path();
        let asset_bytes = std::fs::read(&asset_file).expect("read asset");

        let export_path = temp_dir("bytes-out").join("bytes.cbz");
        export_cbz(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export");

        let file = File::open(&export_path).expect("open cbz");
        let mut archive = zip::ZipArchive::new(file).expect("open archive");
        let mut exported = archive.by_name("00001.png").expect("page entry");
        let mut exported_bytes = Vec::new();
        copy(&mut exported, &mut Cursor::new(&mut exported_bytes)).expect("read exported page");
        assert_eq!(asset_bytes, exported_bytes);
    }
}
