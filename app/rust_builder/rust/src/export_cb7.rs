//! CB7 (7z) archive export via embedded `sevenz-rust2` (see `docs/third-party/sevenz-rust2.md`).

use std::fs;
use std::io::Cursor;
use std::path::{Path, PathBuf};

use sevenz_rust2::{ArchiveEntry, ArchiveWriter, EncoderConfiguration, EncoderMethod};

use crate::db::Library;
use crate::export_atomic::atomic_write_destination;
use crate::export_cbz::metadata_to_comicinfo_xml;
use crate::export_error::ExportError;
use crate::page_image::{cbz_zip_entry_name, normalize_extension};

pub fn export_cb7(
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

    let mut members = Vec::with_capacity(pages.len() + 1);
    members.push(Cb7Member {
        name: "ComicInfo.xml".to_string(),
        data: comicinfo_xml.into_bytes(),
    });

    let page_count = pages.len();
    for page in &pages {
        let extension = normalize_extension(Path::new(&page.asset_path))
            .map_err(ExportError::from_library)?;
        let entry_name = cbz_zip_entry_name(page.sort_index, page_count, &extension);
        let data = fs::read(&page.absolute_path).map_err(|error| {
            ExportError::map_read_page_asset(error, &page.absolute_path)
        })?;
        members.push(Cb7Member {
            name: entry_name,
            data,
        });
    }

    atomic_write_destination(&destination, |temp_path| write_cb7_archive(temp_path, &members))
}

struct Cb7Member {
    name: String,
    data: Vec<u8>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum MemberCompressionPlan {
    Store,
    Compress,
}

fn write_cb7_archive(temp_path: &Path, members: &[Cb7Member]) -> Result<(), ExportError> {
    let mut writer = ArchiveWriter::create(temp_path)
        .map_err(|error| ExportError::map_archive_write("create CB7 writer", error))?;
    writer.set_encrypt_header(false);

    for member in members {
        let plan = plan_member_compression(&member.data)?;
        let method = match plan {
            MemberCompressionPlan::Store => EncoderConfiguration::new(EncoderMethod::COPY),
            MemberCompressionPlan::Compress => EncoderConfiguration::new(EncoderMethod::LZMA2),
        };
        writer.set_content_methods(vec![method]);
        writer
            .push_archive_entry(
                ArchiveEntry::new_file(&member.name),
                Some(Cursor::new(member.data.as_slice())),
            )
            .map_err(|error| {
                ExportError::map_archive_write(
                    &format!("write CB7 entry {}", member.name),
                    error,
                )
            })?;
    }

    writer
        .finish()
        .map_err(|error| ExportError::map_archive_write("finalize CB7", error))?;
    Ok(())
}

fn plan_member_compression(data: &[u8]) -> Result<MemberCompressionPlan, ExportError> {
    let compressed_size = trial_lzma2_compressed_size(data)?;
    if compressed_size >= data.len() as u64 {
        Ok(MemberCompressionPlan::Store)
    } else {
        Ok(MemberCompressionPlan::Compress)
    }
}

fn trial_lzma2_compressed_size(data: &[u8]) -> Result<u64, ExportError> {
    let mut buffer = Cursor::new(Vec::<u8>::new());
    let mut writer = ArchiveWriter::new(&mut buffer)
        .map_err(|error| ExportError::map_archive_write("create CB7 trial writer", error))?;
    writer.set_encrypt_header(false);
    writer.set_content_methods(vec![EncoderConfiguration::new(EncoderMethod::LZMA2)]);
    let entry = writer
        .push_archive_entry(
            ArchiveEntry::new_file("__cbm_trial__"),
            Some(Cursor::new(data)),
        )
        .map_err(|error| ExportError::map_archive_write("write CB7 trial entry", error))?;
    let compressed_size = entry.compressed_size;
    writer
        .finish()
        .map_err(|error| ExportError::map_archive_write("finalize CB7 trial archive", error))?;
    Ok(compressed_size)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::comicinfo::{cover_page_index_from_pages, parse_comicinfo_xml};
    use crate::export_error::{ExportError, ExportErrorKind};
    use crate::import::scan_archive_tree;
    use crate::import::{import_cb7, import_cbz};
    use crate::paths::{project_assets_dir, project_storage_dir};
    use image::{ImageBuffer, Rgba};
    use sevenz_rust2::Archive;
    use std::fs::File;
    use std::io::Write;
    use uuid::Uuid;
    use zip::write::SimpleFileOptions;
    use zip::ZipWriter;

    fn temp_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("cbm-export-cb7-{name}-{}", Uuid::new_v4()));
        fs::create_dir_all(&dir).expect("create temp dir");
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

    fn assert_valid_cb7(path: &Path) {
        let archive = Archive::open(path).expect("parse exported CB7");
        let file_entries: Vec<_> = archive
            .files
            .iter()
            .filter(|entry| entry.has_stream() && !entry.is_directory())
            .collect();
        assert!(!file_entries.is_empty(), "archive should contain file entries");
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
        let export_path = temp_dir("out").join("empty.cb7");

        let error = export_cb7(&library, &project.id, &export_path.to_string_lossy())
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
    fn exports_valid_cb7_archive() {
        let app_data = temp_dir("valid");
        let mut library = Library::open(app_data).expect("open library");
        let fixtures = temp_dir("fixtures");
        let source_cbz = fixtures.join("source.cbz");
        let png = png_bytes();
        write_test_cbz(&source_cbz, &[("001.png", png)], None);

        let outcome = import_cbz(&mut library, &source_cbz.to_string_lossy()).expect("import");
        let export_path = temp_dir("out").join("one-page.cb7");
        export_cb7(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export");

        assert_valid_cb7(&export_path);
    }

    #[test]
    fn roundtrip_export_cb7_import_cb7_preserves_metadata_and_pages() {
        let app_data = temp_dir("roundtrip-src");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let fixtures = temp_dir("roundtrip-fixtures");
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
        let export_path = temp_dir("roundtrip-out").join("exported.cb7");
        export_cb7(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export");

        let reimport_app_data = temp_dir("roundtrip-reimport");
        let mut reimport_library = Library::open(reimport_app_data).expect("open reimport library");
        let reimport = import_cb7(
            &mut reimport_library,
            &export_path.to_string_lossy(),
        )
        .expect("reimport cb7");

        assert_eq!(reimport.title, "exported");
        let pages = reimport_library
            .list_pages_inner(&reimport.project_id)
            .expect("pages");
        assert_eq!(pages.len(), 2);

        let metadata = reimport_library
            .get_project_metadata_inner(&reimport.project_id)
            .expect("metadata");
        assert_eq!(metadata.title, "Export Me");
        assert_eq!(metadata.series.as_deref(), Some("Exported Series"));
        assert_eq!(metadata.author.as_deref(), Some("Bob"));

        let extract_root = temp_dir("roundtrip-scan");
        sevenz_rust2::decompress_file(&export_path, &extract_root).expect("extract cb7");
        let (page_paths, comicinfo_xml) = scan_archive_tree(&extract_root).expect("scan");
        assert_eq!(page_paths, vec!["00001.png", "00002.png"]);

        let parsed = parse_comicinfo_xml(&comicinfo_xml.expect("comicinfo")).expect("parse");
        assert_eq!(parsed.title.as_deref(), Some("Export Me"));
        assert_eq!(parsed.series.as_deref(), Some("Exported Series"));
        assert_eq!(parsed.penciller.as_deref(), Some("Bob"));
        assert_eq!(cover_page_index_from_pages(&parsed.pages, 2, &[]), 0);
    }

    #[test]
    fn roundtrip_preserves_original_image_bytes() {
        let app_data = temp_dir("bytes-src");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let fixtures = temp_dir("bytes-fixtures");
        let source_cbz = fixtures.join("single.cbz");
        let png = png_bytes();
        write_test_cbz(&source_cbz, &[("page.png", png)], None);

        let outcome = import_cbz(&mut library, &source_cbz.to_string_lossy()).expect("import");

        let storage = project_storage_dir(&app_data, &outcome.project_id);
        let assets = project_assets_dir(&storage);
        let asset_file = fs::read_dir(&assets)
            .expect("read assets")
            .next()
            .expect("one asset")
            .expect("asset entry")
            .path();
        let asset_bytes = fs::read(&asset_file).expect("read asset");

        let export_path = temp_dir("bytes-out").join("bytes.cb7");
        export_cb7(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export");

        let extract_root = temp_dir("bytes-extract");
        sevenz_rust2::decompress_file(&export_path, &extract_root).expect("extract");
        let exported_bytes = fs::read(extract_root.join("00001.png")).expect("read exported page");
        assert_eq!(asset_bytes, exported_bytes);
    }

    #[test]
    fn compression_plan_prefers_store_for_incompressible_payload() {
        let png = png_bytes();
        let plan = plan_member_compression(&png).expect("plan");
        assert_eq!(plan, MemberCompressionPlan::Store);
    }

    #[test]
    fn export_uses_stored_members_when_all_payloads_are_incompressible() {
        let payload = png_bytes();
        let members = vec![
            Cb7Member {
                name: "ComicInfo.xml".to_string(),
                data: payload.clone(),
            },
            Cb7Member {
                name: "00001.png".to_string(),
                data: payload,
            },
        ];

        let plans: Vec<_> = members
            .iter()
            .map(|member| plan_member_compression(&member.data))
            .collect::<Result<_, _>>()
            .expect("plan members");
        assert!(
            plans
                .iter()
                .all(|plan| *plan == MemberCompressionPlan::Store),
            "fixture should plan store for all members: {plans:?}"
        );

        let export_path = temp_dir("stored").join("stored.cb7");
        write_cb7_archive(&export_path, &members).expect("write archive");
        let archive = Archive::open(&export_path).expect("read archive");
        for entry in archive
            .files
            .iter()
            .filter(|entry| entry.has_stream() && !entry.is_directory())
        {
            assert_eq!(
                entry.compressed_size, entry.size,
                "expected stored member for incompressible payload, got {} compressed vs {} raw",
                entry.compressed_size, entry.size
            );
        }
    }
}
