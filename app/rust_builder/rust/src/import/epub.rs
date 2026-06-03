//! EPUB archive import adapter.

use std::path::PathBuf;

use crate::db::Library;
use crate::epub_format::{metadata_from_opf, scan_epub_page_paths};
use crate::import_metadata_snapshot::ImportMetadataSnapshot;
use crate::project_format::{ExportFormat, InferredImportKind};

use super::archive_path::fallback_title_from_path;
use super::metadata::build_import_metadata;
use super::orchestration::{run_append_import, run_import_with_rollback};
use super::staging::stage_zip_pages;
use super::types::{AppendImportOutcome, ImportArchiveOutcome};

pub type ImportEpubOutcome = ImportArchiveOutcome;

pub fn import_epub(library: &mut Library, source_path: &str) -> Result<ImportEpubOutcome, String> {
    let path = PathBuf::from(source_path);
    if !path.is_file() {
        return Err(format!("EPUB file not found: {source_path}"));
    }

    let fallback_title = fallback_title_from_path(&path);
    let (page_paths, opf_metadata, comicinfo_xml, opf_metadata_xml) =
        scan_epub_page_paths(&path)?;
    if page_paths.is_empty() {
        return Err("EPUB 中未找到可用的 Page Image".to_string());
    }

    let page_count = page_paths.len() as i32;
    let (metadata, warnings) = if comicinfo_xml.is_some() {
        let (metadata, _, warnings) = build_import_metadata(
            &comicinfo_xml,
            opf_metadata
                .title
                .as_deref()
                .filter(|value| !value.trim().is_empty())
                .unwrap_or(&fallback_title),
            page_count,
            &page_paths,
        );
        (metadata, warnings)
    } else {
        (
            metadata_from_opf(&opf_metadata, &fallback_title, page_count),
            Vec::new(),
        )
    };

    let snapshot = snapshot_from_epub_scan(&comicinfo_xml, &opf_metadata_xml);

    run_import_with_rollback(
        library,
        metadata.title.clone(),
        InferredImportKind::Epub,
        ExportFormat::Epub,
        |library, project_id| {
            let staged = stage_zip_pages(
                library.app_data_dir(),
                project_id,
                &path,
                &page_paths,
                0,
            )?;
            Ok((metadata, staged, warnings, snapshot))
        },
    )
}

pub fn append_epub(
    library: &mut Library,
    project_id: &str,
    source_path: &str,
) -> Result<AppendImportOutcome, String> {
    let path = PathBuf::from(source_path);
    if !path.is_file() {
        return Err(format!("EPUB file not found: {source_path}"));
    }

    let fallback_title = fallback_title_from_path(&path);
    let (page_paths, _opf_metadata, comicinfo_xml, opf_metadata_xml) =
        scan_epub_page_paths(&path)?;
    if page_paths.is_empty() {
        return Err("EPUB 中未找到可用的 Page Image".to_string());
    }

    let (_, _, warnings) = build_import_metadata(
        &comicinfo_xml,
        &fallback_title,
        page_paths.len() as i32,
        &page_paths,
    );
    let snapshot = snapshot_from_epub_scan(&comicinfo_xml, &opf_metadata_xml);

    run_append_import(
        library,
        project_id,
        InferredImportKind::Epub,
        |library, project_id, start_sort_index| {
            let staged = stage_zip_pages(
                library.app_data_dir(),
                project_id,
                &path,
                &page_paths,
                start_sort_index,
            )?;
            Ok((staged, warnings, snapshot))
        },
    )
}

fn snapshot_from_epub_scan(
    comicinfo_xml: &Option<String>,
    opf_metadata_xml: &Option<String>,
) -> ImportMetadataSnapshot {
    if let Some(ref xml) = comicinfo_xml {
        ImportMetadataSnapshot::comicinfo(xml)
    } else if let Some(ref section) = opf_metadata_xml {
        ImportMetadataSnapshot::opf(section)
    } else {
        ImportMetadataSnapshot::none()
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::epub_format::write_minimal_epub;
    use crate::paths::project_cache_dir;
    use image::{ImageBuffer, Rgba};
    use std::io::Cursor;
    use uuid::Uuid;

    fn temp_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("cbm-import-epub-{name}-{}", Uuid::new_v4()));
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

    #[test]
    fn imports_epub_creates_project_with_metadata_and_thumbnail() {
        let app_data = temp_dir("app");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let dir = temp_dir("epub");
        let epub = dir.join("sample.epub");
        let png = png_bytes();

        write_minimal_epub(
            &epub,
            "Imported EPUB",
            &[
                ("page1.xhtml", "images/001.png", png.clone()),
                ("page2.xhtml", "images/002.png", png),
            ],
            Some(
                r#"<?xml version="1.0"?><ComicInfo><Title>ComicInfo Title</Title><PageCount>2</PageCount></ComicInfo>"#,
            ),
        );

        let outcome = import_epub(&mut library, &epub.to_string_lossy()).expect("import");
        assert_eq!(outcome.title, "ComicInfo Title");

        let pages = library.list_pages_inner(&outcome.project_id).expect("pages");
        assert_eq!(pages.len(), 2);

        let metadata = library
            .get_project_metadata_inner(&outcome.project_id)
            .expect("metadata");
        assert_eq!(metadata.page_count, 2);

        let storage = crate::paths::project_storage_dir(&app_data, &outcome.project_id);
        assert!(project_cache_dir(&storage).join("cover.webp").is_file());

        let snapshot = crate::import_metadata_snapshot::read_import_metadata_snapshot(
            &crate::paths::project_storage_dir(&app_data, &outcome.project_id),
        );
        assert_eq!(
            snapshot.kind,
            crate::import_metadata_snapshot::ImportMetadataKind::ComicInfo
        );
        assert!(snapshot.xml.as_deref().unwrap().contains("ComicInfo Title"));
    }

    #[test]
    fn imports_epub_uses_opf_metadata_without_comicinfo() {
        let app_data = temp_dir("opf");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let dir = temp_dir("epub-opf");
        let epub = dir.join("opf.epub");
        let png = png_bytes();

        write_minimal_epub(
            &epub,
            "OPF Title",
            &[("page1.xhtml", "images/1.png", png)],
            None,
        );

        let outcome = import_epub(&mut library, &epub.to_string_lossy()).expect("import");
        assert_eq!(outcome.title, "OPF Title");

        let metadata = library
            .get_project_metadata_inner(&outcome.project_id)
            .expect("metadata");
        assert_eq!(metadata.writer.as_deref(), Some("Test Author"));

        let snapshot = crate::import_metadata_snapshot::read_import_metadata_snapshot(
            &crate::paths::project_storage_dir(&app_data, &outcome.project_id),
        );
        assert_eq!(
            snapshot.kind,
            crate::import_metadata_snapshot::ImportMetadataKind::Opf
        );
        assert!(snapshot.xml.as_deref().unwrap().contains("<metadata"));
        assert!(snapshot.xml.as_deref().unwrap().contains("OPF Title"));
    }

    #[test]
    fn source_epub_is_not_modified() {
        let app_data = temp_dir("readonly");
        let mut library = Library::open(app_data).expect("open library");
        let dir = temp_dir("epub-readonly");
        let epub = dir.join("readonly.epub");
        let png = png_bytes();
        write_minimal_epub(
            &epub,
            "Readonly",
            &[("page1.xhtml", "images/1.png", png)],
            None,
        );

        let before = std::fs::metadata(&epub).expect("meta").len();
        import_epub(&mut library, &epub.to_string_lossy()).expect("import");
        let after = std::fs::metadata(&epub).expect("meta").len();
        assert_eq!(before, after);
    }
}
