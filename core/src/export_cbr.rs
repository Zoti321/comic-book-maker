//! CBR (RAR) archive export via embedded `rars` (see `docs/third-party/rars.md`).

use std::fs;
use std::path::{Path, PathBuf};

use rars::rar50::{CompressedEntry, Rar50Writer, StoredEntry, WriterOptions};
use rars::{ArchiveReader, ArchiveVersion};

use crate::db::Library;
use crate::export_atomic::atomic_write_destination;
use crate::export_cbz::metadata_to_comicinfo_xml;
use crate::export_error::{ExportError, ExportErrorKind};
use crate::page_image::{cbz_zip_entry_name, normalize_extension};

const RAR50_FILE_ATTRIBUTES: u64 = 0x20;
const RAR50_HOST_OS: u64 = 3;

pub fn export_cbr(
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
    members.push(CbrMember {
        name: b"ComicInfo.xml".to_vec(),
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
        members.push(CbrMember {
            name: entry_name.into_bytes(),
            data,
        });
    }

    let archive_bytes = write_rar50_archive(&members)?;
    atomic_write_destination(&destination, |temp_path| {
        fs::write(temp_path, &archive_bytes)
            .map_err(|error| ExportError::map_create_destination(error, temp_path))
    })
}

struct CbrMember {
    name: Vec<u8>,
    data: Vec<u8>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
enum MemberCompressionPlan {
    Store,
    Compress,
}

fn write_rar50_archive(members: &[CbrMember]) -> Result<Vec<u8>, ExportError> {
    let plans: Vec<MemberCompressionPlan> = members
        .iter()
        .map(|member| plan_member_compression(&member.data))
        .collect::<Result<_, _>>()?;

    let use_store = plans.iter().all(|plan| *plan == MemberCompressionPlan::Store);
    let options = rar50_writer_options();

    if use_store {
        let stored: Vec<StoredEntry<'_>> = members
            .iter()
            .map(|member| StoredEntry {
                name: member.name.as_slice(),
                data: member.data.as_slice(),
                attributes: RAR50_FILE_ATTRIBUTES,
                host_os: RAR50_HOST_OS,
                mtime: None,
            })
            .collect();
        Rar50Writer::new(options)
            .stored_entries(&stored)
            .finish()
            .map_err(map_rars_error)
    } else {
        // `rars` 0.2.0 RAR5 writer rejects mixed stored/compressed members in one archive.
        // When plans differ, default to compressed for all members (ADR: compress by default).
        let compressed: Vec<CompressedEntry<'_>> = members
            .iter()
            .map(|member| CompressedEntry {
                name: member.name.as_slice(),
                data: member.data.as_slice(),
                attributes: RAR50_FILE_ATTRIBUTES,
                host_os: RAR50_HOST_OS,
                mtime: None,
            })
            .collect();
        Rar50Writer::new(options)
            .compressed_entries(&compressed)
            .finish()
            .map_err(map_rars_error)
    }
}

fn rar50_writer_options() -> WriterOptions {
    let mut options = WriterOptions::default();
    options.target = ArchiveVersion::Rar50;
    options
}

fn plan_member_compression(data: &[u8]) -> Result<MemberCompressionPlan, ExportError> {
    let packed_size = trial_compressed_packed_size(data)?;
    if packed_size >= data.len() as u64 {
        Ok(MemberCompressionPlan::Store)
    } else {
        Ok(MemberCompressionPlan::Compress)
    }
}

fn trial_compressed_packed_size(data: &[u8]) -> Result<u64, ExportError> {
    let entry = CompressedEntry {
        name: b"__cbm_trial__",
        data,
        attributes: RAR50_FILE_ATTRIBUTES,
        host_os: RAR50_HOST_OS,
        mtime: None,
    };
    let bytes = Rar50Writer::new(rar50_writer_options())
        .compressed_entries(&[entry])
        .finish()
        .map_err(map_rars_error)?;
    first_file_member_packed_size(&bytes)
}

fn first_file_member_packed_size(archive_bytes: &[u8]) -> Result<u64, ExportError> {
    let archive = ArchiveReader::read(archive_bytes).map_err(map_rars_error)?;
    archive
        .members()
        .find(|member| !member.meta.is_directory)
        .map(|member| member.meta.packed_size)
        .ok_or_else(|| ExportError::new(
            ExportErrorKind::ArchiveWriteFailed,
            "RAR trial archive missing file member",
        ))
}

fn map_rars_error(error: rars::Error) -> ExportError {
    ExportError::map_archive_write("write CBR", error)
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::export_error::{ExportError, ExportErrorKind};
    use crate::comicinfo::{cover_page_index_from_pages, parse_comicinfo_xml};
    use crate::import::scan_archive_tree;
    use crate::import_cbz::import_cbz;
    use crate::import_cbr::import_cbr;
    use crate::paths::{project_assets_dir, project_storage_dir};
    use image::{ImageBuffer, Rgba};
    use std::fs::File;
    use std::io::{Cursor, Write};
    use std::path::Path;
    use uuid::Uuid;
    use zip::write::SimpleFileOptions;
    use zip::ZipWriter;

    fn temp_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("cbm-export-cbr-{name}-{}", Uuid::new_v4()));
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

    fn assert_valid_rar50(bytes: &[u8]) {
        let archive = ArchiveReader::read(bytes).expect("parse exported CBR");
        assert!(archive.as_rar50().is_some(), "expected RAR 5.0 archive");
        let file_members: Vec<_> = archive
            .members()
            .filter(|member| !member.meta.is_directory)
            .collect();
        assert!(!file_members.is_empty(), "archive should contain file members");
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
        let export_path = temp_dir("out").join("empty.cbr");

        let error = export_cbr(&library, &project.id, &export_path.to_string_lossy())
            .expect_err("empty project");
        assert!(matches!(error, ExportError { kind: ExportErrorKind::NoPages, .. }));
    }

    #[test]
    fn exports_valid_rar50_archive() {
        let app_data = temp_dir("valid");
        let mut library = Library::open(app_data).expect("open library");
        let fixtures = temp_dir("fixtures");
        let source_cbz = fixtures.join("source.cbz");
        let png = png_bytes();
        write_test_cbz(&source_cbz, &[("001.png", png)], None);

        let outcome = import_cbz(&mut library, &source_cbz.to_string_lossy()).expect("import");
        let export_path = temp_dir("out").join("one-page.cbr");
        export_cbr(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export");

        let bytes = fs::read(&export_path).expect("read export");
        assert_valid_rar50(&bytes);
        unrar_ng::Archive::new(&export_path)
            .as_first_part()
            .open_for_processing()
            .expect("unrar-ng should open exported CBR");
    }

    #[test]
    fn roundtrip_export_cbr_import_cbr_preserves_metadata_and_pages() {
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
        let export_path = temp_dir("roundtrip-out").join("exported.cbr");
        export_cbr(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export");

        let reimport_app_data = temp_dir("roundtrip-reimport");
        let mut reimport_library = Library::open(reimport_app_data).expect("open reimport library");
        let reimport = import_cbr(
            &mut reimport_library,
            &export_path.to_string_lossy(),
        )
        .expect("reimport cbr");

        assert_eq!(reimport.title, "Export Me");
        let pages = reimport_library
            .list_pages_inner(&reimport.project_id)
            .expect("pages");
        assert_eq!(pages.len(), 2);

        let metadata = reimport_library
            .get_project_metadata_inner(&reimport.project_id)
            .expect("metadata");
        assert_eq!(metadata.title, "Export Me");
        assert_eq!(metadata.series.as_deref(), Some("Exported Series"));
        assert_eq!(metadata.writer.as_deref(), Some("Bob"));

        let extract_root = temp_dir("roundtrip-scan");
        let archive = unrar_ng::Archive::new(&export_path).as_first_part();
        archive
            .open_for_processing()
            .expect("open cbr")
            .extract_all(&extract_root)
            .expect("extract cbr");
        let (page_paths, comicinfo_xml) = scan_archive_tree(&extract_root).expect("scan");
        assert_eq!(page_paths, vec!["00001.png", "00002.png"]);

        let parsed = parse_comicinfo_xml(&comicinfo_xml.expect("comicinfo")).expect("parse");
        assert_eq!(parsed.title.as_deref(), Some("Export Me"));
        assert_eq!(parsed.series.as_deref(), Some("Exported Series"));
        assert_eq!(parsed.writer.as_deref(), Some("Bob"));
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

        let export_path = temp_dir("bytes-out").join("bytes.cbr");
        export_cbr(
            &library,
            &outcome.project_id,
            &export_path.to_string_lossy(),
        )
        .expect("export");

        let extract_root = temp_dir("bytes-extract");
        let archive = unrar_ng::Archive::new(&export_path).as_first_part();
        archive
            .open_for_processing()
            .expect("open cbr")
            .extract_all(&extract_root)
            .expect("extract");
        let exported_bytes = fs::read(extract_root.join("00001.png")).expect("read exported page");
        assert_eq!(asset_bytes, exported_bytes);
    }

    #[test]
    fn compression_plan_prefers_store_for_incompressible_payload() {
        let random = (0u8..255).collect::<Vec<_>>();
        let plan = plan_member_compression(&random).expect("plan");
        assert_eq!(plan, MemberCompressionPlan::Store);
    }

    #[test]
    fn export_uses_stored_members_when_all_payloads_are_incompressible() {
        let payload: Vec<u8> = (0u8..=255).collect();
        let members = vec![
            CbrMember {
                name: b"ComicInfo.xml".to_vec(),
                data: payload.clone(),
            },
            CbrMember {
                name: b"00001.png".to_vec(),
                data: payload,
            },
        ];

        let plans: Vec<_> = members
            .iter()
            .map(|member| plan_member_compression(&member.data))
            .collect::<Result<_, _>>()
            .expect("plan members");
        assert!(
            plans.iter().all(|plan| *plan == MemberCompressionPlan::Store),
            "fixture should plan store for all members: {plans:?}"
        );

        let bytes = write_rar50_archive(&members).expect("write archive");
        let archive = ArchiveReader::read(&bytes).expect("read archive");
        for member in archive.members().filter(|member| !member.meta.is_directory) {
            assert!(
                member.meta.is_stored,
                "expected stored member for incompressible payload, got {:?}",
                member.meta.name_lossy()
            );
        }
    }
}
