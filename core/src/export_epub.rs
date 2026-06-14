//! EPUB archive export.

use std::path::PathBuf;

use crate::db::Library;
use crate::epub_format::write_epub;
use crate::export_error::ExportError;

pub fn export_epub(
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
    let destination = PathBuf::from(destination_path);

    write_epub(&destination, &metadata, &pages)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::export_error::{ExportError, ExportErrorKind};
    use crate::epub_format::scan_epub_page_paths;
    use crate::import::{import_cbz, import_epub};
    use crate::paths::project_assets_dir;
    use image::{ImageBuffer, Rgba};
    use std::fs::File;
    use std::io::{copy, Cursor};
    use std::path::Path;
    use uuid::Uuid;
    use zip::write::SimpleFileOptions;
    use zip::ZipWriter;

    fn temp_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("cbm-export-epub-{name}-{}", Uuid::new_v4()));
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
        use std::io::Write;
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

    fn read_exported_opf(path: &Path) -> String {
        use std::io::Read;
        let file = File::open(path).expect("open epub");
        let mut archive = zip::ZipArchive::new(file).expect("open archive");
        let mut opf = archive
            .by_name("content.opf")
            .expect("content.opf should exist");
        let mut text = String::new();
        opf.read_to_string(&mut text).expect("read opf");
        text
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
        let export_path = temp_dir("out").join("empty.epub");

        let error = export_epub(&library, &project.id, &export_path.to_string_lossy())
            .expect_err("empty project");
        assert!(matches!(error, ExportError { kind: ExportErrorKind::NoPages, .. }));
    }

    #[test]
    fn exports_epub_roundtrip_preserves_project() {
        let app_data = temp_dir("export");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let fixtures = temp_dir("fixtures");
        let source_cbz = fixtures.join("source.cbz");
        let png = png_bytes();

        let comicinfo = r#"<?xml version="1.0"?>
<ComicInfo>
  <Title>Export EPUB</Title>
  <Series>SeriesName</Series>
  <Number>No.7</Number>
  <Volume>Vol.2</Volume>
  <Writer>Bob</Writer>
  <Publisher>Pub</Publisher>
  <LanguageISO>zh-TW</LanguageISO>
  <Web>https://example.com</Web>
  <GTIN>9781234567890</GTIN>
  <Summary>Summary</Summary>
  <Characters>角色A,角色B</Characters>
  <Tags>标签A,标签B</Tags>
  <PageCount>2</PageCount>
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

        let export_path = temp_dir("epub-out").join("exported.epub");
        export_epub(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export");

        let metadata_after = library
            .get_project_metadata_inner(&outcome.project_id)
            .expect("metadata after");
        assert_eq!(metadata_before, metadata_after);
        assert_eq!(pages_before.len(), metadata_after.page_count as usize);

        let opf = read_exported_opf(&export_path);
        assert!(opf.contains("<dc:title>Export EPUB</dc:title>"));
        assert!(opf.contains("<dc:series>SeriesName</dc:series>"));
        assert!(opf.contains("<dc:number>No.7</dc:number>"));
        assert!(opf.contains("<dc:creator>Bob</dc:creator>"));
        assert!(opf.contains("<dc:description>Summary</dc:description>"));
        assert!(opf.contains("<meta name=\"characters\" content=\"角色A,角色B\"/>"));
        assert!(opf.contains("<meta name=\"tags\" content=\"标签A,标签B\"/>"));
        assert!(opf.contains("<dc:identifier id=\"book-id\">Export EPUB</dc:identifier>"));
        assert!(opf.contains("<guide>"));
        assert!(opf.contains("type=\"cover\""));
        assert!(!opf.contains("ComicInfo"));
        assert_eq!(opf.matches("idref=\"Page_cover\"").count(), 1);
        let layout_pos = opf
            .find(r#"<meta property="rendition:layout">pre-paginated</meta>"#)
            .expect("rendition:layout meta");
        let title_pos = opf.find("<dc:title>").expect("dc:title");
        assert!(
            layout_pos < title_pos,
            "comic layout metadata should precede Dublin Core title"
        );
        assert!(opf.contains(r#"<meta property="rendition:spread">landscape</meta>"#));
        assert!(opf.contains(r#"<meta name="book-type" content="comic"/>"#));
        assert!(opf.contains(r#"<meta name="fixed-layout" content="true"/>"#));
        assert!(opf.contains(r#"<meta name="original-resolution" content="8x12"/>"#));
        assert!(opf.contains(r#"<meta name="characters" content="角色A,角色B"/>"#));
        assert!(opf.contains(r#"<meta name="tags" content="标签A,标签B"/>"#));

        let reimport = import_epub(&mut library, &export_path.to_string_lossy()).expect("reimport");
        assert_eq!(reimport.title, "exported");
        let reimport_metadata = library
            .get_project_metadata_inner(&reimport.project_id)
            .expect("reimport metadata");
        assert_eq!(reimport_metadata.characters.as_deref(), Some("角色A,角色B"));
        assert_eq!(reimport_metadata.tags.as_deref(), Some("标签A,标签B"));

        let reimported_pages = library
            .list_pages_inner(&reimport.project_id)
            .expect("reimported pages");
        assert!(reimported_pages.len() >= 2);
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

        let export_path = temp_dir("bytes-out").join("bytes.epub");
        export_epub(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export");

        let (page_paths, _, _, _, _) = scan_epub_page_paths(&export_path).expect("scan export");
        assert!(!page_paths.is_empty());

        let file = File::open(&export_path).expect("open epub");
        let mut archive = zip::ZipArchive::new(file).expect("open archive");
        let chosen_path = page_paths
            .iter()
            .find(|p| p.ends_with(".png"))
            .unwrap_or(&page_paths[0]);
        let mut exported = archive.by_name(chosen_path).expect("page entry");
        let mut exported_bytes = Vec::new();
        copy(&mut exported, &mut Cursor::new(&mut exported_bytes)).expect("read exported page");
        assert_eq!(asset_bytes, exported_bytes);
    }
}
