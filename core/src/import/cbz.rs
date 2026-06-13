//! CBZ (ZIP) archive import adapter.

use std::path::PathBuf;

use crate::db::Library;
use crate::project_format::{ExportFormat, InferredImportKind};

use super::archive_path::fallback_title_from_path;
use super::metadata::build_import_metadata;
use super::orchestration::{run_append_import, run_import_with_rollback};
use super::staging::{scan_zip_archive, stage_zip_pages};
use super::types::{AppendImportOutcome, ImportArchiveOutcome};

pub type ImportCbzOutcome = ImportArchiveOutcome;

pub fn import_cbz(library: &mut Library, source_path: &str) -> Result<ImportCbzOutcome, String> {
    let path = PathBuf::from(source_path);
    if !path.is_file() {
        return Err(format!("CBZ file not found: {source_path}"));
    }

    let fallback_title = fallback_title_from_path(&path);
    let (page_paths, comicinfo_xml) = scan_cbz_entries(&path)?;
    if page_paths.is_empty() {
        return Err("CBZ 中未找到可用的 Page Image".to_string());
    }

    let (metadata, _, warnings) = build_import_metadata(
        &comicinfo_xml,
        &fallback_title,
        page_paths.len() as i32,
        &page_paths,
    );
    run_import_with_rollback(
        library,
        fallback_title.clone(),
        InferredImportKind::ComicArchive,
        ExportFormat::ComicArchive,
        |library, project_id| {
            let staged = stage_zip_pages(
                library.app_data_dir(),
                project_id,
                &path,
                &page_paths,
                0,
            )?;
            Ok((metadata, staged, warnings))
        },
    )
}

pub fn append_cbz(
    library: &mut Library,
    project_id: &str,
    source_path: &str,
) -> Result<AppendImportOutcome, String> {
    let path = PathBuf::from(source_path);
    if !path.is_file() {
        return Err(format!("CBZ file not found: {source_path}"));
    }

    let fallback_title = fallback_title_from_path(&path);
    let (page_paths, comicinfo_xml) = scan_cbz_entries(&path)?;
    if page_paths.is_empty() {
        return Err("CBZ 中未找到可用的 Page Image".to_string());
    }

    let (_, _, warnings) = build_import_metadata(
        &comicinfo_xml,
        &fallback_title,
        page_paths.len() as i32,
        &page_paths,
    );
    run_append_import(
        library,
        project_id,
        InferredImportKind::ComicArchive,
        |library, project_id, start_sort_index| {
            let staged = stage_zip_pages(
                library.app_data_dir(),
                project_id,
                &path,
                &page_paths,
                start_sort_index,
            )?;
            Ok((staged, warnings))
        },
    )
}

pub fn scan_cbz_entries(path: &std::path::Path) -> Result<(Vec<String>, Option<String>), String> {
    scan_zip_archive(path)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::paths::project_cache_dir;
    use image::{ImageBuffer, Rgba};
    use std::fs::File;
    use std::io::{Cursor, Write};
    use std::path::Path;
    use uuid::Uuid;
    use zip::write::SimpleFileOptions;
    use zip::ZipWriter;

    fn temp_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("cbm-import-{name}-{}", Uuid::new_v4()));
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

    fn write_test_cbz(
        path: &Path,
        pages: &[(&str, Vec<u8>)],
        comicinfo: Option<&str>,
        extras: &[(&str, Vec<u8>)],
    ) {
        let file = File::create(path).expect("create cbz");
        let mut zip = ZipWriter::new(file);
        let options = SimpleFileOptions::default();

        if let Some(xml) = comicinfo {
            zip.start_file("ComicInfo.xml", options)
                .expect("start comicinfo");
            zip.write_all(xml.as_bytes()).expect("write comicinfo");
        }

        for (name, content) in extras {
            zip.start_file(*name, options).expect("start extra");
            zip.write_all(content).expect("write extra");
        }

        for (name, content) in pages {
            zip.start_file(*name, options).expect("start page");
            zip.write_all(content).expect("write page");
        }

        zip.finish().expect("finish cbz");
    }

    #[test]
    fn natural_sorts_pages_and_ignores_non_images() {
        let dir = temp_dir("scan");
        let cbz = dir.join("test.cbz");
        let png = png_bytes();
        write_test_cbz(
            &cbz,
            &[
                ("pages/10.png", png.clone()),
                ("pages/2.png", png.clone()),
                ("pages/1.png", png.clone()),
            ],
            None,
            &[
                ("__MACOSX/._1.png", b"meta".to_vec()),
                ("ComicInfo.xml", b"<ComicInfo/>".to_vec()),
            ],
        );

        let (pages, comicinfo) = scan_cbz_entries(&cbz).expect("scan");
        assert_eq!(pages, vec!["pages/1.png", "pages/2.png", "pages/10.png"]);
        assert!(comicinfo.is_some());
    }

    #[test]
    fn imports_cbz_creates_project_with_metadata_and_thumbnail() {
        let app_data = temp_dir("app");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let dir = temp_dir("cbz");
        let cbz = dir.join("sample.cbz");
        let png = png_bytes();

        let comicinfo = r#"<?xml version="1.0"?>
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
  <Tags>tag1,tag2</Tags>
  <Characters>CharA</Characters>
  <AgeRating>Everyone</AgeRating>
  <Summary>A summary</Summary>
  <PageCount>2</PageCount>
</ComicInfo>"#;

        write_test_cbz(
            &cbz,
            &[("001.png", png.clone()), ("002.png", png)],
            Some(comicinfo),
            &[],
        );

        let outcome = import_cbz(&mut library, &cbz.to_string_lossy()).expect("import");
        assert_eq!(outcome.title, "sample");
        assert!(outcome.warnings.is_empty());

        let pages = library.list_pages_inner(&outcome.project_id).expect("pages");
        assert_eq!(pages.len(), 2);
        assert_eq!(pages[0].sort_index, 0);
        assert_eq!(pages[1].sort_index, 1);
        assert!(pages[0].asset_path.ends_with("001.png"));
        assert!(pages[1].asset_path.ends_with("002.png"));

        let metadata = library
            .get_project_metadata_inner(&outcome.project_id)
            .expect("metadata");
        assert_eq!(metadata.title, "Imported Title");
        assert_eq!(metadata.series.as_deref(), Some("Sample Series"));
        assert_eq!(metadata.number.as_deref(), Some("7"));
        assert_eq!(metadata.series_count.as_deref(), Some("12"));
        assert_eq!(metadata.published_date.as_deref(), Some("2024-05-31"));
        assert_eq!(metadata.language_iso.as_deref(), Some("zh-CN"));
        assert_eq!(metadata.author.as_deref(), Some("Alice, Bob"));
        assert_eq!(metadata.tags.as_deref(), Some("tag1,tag2"));
        assert_eq!(metadata.characters.as_deref(), Some("CharA"));
        assert_eq!(metadata.age_rating.as_deref(), Some("Everyone"));
        assert_eq!(metadata.description.as_deref(), Some("A summary"));
        assert_eq!(metadata.page_count, 2);

        let storage = crate::paths::project_storage_dir(&app_data, &outcome.project_id);
        assert!(project_cache_dir(&storage).join("cover.webp").is_file());
    }

    #[test]
    fn imports_cbz_without_comicinfo_uses_filename_title() {
        let app_data = temp_dir("no-comicinfo");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let cbz = temp_dir("cbz-none").join("plain.cbz");
        write_test_cbz(&cbz, &[("1.png", png_bytes())], None, &[]);

        let outcome = import_cbz(&mut library, &cbz.to_string_lossy()).expect("import");
        let metadata = library
            .get_project_metadata_inner(&outcome.project_id)
            .expect("metadata");
        assert_eq!(metadata.title, "plain");
        assert_eq!(metadata.page_count, 1);
    }

    #[test]
    fn imports_cbz_with_pagecount_warning() {
        let app_data = temp_dir("warn");
        let mut library = Library::open(app_data).expect("open library");
        let dir = temp_dir("cbz-warn");
        let cbz = dir.join("warn.cbz");
        let png = png_bytes();

        write_test_cbz(
            &cbz,
            &[("1.png", png.clone())],
            Some(
                r#"<ComicInfo><Title>Warn</Title><PageCount>99</PageCount></ComicInfo>"#,
            ),
            &[],
        );

        let outcome = import_cbz(&mut library, &cbz.to_string_lossy()).expect("import");
        assert_eq!(outcome.warnings.len(), 1);
        assert!(outcome.warnings[0].contains("PageCount"));
    }

    #[test]
    fn append_cbz_adds_pages_after_existing() {
        let app_data = temp_dir("append");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let dir = temp_dir("cbz-append");
        let png = png_bytes();

        let initial_cbz = dir.join("initial.cbz");
        write_test_cbz(
            &initial_cbz,
            &[
                ("001.png", png.clone()),
                ("002.png", png.clone()),
                ("003.png", png.clone()),
            ],
            Some(r#"<ComicInfo><Title>Initial</Title></ComicInfo>"#),
            &[],
        );

        let outcome = import_cbz(&mut library, &initial_cbz.to_string_lossy()).expect("import");
        let project_id = outcome.project_id.clone();

        let append_cbz_path = dir.join("append.cbz");
        let append_comicinfo = r#"<ComicInfo><Title>Appended</Title></ComicInfo>"#;
        write_test_cbz(
            &append_cbz_path,
            &[
                ("a.png", png.clone()),
                ("b.png", png.clone()),
                ("c.png", png.clone()),
                ("d.png", png.clone()),
                ("e.png", png),
            ],
            Some(append_comicinfo),
            &[],
        );

        let append_outcome =
            append_cbz(&mut library, &project_id, &append_cbz_path.to_string_lossy())
                .expect("append");
        assert_eq!(append_outcome.added_page_count, 5);

        let settings = library
            .get_project_settings_inner(&project_id)
            .expect("settings");
        assert_eq!(
            settings.inferred_import_kind,
            InferredImportKind::ComicArchive
        );

        let pages = library.list_pages_inner(&project_id).expect("pages");
        assert_eq!(pages.len(), 8);
        assert_eq!(pages[0].sort_index, 0);
        assert_eq!(pages[2].sort_index, 2);
        assert_eq!(pages[3].sort_index, 3);
        assert_eq!(pages[7].sort_index, 7);
    }

    #[test]
    fn source_cbz_is_not_modified() {
        let app_data = temp_dir("readonly");
        let mut library = Library::open(app_data).expect("open library");
        let dir = temp_dir("cbz-readonly");
        let cbz = dir.join("readonly.cbz");
        let png = png_bytes();
        write_test_cbz(&cbz, &[("a.png", png)], None, &[]);

        let before = std::fs::metadata(&cbz).expect("meta").len();
        import_cbz(&mut library, &cbz.to_string_lossy()).expect("import");
        let after = std::fs::metadata(&cbz).expect("meta").len();
        assert_eq!(before, after);
    }
}
