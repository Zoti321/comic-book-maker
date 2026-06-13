//! PDF archive import adapter (minimal Document Info metadata + image pages).

use std::path::PathBuf;

use crate::db::{normalize_metadata, Library};
use crate::pdf_format::{metadata_from_pdf_document_info, scan_pdf};
use crate::project_format::{ExportFormat, InferredImportKind};

use super::archive_path::fallback_title_from_path;
use super::orchestration::run_import_with_rollback;
use super::staging::stage_pdf_pages;
use super::types::ImportArchiveOutcome;

pub type ImportPdfOutcome = ImportArchiveOutcome;

pub fn import_pdf(library: &mut Library, source_path: &str) -> Result<ImportPdfOutcome, String> {
    let path = PathBuf::from(source_path);
    if !path.is_file() {
        return Err(format!("PDF file not found: {source_path}"));
    }

    let fallback_title = fallback_title_from_path(&path);
    let (info, pages) = scan_pdf(&path)?;
    let page_count = pages.len() as i32;
    let metadata = normalize_metadata(metadata_from_pdf_document_info(
        &info,
        &fallback_title,
        page_count,
    ));

    run_import_with_rollback(
        library,
        fallback_title.to_string(),
        InferredImportKind::Pdf,
        ExportFormat::Pdf,
        |library, project_id| {
            let staged = stage_pdf_pages(library.app_data_dir(), project_id, &pages, 0)?;
            Ok((metadata, staged, Vec::new()))
        },
    )
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::export_pdf::export_pdf;
    use crate::pdf_format::{write_test_pdf_with_document_info, ParsedPdfDocumentInfo};
    use image::{ImageBuffer, Rgba};
    use std::io::Cursor;
    use uuid::Uuid;

    fn temp_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("cbm-import-pdf-{name}-{}", Uuid::new_v4()));
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

    fn png_bytes() -> Vec<u8> {
        let img = ImageBuffer::from_fn(8, 12, |_, _| Rgba([30u8, 90, 180, 255]));
        let mut buffer = Cursor::new(Vec::new());
        img.write_to(&mut buffer, image::ImageFormat::Png)
            .expect("encode png");
        buffer.into_inner()
    }

    #[test]
    fn imports_pdf_maps_document_info_to_canonical_metadata() {
        let app_data = temp_dir("app");
        let mut library = Library::open(app_data).expect("open library");
        let dir = temp_dir("pdf");
        let pdf = dir.join("sample.pdf");

        write_test_pdf_with_document_info(
            &pdf,
            &ParsedPdfDocumentInfo {
                title: Some("Imported PDF".to_string()),
                author: Some("PDF Author".to_string()),
                subject: Some("Description text".to_string()),
                keywords: Some("action, drama".to_string()),
                creation_date: Some("D:20230615".to_string()),
                ..Default::default()
            },
            &jpeg_bytes(),
        );

        let outcome = import_pdf(&mut library, &pdf.to_string_lossy()).expect("import");
        assert_eq!(outcome.title, "sample");

        let metadata = library
            .get_project_metadata_inner(&outcome.project_id)
            .expect("metadata");
        assert_eq!(metadata.author.as_deref(), Some("PDF Author"));
        assert_eq!(metadata.description.as_deref(), Some("Description text"));
        assert_eq!(metadata.tags.as_deref(), Some("action,drama"));
        assert_eq!(metadata.published_date.as_deref(), Some("2023-06-15"));
        assert!(metadata.series.is_none());
        assert!(metadata.number.is_none());
    }

    #[test]
    fn pdf_import_export_reimport_preserves_minimal_metadata() {
        let app_data = temp_dir("roundtrip");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let dir = temp_dir("pdf-roundtrip");
        let source_pdf = dir.join("source.pdf");

        write_test_pdf_with_document_info(
            &source_pdf,
            &ParsedPdfDocumentInfo {
                title: Some("Roundtrip PDF".to_string()),
                author: Some("Alice, Bob".to_string()),
                subject: Some("About this comic".to_string()),
                keywords: Some("标签A,标签B".to_string()),
                ..Default::default()
            },
            &jpeg_bytes(),
        );

        let imported = import_pdf(&mut library, &source_pdf.to_string_lossy()).expect("import");
        let export_path = dir.join("exported.pdf");
        export_pdf(
            &library,
            &imported.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export");

        let document = lopdf::Document::load(&export_path).expect("load export");
        let embedded = std::fs::read(&export_path).expect("read export bytes");
        let embedded_text = String::from_utf8_lossy(&embedded);
        assert!(!embedded_text.contains("<Series>"));
        assert!(!embedded_text.contains("<Number>"));

        let info = crate::pdf_format::parse_pdf_document_info(&document);
        assert_eq!(info.title.as_deref(), Some("Roundtrip PDF"));
        assert_eq!(info.author.as_deref(), Some("Alice, Bob"));
        assert_eq!(info.subject.as_deref(), Some("About this comic"));
        assert_eq!(info.keywords.as_deref(), Some("标签A,标签B"));

        let reimported = import_pdf(&mut library, &export_path.to_string_lossy()).expect("reimport");
        let roundtrip = library
            .get_project_metadata_inner(&reimported.project_id)
            .expect("roundtrip metadata");
        assert_eq!(roundtrip.title, "Roundtrip PDF");
        assert_eq!(roundtrip.author.as_deref(), Some("Alice, Bob"));
        assert_eq!(roundtrip.description.as_deref(), Some("About this comic"));
        assert_eq!(roundtrip.tags.as_deref(), Some("标签A,标签B"));
    }

    #[test]
    fn imports_pdf_extracts_png_pages_from_exported_pdf() {
        let app_data = temp_dir("png");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let dir = temp_dir("fixtures");
        let source_cbz = dir.join("source.cbz");
        let png = png_bytes();
        write_test_cbz(&source_cbz, &[("001.png", png.clone())]);

        let outcome =
            crate::import_cbz::import_cbz(&mut library, &source_cbz.to_string_lossy()).expect("import cbz");
        let export_path = dir.join("exported.pdf");
        export_pdf(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export");

        let reimported = import_pdf(&mut library, &export_path.to_string_lossy()).expect("reimport");
        let pages = library
            .list_pages_inner(&reimported.project_id)
            .expect("pages");
        assert_eq!(pages.len(), 1);
    }

    fn write_test_cbz(path: &std::path::Path, pages: &[(&str, Vec<u8>)]) {
        use std::fs::File;
        use std::io::Write;
        use zip::write::SimpleFileOptions;
        use zip::ZipWriter;

        let file = File::create(path).expect("create cbz");
        let mut zip = ZipWriter::new(file);
        let options = SimpleFileOptions::default();
        for (name, content) in pages {
            zip.start_file(*name, options).expect("start page");
            zip.write_all(content).expect("write page");
        }
        zip.finish().expect("finish cbz");
    }
}
