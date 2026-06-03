//! CBR (RAR) archive import via embedded UnRAR (see `docs/third-party/unrar.md`).

use std::path::{Path, PathBuf};

use unrar_ng::Archive;

use crate::db::Library;
use crate::import_metadata_snapshot::ImportMetadataSnapshot;
use crate::project_format::{ExportFormat, InferredImportKind};

use super::archive_path::fallback_title_from_path;
use super::metadata::build_import_metadata;
use super::orchestration::{run_append_import, run_import_with_rollback};
use super::staging::{scan_archive_tree, stage_pages_from_files};
use super::types::{AppendImportOutcome, ImportArchiveOutcome};

pub fn import_cbr(library: &mut Library, source_path: &str) -> Result<ImportArchiveOutcome, String> {
    let path = PathBuf::from(source_path);
    if !path.is_file() {
        return Err(format!("CBR file not found: {source_path}"));
    }

    if !Archive::new(&path).is_archive() {
        return Err("不是有效的 RAR/CBR 归档".to_string());
    }

    let fallback_title = fallback_title_from_path(&path);
    let extract_root = temp_extract_dir()?;
    let import_result = import_cbr_from_extracted(
        library,
        &path,
        &extract_root,
        &fallback_title,
    );
    let _ = std::fs::remove_dir_all(&extract_root);
    import_result
}

pub fn append_cbr(
    library: &mut Library,
    project_id: &str,
    source_path: &str,
) -> Result<AppendImportOutcome, String> {
    let path = PathBuf::from(source_path);
    if !path.is_file() {
        return Err(format!("CBR file not found: {source_path}"));
    }

    if !Archive::new(&path).is_archive() {
        return Err("不是有效的 RAR/CBR 归档".to_string());
    }

    let fallback_title = fallback_title_from_path(&path);
    let extract_root = temp_extract_dir()?;
    let append_result = append_cbr_from_extracted(
        library,
        project_id,
        &path,
        &extract_root,
        &fallback_title,
    );
    let _ = std::fs::remove_dir_all(&extract_root);
    append_result
}

fn append_cbr_from_extracted(
    library: &mut Library,
    project_id: &str,
    source: &Path,
    extract_root: &Path,
    fallback_title: &str,
) -> Result<AppendImportOutcome, String> {
    extract_cbr_to_directory(source, extract_root)?;

    let (page_rel_paths, comicinfo_xml) = scan_archive_tree(extract_root)?;
    if page_rel_paths.is_empty() {
        return Err("CBR 中未找到可用的 Page Image".to_string());
    }

    let page_files: Vec<PathBuf> = page_rel_paths
        .iter()
        .map(|rel| extract_root.join(rel))
        .collect();

    let (_, _, warnings) = build_import_metadata(
        &comicinfo_xml,
        fallback_title,
        page_rel_paths.len() as i32,
        &page_rel_paths,
    );
    let snapshot = ImportMetadataSnapshot::from_comicinfo_xml(&comicinfo_xml);

    run_append_import(
        library,
        project_id,
        InferredImportKind::ComicArchive,
        |library, project_id, start_sort_index| {
            let staged = stage_pages_from_files(
                library.app_data_dir(),
                project_id,
                &page_files,
                start_sort_index,
            )?;
            Ok((staged, warnings, snapshot))
        },
    )
}

fn import_cbr_from_extracted(
    library: &mut Library,
    source: &Path,
    extract_root: &Path,
    fallback_title: &str,
) -> Result<ImportArchiveOutcome, String> {
    extract_cbr_to_directory(source, extract_root)?;

    let (page_rel_paths, comicinfo_xml) = scan_archive_tree(extract_root)?;
    if page_rel_paths.is_empty() {
        return Err("CBR 中未找到可用的 Page Image".to_string());
    }

    let page_files: Vec<PathBuf> = page_rel_paths
        .iter()
        .map(|rel| extract_root.join(rel))
        .collect();

    let (metadata, _, warnings) = build_import_metadata(
        &comicinfo_xml,
        fallback_title,
        page_rel_paths.len() as i32,
        &page_rel_paths,
    );
    let snapshot = ImportMetadataSnapshot::from_comicinfo_xml(&comicinfo_xml);

    run_import_with_rollback(
        library,
        metadata.title.clone(),
        InferredImportKind::ComicArchive,
        ExportFormat::ComicArchive,
        |library, project_id| {
            let staged = stage_pages_from_files(
                library.app_data_dir(),
                project_id,
                &page_files,
                0,
            )?;
            Ok((metadata, staged, warnings, snapshot))
        },
    )
}

fn temp_extract_dir() -> Result<PathBuf, String> {
    let dir = std::env::temp_dir().join(format!(
        "cbm-cbr-import-{}",
        uuid::Uuid::new_v4()
    ));
    std::fs::create_dir_all(&dir).map_err(|error| format!("create temp extract dir: {error}"))?;
    Ok(dir)
}

fn extract_cbr_to_directory(source: &Path, destination: &Path) -> Result<(), String> {
    let archive = Archive::new(source).as_first_part();
    let open = archive
        .open_for_processing()
        .map_err(map_unrar_error)?;

    open.extract_all(destination)
        .map_err(map_unrar_error)?;

    Ok(())
}

fn map_unrar_error(error: impl std::fmt::Display) -> String {
    let message = error.to_string();
    if message.to_ascii_lowercase().contains("password") {
        return "CBR 已加密，当前不支持密码保护的归档".to_string();
    }
    format!("解压 CBR: {message}")
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::import::staging::scan_archive_tree;
    use crate::paths::project_cache_dir;
    use image::{ImageBuffer, Rgba};
    use std::process::Command;
    use uuid::Uuid;

    fn temp_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("cbm-cbr-{name}-{}", Uuid::new_v4()));
        std::fs::create_dir_all(&dir).expect("create temp dir");
        dir
    }

    fn png_bytes() -> Vec<u8> {
        let img = ImageBuffer::from_fn(8, 12, |_, _| Rgba([30u8, 90, 180, 255]));
        let mut buffer = std::io::Cursor::new(Vec::new());
        img.write_to(&mut buffer, image::ImageFormat::Png)
            .expect("encode png");
        buffer.into_inner()
    }

    fn rar_available() -> bool {
        Command::new("rar")
            .arg("?")
            .status()
            .map(|status| status.success())
            .unwrap_or(false)
    }

    fn create_test_cbr(path: &Path, pages: &[(&str, Vec<u8>)], comicinfo: Option<&str>) {
        let staging = temp_dir("staging");
        if let Some(xml) = comicinfo {
            std::fs::write(staging.join("ComicInfo.xml"), xml).expect("write comicinfo");
        }
        for (name, content) in pages {
            std::fs::write(staging.join(name), content).expect("write page");
        }

        let output = Command::new("rar")
            .arg("a")
            .arg("-ep1")
            .arg(path)
            .arg(staging.join("*"))
            .output()
            .expect("run rar");

        if !output.status.success() {
            panic!(
                "rar failed: {}",
                String::from_utf8_lossy(&output.stderr)
            );
        }
    }

    #[test]
    fn scan_extracted_tree_matches_cbz_scan_order() {
        let root = temp_dir("tree");
        let png = png_bytes();
        std::fs::create_dir_all(root.join("pages")).expect("mkdir");
        std::fs::write(root.join("pages/10.png"), &png).expect("write");
        std::fs::write(root.join("pages/2.png"), &png).expect("write");
        std::fs::write(root.join("pages/1.png"), &png).expect("write");
        std::fs::write(root.join("ComicInfo.xml"), "<ComicInfo/>").expect("write");

        let (pages, comicinfo) = scan_archive_tree(&root).expect("scan");
        assert_eq!(pages, vec!["pages/1.png", "pages/2.png", "pages/10.png"]);
        assert!(comicinfo.is_some());
    }

    #[test]
    fn imports_cbr_when_rar_cli_available() {
        if !rar_available() {
            eprintln!("skip imports_cbr_when_rar_cli_available: rar CLI not found");
            return;
        }

        let app_data = temp_dir("app");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let dir = temp_dir("cbr");
        let cbr = dir.join("sample.cbr");
        let png = png_bytes();

        let comicinfo = r#"<?xml version="1.0"?>
<ComicInfo>
  <Title>CBR Title</Title>
  <Series>CBR Series</Series>
  <PageCount>2</PageCount>
</ComicInfo>"#;

        create_test_cbr(
            &cbr,
            &[("001.png", png.clone()), ("002.png", png)],
            Some(comicinfo),
        );

        let before = std::fs::metadata(&cbr).expect("meta").len();
        let outcome = import_cbr(&mut library, &cbr.to_string_lossy()).expect("import");
        let after = std::fs::metadata(&cbr).expect("meta").len();
        assert_eq!(before, after);

        assert_eq!(outcome.title, "CBR Title");
        let pages = library.list_pages_inner(&outcome.project_id).expect("pages");
        assert_eq!(pages.len(), 2);
        assert!(project_cache_dir(&crate::paths::project_storage_dir(&app_data, &outcome.project_id))
            .join("cover.webp")
            .is_file());
    }
}
