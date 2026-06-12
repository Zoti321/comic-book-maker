//! PDF archive export (image pages + ComicInfo embedded file + Document Info).

use std::fs;
use std::io::Cursor;
use std::path::{Path, PathBuf};

use image::ImageFormat;
use image::ImageReader;
use lopdf::content::{Content, Operation};
use lopdf::{text_string, Dictionary, Document, Object, Stream};

use crate::db::{Library, MetadataRecord, PageRecord};
use crate::export_atomic::atomic_write_destination;
use crate::export_cbz::{metadata_to_pdf_comicinfo_xml, pdf_document_author};
use crate::export_error::{ExportError, ExportErrorKind};
use crate::metadata_schema::normalize_comma_separated_tags;
use crate::page_image::normalize_extension;

const COMICINFO_EMBEDDED_NAME: &str = "ComicInfo.xml";

pub fn export_pdf(
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

    let project = library
        .find_project(project_id)
        .map_err(ExportError::from_library)?;
    let metadata = library
        .get_project_metadata_inner(project_id)
        .map_err(ExportError::from_library)?;
    let export_title = effective_export_title(&metadata, &project.title);

    let destination = PathBuf::from(destination_path);
    atomic_write_destination(&destination, |temp_path| {
        write_pdf(temp_path, &pages, &metadata, &export_title)
    })
}

fn effective_export_title(metadata: &MetadataRecord, project_title: &str) -> String {
    let trimmed = metadata.title.trim();
    if trimmed.is_empty() {
        project_title.trim().to_string()
    } else {
        trimmed.to_string()
    }
}

fn optional_trimmed(value: Option<&str>) -> Option<String> {
    value
        .map(str::trim)
        .filter(|text| !text.is_empty())
        .map(str::to_string)
}

fn pdf_supported_extension(extension: &str) -> bool {
    matches!(extension, "jpg" | "jpeg" | "png")
}

fn unsupported_format_error(extension: &str, asset_path: &str) -> ExportError {
    ExportError::new(
        ExportErrorKind::ArchiveWriteFailed,
        format!(
            "PDF 导出不支持 .{extension} 页图（{asset_path}）。请将页面替换为 JPEG 或 PNG 后重试。"
        ),
    )
}

enum PdfPageImage {
    Jpeg {
        width: u32,
        height: u32,
        bytes: Vec<u8>,
    },
    Png {
        width: u32,
        height: u32,
        rgb: Vec<u8>,
    },
}

impl PdfPageImage {
    fn width(&self) -> u32 {
        match self {
            Self::Jpeg { width, .. } | Self::Png { width, .. } => *width,
        }
    }

    fn height(&self) -> u32 {
        match self {
            Self::Jpeg { height, .. } | Self::Png { height, .. } => *height,
        }
    }
}

fn load_page_image(page: &PageRecord) -> Result<PdfPageImage, ExportError> {
    let extension = normalize_extension(Path::new(&page.asset_path))
        .map_err(ExportError::from_library)?;
    if !pdf_supported_extension(&extension) {
        return Err(unsupported_format_error(&extension, &page.asset_path));
    }

    let bytes = fs::read(&page.absolute_path).map_err(|error| {
        ExportError::map_open_page_asset(error, &page.absolute_path)
    })?;

    let (width, height) = ImageReader::new(Cursor::new(&bytes))
        .with_guessed_format()
        .map_err(|error| {
            ExportError::new(
                ExportErrorKind::PageAssetUnreadable,
                format!(
                    "detect image format for {}: {error}",
                    page.absolute_path
                ),
            )
        })?
        .into_dimensions()
        .map_err(|error| {
            ExportError::new(
                ExportErrorKind::PageAssetUnreadable,
                format!(
                    "read image dimensions for {}: {error}",
                    page.absolute_path
                ),
            )
        })?;

    match extension.as_str() {
        "jpg" | "jpeg" => Ok(PdfPageImage::Jpeg {
            width,
            height,
            bytes,
        }),
        "png" => {
            let decoded = image::load_from_memory_with_format(&bytes, ImageFormat::Png).map_err(
                |error| {
                    ExportError::new(
                        ExportErrorKind::PageAssetUnreadable,
                        format!("decode PNG page {}: {error}", page.absolute_path),
                    )
                },
            )?;
            Ok(PdfPageImage::Png {
                width,
                height,
                rgb: decoded.to_rgb8().into_raw(),
            })
        }
        _ => Err(unsupported_format_error(&extension, &page.asset_path)),
    }
}

fn write_pdf(
    destination: &Path,
    pages: &[PageRecord],
    metadata: &MetadataRecord,
    export_title: &str,
) -> Result<(), ExportError> {
    let page_images = pages
        .iter()
        .map(load_page_image)
        .collect::<Result<Vec<_>, _>>()?;

    let mut document = Document::with_version("1.5");
    let pages_id = document.new_object_id();
    let catalog_id = document.new_object_id();

    let mut page_ids = Vec::with_capacity(page_images.len());
    for image in &page_images {
        page_ids.push(build_pdf_page(&mut document, pages_id, image)?);
    }

    document.objects.insert(
        pages_id,
        Object::Dictionary(Dictionary::from_iter(vec![
            ("Type", Object::Name(b"Pages".to_vec())),
            (
                "Kids",
                Object::Array(page_ids.iter().copied().map(Object::Reference).collect()),
            ),
            ("Count", Object::Integer(page_ids.len() as i64)),
        ])),
    );

    document.objects.insert(
        catalog_id,
        Object::Dictionary(Dictionary::from_iter(vec![
            ("Type", Object::Name(b"Catalog".to_vec())),
            ("Pages", Object::Reference(pages_id)),
        ])),
    );

    let comicinfo_xml = metadata_to_pdf_comicinfo_xml(metadata, export_title, pages.len());
    attach_comicinfo_embedded_file(&mut document, catalog_id, &comicinfo_xml)?;

    let normalized_tags = metadata
        .tags
        .as_deref()
        .and_then(normalize_comma_separated_tags);
    let info_id = build_document_info(
        &mut document,
        export_title,
        pdf_document_author(metadata).as_deref(),
        optional_trimmed(metadata.summary.as_deref()).as_deref(),
        optional_trimmed(normalized_tags.as_deref()).as_deref(),
    );
    document.trailer.set("Root", Object::Reference(catalog_id));
    document.trailer.set("Info", Object::Reference(info_id));
    document
        .save(destination)
        .map(|_file| ())
        .map_err(|error| ExportError::map_archive_write("save PDF", error))
}

fn build_document_info(
    document: &mut Document,
    title: &str,
    author: Option<&str>,
    subject: Option<&str>,
    keywords: Option<&str>,
) -> (u32, u16) {
    let mut info = Dictionary::new();
    info.set("Title", text_string(title));
    if let Some(author) = author {
        info.set("Author", text_string(author));
    }
    if let Some(subject) = subject {
        info.set("Subject", text_string(subject));
    }
    if let Some(keywords) = keywords {
        info.set("Keywords", text_string(keywords));
    }
    document.add_object(Object::Dictionary(info))
}

fn attach_comicinfo_embedded_file(
    document: &mut Document,
    catalog_id: (u32, u16),
    comicinfo_xml: &str,
) -> Result<(), ExportError> {
    let content = comicinfo_xml.as_bytes();
    let embedded_stream_id = document.add_object(Object::Stream(Stream::new(
        Dictionary::from_iter(vec![
            ("Type", Object::Name(b"EmbeddedFile".to_vec())),
            ("Subtype", Object::Name(b"text/xml".to_vec())),
            (
                "Params",
                Object::Dictionary(Dictionary::from_iter(vec![(
                    "Size",
                    Object::Integer(content.len() as i64),
                )])),
            ),
        ]),
        content.to_vec(),
    )));

    let filespec_id = document.add_object(Object::Dictionary(Dictionary::from_iter(vec![
        ("Type", Object::Name(b"Filespec".to_vec())),
        ("F", Object::string_literal(COMICINFO_EMBEDDED_NAME)),
        ("UF", Object::string_literal(COMICINFO_EMBEDDED_NAME)),
        (
            "EF",
            Object::Dictionary(Dictionary::from_iter(vec![(
                "F",
                Object::Reference(embedded_stream_id),
            )])),
        ),
    ])));

    let embedded_files_id = document.add_object(Object::Dictionary(Dictionary::from_iter(vec![(
        "Names",
        Object::Array(vec![
            Object::string_literal(COMICINFO_EMBEDDED_NAME),
            Object::Reference(filespec_id),
        ]),
    )])));

    let names_id = document.add_object(Object::Dictionary(Dictionary::from_iter(vec![(
        "EmbeddedFiles",
        Object::Reference(embedded_files_id),
    )])));

    let catalog = document
        .objects
        .get_mut(&catalog_id)
        .ok_or_else(|| {
            ExportError::new(
                ExportErrorKind::ArchiveWriteFailed,
                "PDF catalog object missing while attaching ComicInfo.xml",
            )
        })?;
    if let Object::Dictionary(catalog) = catalog {
        catalog.set("Names", Object::Reference(names_id));
    }

    Ok(())
}

fn build_pdf_page(
    document: &mut Document,
    pages_id: (u32, u16),
    image: &PdfPageImage,
) -> Result<(u32, u16), ExportError> {
    let width = image.width();
    let height = image.height();
    let width_pt = width as f32;
    let height_pt = height as f32;

    let image_id = document.new_object_id();
    let content_id = document.new_object_id();
    let resources_id = document.new_object_id();
    let page_id = document.new_object_id();

    let image_name = b"Im1".to_vec();
    let image_object = match image {
        PdfPageImage::Jpeg { bytes, .. } => Object::Stream(Stream::new(
            Dictionary::from_iter(vec![
                ("Type", Object::Name(b"XObject".to_vec())),
                ("Subtype", Object::Name(b"Image".to_vec())),
                ("Width", Object::Integer(width as i64)),
                ("Height", Object::Integer(height as i64)),
                ("ColorSpace", Object::Name(b"DeviceRGB".to_vec())),
                ("BitsPerComponent", Object::Integer(8)),
                ("Filter", Object::Name(b"DCTDecode".to_vec())),
            ]),
            bytes.clone(),
        )),
        PdfPageImage::Png { rgb, .. } => Object::Stream(Stream::new(
            Dictionary::from_iter(vec![
                ("Type", Object::Name(b"XObject".to_vec())),
                ("Subtype", Object::Name(b"Image".to_vec())),
                ("Width", Object::Integer(width as i64)),
                ("Height", Object::Integer(height as i64)),
                ("ColorSpace", Object::Name(b"DeviceRGB".to_vec())),
                ("BitsPerComponent", Object::Integer(8)),
                ("Filter", Object::Name(b"FlateDecode".to_vec())),
            ]),
            rgb.clone(),
        )),
    };
    document.objects.insert(image_id, image_object);

    let content = Content {
        operations: vec![
            Operation::new("q", vec![]),
            Operation::new(
                "cm",
                vec![
                    Object::Real(width_pt),
                    Object::Real(0.0),
                    Object::Real(0.0),
                    Object::Real(height_pt),
                    Object::Real(0.0),
                    Object::Real(0.0),
                ],
            ),
            Operation::new("Do", vec![Object::Name(image_name.clone())]),
            Operation::new("Q", vec![]),
        ],
    };
    let content_data = content
        .encode()
        .map_err(|error| ExportError::map_archive_write("encode PDF content stream", error))?;
    document.objects.insert(
        content_id,
        Object::Stream(Stream::new(
            Dictionary::from_iter(vec![("Length", Object::Integer(content_data.len() as i64))]),
            content_data,
        )),
    );

    document.objects.insert(
        resources_id,
        Object::Dictionary(Dictionary::from_iter(vec![(
            "XObject",
            Object::Dictionary(Dictionary::from_iter(vec![(
                image_name,
                Object::Reference(image_id),
            )])),
        )])),
    );

    document.objects.insert(
        page_id,
        Object::Dictionary(Dictionary::from_iter(vec![
            ("Type", Object::Name(b"Page".to_vec())),
            ("Parent", Object::Reference(pages_id)),
            (
                "MediaBox",
                Object::Array(vec![
                    Object::Real(0.0),
                    Object::Real(0.0),
                    Object::Real(width_pt),
                    Object::Real(height_pt),
                ]),
            ),
            ("Resources", Object::Reference(resources_id)),
            ("Contents", Object::Reference(content_id)),
        ])),
    );

    Ok(page_id)
}

#[cfg(test)]
mod tests {
    use super::*;
    use lopdf::decode_text_string;
    use crate::db::Library;
    use crate::export_error::{ExportError, ExportErrorKind};
    use crate::import_cbz::import_cbz;
    use crate::paths::project_assets_dir;
    use image::{ImageBuffer, Rgba};
    use std::fs::File;
    use std::io::Write;
    use uuid::Uuid;
    use zip::write::SimpleFileOptions;
    use zip::ZipWriter;

    fn temp_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("cbm-export-pdf-{name}-{}", Uuid::new_v4()));
        fs::create_dir_all(&dir).expect("create temp dir");
        dir
    }

    fn png_bytes() -> Vec<u8> {
        let img = ImageBuffer::from_fn(8, 12, |_, _| Rgba([30u8, 90, 180, 255]));
        let mut buffer = Cursor::new(Vec::new());
        img.write_to(&mut buffer, ImageFormat::Png)
            .expect("encode png");
        buffer.into_inner()
    }

    fn jpeg_bytes(width: u32, height: u32) -> Vec<u8> {
        let img: ImageBuffer<image::Rgb<u8>, Vec<u8>> =
            ImageBuffer::from_fn(width, height, |_, _| image::Rgb([200u8, 100, 50]));
        let mut buffer = Cursor::new(Vec::new());
        img.write_to(&mut buffer, ImageFormat::Jpeg)
            .expect("encode jpeg");
        buffer.into_inner()
    }

    fn read_document_info_field(document: &Document, field: &[u8]) -> Option<String> {
        let info_id = document
            .trailer
            .get(b"Info")
            .and_then(Object::as_reference)
            .ok()?;
        let info = document.get_object(info_id).ok()?.as_dict().ok()?;
        let value = info.get(field).ok()?;
        decode_text_string(value).ok()
    }

    fn write_test_cbz(path: &Path, pages: &[(&str, Vec<u8>)]) {
        let file = File::create(path).expect("create cbz");
        let mut zip = ZipWriter::new(file);
        let options = SimpleFileOptions::default();
        for (name, content) in pages {
            zip.start_file(*name, options).expect("start page");
            zip.write_all(content).expect("write page");
        }
        zip.finish().expect("finish cbz");
    }

    #[test]
    fn export_pdf_fails_when_project_has_no_pages() {
        let app_data = temp_dir("empty");
        let mut library = Library::open(app_data).expect("open library");
        let project = library
            .create_project_inner(Some("Empty".to_string()))
            .expect("create project");
        let export_path = temp_dir("out").join("empty.pdf");

        let error = export_pdf(&library, &project.id, &export_path.to_string_lossy())
            .expect_err("empty project");
        assert!(matches!(
            error,
            ExportError {
                kind: ExportErrorKind::NoPages,
                ..
            }
        ));
    }

    #[test]
    fn export_pdf_writes_multi_page_document() {
        let app_data = temp_dir("multi");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let fixtures = temp_dir("fixtures");
        let source_cbz = fixtures.join("source.cbz");
        write_test_cbz(
            &source_cbz,
            &[
                ("001.jpg", jpeg_bytes(10, 20)),
                ("002.png", png_bytes()),
            ],
        );

        let outcome = import_cbz(&mut library, &source_cbz.to_string_lossy()).expect("import");
        let export_path = temp_dir("out").join("exported.pdf");
        export_pdf(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export pdf");

        let document = Document::load(&export_path).expect("load pdf");
        let page_count = document.get_pages().len();
        assert_eq!(page_count, 2);
    }

    #[test]
    fn export_pdf_fails_for_unsupported_page_format() {
        let app_data = temp_dir("webp");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let fixtures = temp_dir("fixtures");
        let source_cbz = fixtures.join("webp.cbz");
        let webp = {
            let img = ImageBuffer::from_fn(4, 4, |_, _| Rgba([1u8, 2, 3, 255]));
            let mut buffer = Cursor::new(Vec::new());
            img.write_to(&mut buffer, ImageFormat::WebP)
                .expect("encode webp");
            buffer.into_inner()
        };
        write_test_cbz(&source_cbz, &[("001.webp", webp)]);

        let outcome = import_cbz(&mut library, &source_cbz.to_string_lossy()).expect("import");
        let export_path = temp_dir("out").join("webp.pdf");
        let error = export_pdf(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect_err("webp should fail");

        assert_eq!(error.kind, ExportErrorKind::ArchiveWriteFailed);
        assert!(error.detail.contains("webp"));
        assert!(error.detail.contains("JPEG 或 PNG"));
    }

    #[test]
    fn export_pdf_fails_for_mixed_supported_and_unsupported_page_formats() {
        let app_data = temp_dir("mixed");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let fixtures = temp_dir("fixtures");
        let source_cbz = fixtures.join("mixed.cbz");
        let webp = {
            let img = ImageBuffer::from_fn(4, 4, |_, _| Rgba([1u8, 2, 3, 255]));
            let mut buffer = Cursor::new(Vec::new());
            img.write_to(&mut buffer, ImageFormat::WebP)
                .expect("encode webp");
            buffer.into_inner()
        };
        write_test_cbz(
            &source_cbz,
            &[
                ("001.jpg", jpeg_bytes(8, 8)),
                ("002.webp", webp),
            ],
        );

        let outcome = import_cbz(&mut library, &source_cbz.to_string_lossy()).expect("import");
        let export_path = temp_dir("out").join("mixed.pdf");
        let error = export_pdf(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect_err("mixed formats should fail");

        assert_eq!(error.kind, ExportErrorKind::ArchiveWriteFailed);
        assert!(error.detail.contains("webp"));
        assert!(!export_path.exists());
    }

    #[test]
    fn export_pdf_writes_comicinfo_and_document_info() {
        let app_data = temp_dir("meta");
        let mut library = Library::open(app_data).expect("open library");
        let fixtures = temp_dir("fixtures");
        let source_cbz = fixtures.join("meta.cbz");
        let comicinfo = r#"<?xml version="1.0"?>
<ComicInfo>
  <Title>Import Title</Title>
  <Series>Series A</Series>
  <Number>3</Number>
  <Count>12</Count>
  <Writer>Author Name</Writer>
  <Summary>About this comic</Summary>
  <Characters>Hero,Sidekick</Characters>
  <AgeRating>Teen</AgeRating>
  <Tags>action, drama</Tags>
  <PageCount>1</PageCount>
</ComicInfo>"#;
        write_test_cbz_with_comicinfo(
            &source_cbz,
            &[("001.png", png_bytes())],
            comicinfo,
        );

        let outcome = import_cbz(&mut library, &source_cbz.to_string_lossy()).expect("import");
        let export_path = temp_dir("out").join("meta.pdf");
        export_pdf(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export");

        let bytes = fs::read(&export_path).expect("read pdf");
        let embedded = String::from_utf8_lossy(&bytes);
        assert!(embedded.contains("<Series>Series A</Series>"));
        assert!(embedded.contains("<Number>3</Number>"));
        assert!(embedded.contains("<Count>12</Count>"));
        assert!(embedded.contains("<Writer>Author Name</Writer>"));
        assert!(embedded.contains("<PageCount>1</PageCount>"));
        assert!(!embedded.contains("<Publisher>"));

        let document = Document::load(&export_path).expect("load pdf");
        assert_eq!(
            read_document_info_field(&document, b"Title").as_deref(),
            Some("Import Title")
        );
        assert_eq!(
            read_document_info_field(&document, b"Author").as_deref(),
            Some("Author Name")
        );
        assert_eq!(
            read_document_info_field(&document, b"Subject").as_deref(),
            Some("About this comic")
        );
        assert_eq!(
            read_document_info_field(&document, b"Keywords").as_deref(),
            Some("action,drama")
        );
    }

    #[test]
    fn export_pdf_document_info_uses_penciller_for_author_when_writer_missing() {
        let app_data = temp_dir("penciller-author");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let fixtures = temp_dir("fixtures");
        let source_cbz = fixtures.join("penciller.cbz");
        write_test_cbz(&source_cbz, &[("001.png", png_bytes())]);

        let outcome = import_cbz(&mut library, &source_cbz.to_string_lossy()).expect("import");
        library
            .update_project_metadata_inner(
                &outcome.project_id,
                crate::db::MetadataRecord {
                    penciller: Some("Pencil Artist".to_string()),
                    ..library
                        .get_project_metadata_inner(&outcome.project_id)
                        .expect("metadata")
                },
            )
            .expect("update metadata");

        let export_path = temp_dir("out").join("penciller.pdf");
        export_pdf(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export");

        let bytes = fs::read(&export_path).expect("read pdf");
        let embedded = String::from_utf8_lossy(&bytes);
        assert!(embedded.contains("<Penciller>Pencil Artist</Penciller>"));
        assert!(!embedded.contains("<Writer>"));

        let document = Document::load(&export_path).expect("load pdf");
        assert_eq!(
            read_document_info_field(&document, b"Author").as_deref(),
            Some("Pencil Artist")
        );
    }

    #[test]
    fn export_pdf_document_info_merges_writer_and_penciller_for_author() {
        let app_data = temp_dir("merged-author");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let fixtures = temp_dir("fixtures");
        let source_cbz = fixtures.join("merged.cbz");
        write_test_cbz(&source_cbz, &[("001.png", png_bytes())]);

        let outcome = import_cbz(&mut library, &source_cbz.to_string_lossy()).expect("import");
        library
            .update_project_metadata_inner(
                &outcome.project_id,
                crate::db::MetadataRecord {
                    writer: Some("Script Writer".to_string()),
                    penciller: Some("Pencil Artist".to_string()),
                    ..library
                        .get_project_metadata_inner(&outcome.project_id)
                        .expect("metadata")
                },
            )
            .expect("update metadata");

        let export_path = temp_dir("out").join("merged.pdf");
        export_pdf(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export");

        let bytes = fs::read(&export_path).expect("read pdf");
        let embedded = String::from_utf8_lossy(&bytes);
        assert!(embedded.contains("<Writer>Script Writer</Writer>"));
        assert!(embedded.contains("<Penciller>Pencil Artist</Penciller>"));

        let document = Document::load(&export_path).expect("load pdf");
        assert_eq!(
            read_document_info_field(&document, b"Author").as_deref(),
            Some("Script Writer, Pencil Artist")
        );
    }

    #[test]
    fn export_pdf_document_info_preserves_unicode_text() {
        let app_data = temp_dir("unicode");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let fixtures = temp_dir("fixtures");
        let source_cbz = fixtures.join("unicode.cbz");
        write_test_cbz(&source_cbz, &[("001.png", png_bytes())]);

        let outcome = import_cbz(&mut library, &source_cbz.to_string_lossy()).expect("import");
        let title = "(C81) [アカギリ (清一)] 汚";
        let tags = "同人,漫画";
        library
            .update_project_metadata_inner(
                &outcome.project_id,
                crate::db::MetadataRecord {
                    title: title.to_string(),
                    tags: Some(tags.to_string()),
                    ..library
                        .get_project_metadata_inner(&outcome.project_id)
                        .expect("metadata")
                },
            )
            .expect("update metadata");

        let export_path = temp_dir("out").join("unicode.pdf");
        export_pdf(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export");

        let document = Document::load(&export_path).expect("load pdf");
        assert_eq!(
            read_document_info_field(&document, b"Title").as_deref(),
            Some(title)
        );
        assert_eq!(
            read_document_info_field(&document, b"Keywords").as_deref(),
            Some(tags)
        );
    }

    #[test]
    fn export_pdf_omits_empty_optional_comicinfo_fields() {
        let app_data = temp_dir("sparse");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let fixtures = temp_dir("fixtures");
        let source_cbz = fixtures.join("sparse.cbz");
        write_test_cbz(&source_cbz, &[("001.png", png_bytes())]);

        let outcome = import_cbz(&mut library, &source_cbz.to_string_lossy()).expect("import");
        library
            .update_project_metadata_inner(
                &outcome.project_id,
                crate::db::MetadataRecord {
                    title: "Sparse Title".to_string(),
                    ..library
                        .get_project_metadata_inner(&outcome.project_id)
                        .expect("metadata")
                },
            )
            .expect("update metadata");

        let export_path = temp_dir("out").join("sparse.pdf");
        export_pdf(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export");

        let pdf_bytes = fs::read(&export_path).expect("read pdf");
        let xml = String::from_utf8_lossy(&pdf_bytes);
        assert!(xml.contains("<Title>Sparse Title</Title>"));
        assert!(xml.contains("<PageCount>1</PageCount>"));
        assert!(!xml.contains("<Series>"));
        assert!(!xml.contains("<Writer>"));
    }

    fn write_test_cbz_with_comicinfo(path: &Path, pages: &[(&str, Vec<u8>)], comicinfo: &str) {
        let file = File::create(path).expect("create cbz");
        let mut zip = ZipWriter::new(file);
        let options = SimpleFileOptions::default();
        zip.start_file("ComicInfo.xml", options)
            .expect("start comicinfo");
        zip.write_all(comicinfo.as_bytes()).expect("write comicinfo");
        for (name, content) in pages {
            zip.start_file(*name, options).expect("start page");
            zip.write_all(content).expect("write page");
        }
        zip.finish().expect("finish cbz");
    }

    #[test]
    fn export_pdf_preserves_jpeg_page_bytes_in_storage() {
        let app_data = temp_dir("bytes");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let fixtures = temp_dir("fixtures");
        let source_cbz = fixtures.join("jpeg.cbz");
        let jpeg = jpeg_bytes(6, 8);
        write_test_cbz(&source_cbz, &[("page.jpg", jpeg.clone())]);

        let outcome = import_cbz(&mut library, &source_cbz.to_string_lossy()).expect("import");
        let storage = crate::paths::project_storage_dir(&app_data, &outcome.project_id);
        let assets = project_assets_dir(&storage);
        let asset_file = fs::read_dir(&assets)
            .expect("read assets")
            .filter_map(|entry| entry.ok())
            .map(|entry| entry.path())
            .find(|path| path.extension().is_some_and(|ext| ext == "jpg"))
            .expect("jpg asset");
        let stored_bytes = fs::read(&asset_file).expect("read asset");

        let export_path = temp_dir("out").join("jpeg.pdf");
        export_pdf(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export");

        let document = Document::load(&export_path).expect("load pdf");
        assert_eq!(document.get_pages().len(), 1);
        assert_eq!(stored_bytes, jpeg);
    }
}
