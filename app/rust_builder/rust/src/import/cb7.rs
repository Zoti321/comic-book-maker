//! CB7 (7z) archive import via embedded `sevenz-rust2` (see `docs/third-party/sevenz-rust2.md`).

use std::path::{Path, PathBuf};

use sevenz_rust2::{decompress_file, Archive, Error as SevenZError};

use crate::db::Library;
use crate::import_metadata_snapshot::ImportMetadataSnapshot;
use crate::project_format::{ExportFormat, InferredImportKind};

use super::archive_path::fallback_title_from_path;
use super::metadata::build_import_metadata;
use super::orchestration::{run_append_import, run_import_with_rollback};
use super::staging::{scan_archive_tree, stage_pages_from_files};
use super::types::{AppendImportOutcome, ImportArchiveOutcome};

pub fn import_cb7(library: &mut Library, source_path: &str) -> Result<ImportArchiveOutcome, String> {
    let path = PathBuf::from(source_path);
    if !path.is_file() {
        return Err(format!("CB7 file not found: {source_path}"));
    }

    ensure_readable_cb7_archive(&path)?;

    let fallback_title = fallback_title_from_path(&path);
    let extract_root = temp_extract_dir()?;
    let import_result = import_cb7_from_extracted(
        library,
        &path,
        &extract_root,
        &fallback_title,
    );
    let _ = std::fs::remove_dir_all(&extract_root);
    import_result
}

pub fn append_cb7(
    library: &mut Library,
    project_id: &str,
    source_path: &str,
) -> Result<AppendImportOutcome, String> {
    let path = PathBuf::from(source_path);
    if !path.is_file() {
        return Err(format!("CB7 file not found: {source_path}"));
    }

    ensure_readable_cb7_archive(&path)?;

    let fallback_title = fallback_title_from_path(&path);
    let extract_root = temp_extract_dir()?;
    let append_result = append_cb7_from_extracted(
        library,
        project_id,
        &path,
        &extract_root,
        &fallback_title,
    );
    let _ = std::fs::remove_dir_all(&extract_root);
    append_result
}

fn append_cb7_from_extracted(
    library: &mut Library,
    project_id: &str,
    source: &Path,
    extract_root: &Path,
    fallback_title: &str,
) -> Result<AppendImportOutcome, String> {
    extract_cb7_to_directory(source, extract_root)?;

    let (page_rel_paths, comicinfo_xml) = scan_archive_tree(extract_root)?;
    if page_rel_paths.is_empty() {
        return Err("CB7 中未找到可用的 Page Image".to_string());
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

fn import_cb7_from_extracted(
    library: &mut Library,
    source: &Path,
    extract_root: &Path,
    fallback_title: &str,
) -> Result<ImportArchiveOutcome, String> {
    extract_cb7_to_directory(source, extract_root)?;

    let (page_rel_paths, comicinfo_xml) = scan_archive_tree(extract_root)?;
    if page_rel_paths.is_empty() {
        return Err("CB7 中未找到可用的 Page Image".to_string());
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

fn ensure_readable_cb7_archive(path: &Path) -> Result<(), String> {
    Archive::open(path)
        .map(|_| ())
        .map_err(map_sevenz_open_error)
}

fn temp_extract_dir() -> Result<PathBuf, String> {
    let dir = std::env::temp_dir().join(format!(
        "cbm-cb7-import-{}",
        uuid::Uuid::new_v4()
    ));
    std::fs::create_dir_all(&dir).map_err(|error| format!("create temp extract dir: {error}"))?;
    Ok(dir)
}

fn extract_cb7_to_directory(source: &Path, destination: &Path) -> Result<(), String> {
    decompress_file(source, destination).map_err(map_sevenz_extract_error)
}

fn map_sevenz_open_error(error: SevenZError) -> String {
    if is_password_protected_sevenz_error(&error) {
        return "CB7 已加密，当前不支持密码保护的归档".to_string();
    }
    let message = error.to_string();
    if message.trim().is_empty() {
        return "不是有效的 7Z/CB7 归档".to_string();
    }
    format!("不是有效的 7Z/CB7 归档: {message}")
}

fn map_sevenz_extract_error(error: SevenZError) -> String {
    if is_password_protected_sevenz_error(&error) {
        return "CB7 已加密，当前不支持密码保护的归档".to_string();
    }
    format!("解压 CB7: {error}")
}

fn is_password_protected_sevenz_error(error: &SevenZError) -> bool {
    matches!(
        error,
        SevenZError::PasswordRequired | SevenZError::MaybeBadPassword(_)
    ) || error
        .to_string()
        .to_ascii_lowercase()
        .contains("password")
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::paths::project_cache_dir;
    use image::{ImageBuffer, Rgba};
    use sevenz_rust2::{compress_to_path, compress_to_path_encrypted, Password};
    use uuid::Uuid;

    fn temp_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("cbm-cb7-{name}-{}", Uuid::new_v4()));
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

    fn create_test_cb7(path: &Path, pages: &[(&str, Vec<u8>)], comicinfo: Option<&str>) {
        let staging = temp_dir("staging");
        if let Some(xml) = comicinfo {
            std::fs::write(staging.join("ComicInfo.xml"), xml).expect("write comicinfo");
        }
        for (name, content) in pages {
            std::fs::write(staging.join(name), content).expect("write page");
        }

        compress_to_path(&staging, path).expect("compress cb7");
    }

    fn create_encrypted_test_cb7(path: &Path, pages: &[(&str, Vec<u8>)]) {
        let staging = temp_dir("encrypted-staging");
        for (name, content) in pages {
            std::fs::write(staging.join(name), content).expect("write page");
        }

        compress_to_path_encrypted(&staging, path, Password::from("secret"))
            .expect("compress encrypted cb7");
    }

    #[test]
    fn imports_cb7_with_comicinfo() {
        let app_data = temp_dir("app");
        let mut library = Library::open(app_data.clone()).expect("open library");
        let dir = temp_dir("cb7");
        let cb7 = dir.join("sample.cb7");
        let png = png_bytes();

        let comicinfo = r#"<?xml version="1.0"?>
<ComicInfo>
  <Title>CB7 Title</Title>
  <Series>CB7 Series</Series>
  <PageCount>2</PageCount>
</ComicInfo>"#;

        create_test_cb7(
            &cb7,
            &[("001.png", png.clone()), ("002.png", png)],
            Some(comicinfo),
        );

        let before = std::fs::metadata(&cb7).expect("meta").len();
        let outcome = import_cb7(&mut library, &cb7.to_string_lossy()).expect("import");
        let after = std::fs::metadata(&cb7).expect("meta").len();
        assert_eq!(before, after);

        assert_eq!(outcome.title, "CB7 Title");
        let pages = library.list_pages_inner(&outcome.project_id).expect("pages");
        assert_eq!(pages.len(), 2);
        assert!(project_cache_dir(&crate::paths::project_storage_dir(
            &app_data,
            &outcome.project_id
        ))
        .join("cover.webp")
        .is_file());
    }

    #[test]
    fn append_cb7_adds_pages_after_existing() {
        let app_data = temp_dir("append");
        let mut library = Library::open(app_data).expect("open library");
        let dir = temp_dir("cb7-append");
        let png = png_bytes();

        let initial_cb7 = dir.join("initial.cb7");
        create_test_cb7(
            &initial_cb7,
            &[("001.png", png.clone()), ("002.png", png.clone())],
            Some(r#"<ComicInfo><Title>Initial</Title></ComicInfo>"#),
        );

        let outcome = import_cb7(&mut library, &initial_cb7.to_string_lossy()).expect("import");
        let project_id = outcome.project_id.clone();

        let append_cb7_path = dir.join("append.cb7");
        create_test_cb7(
            &append_cb7_path,
            &[
                ("a.png", png.clone()),
                ("b.png", png.clone()),
                ("c.png", png),
            ],
            None,
        );

        let append_outcome =
            append_cb7(&mut library, &project_id, &append_cb7_path.to_string_lossy())
                .expect("append");
        assert_eq!(append_outcome.added_page_count, 3);

        let pages = library.list_pages_inner(&project_id).expect("pages");
        assert_eq!(pages.len(), 5);
    }

    #[test]
    fn rejects_encrypted_cb7() {
        let app_data = temp_dir("encrypted-app");
        let mut library = Library::open(app_data).expect("open library");
        let cb7 = temp_dir("encrypted").join("locked.cb7");
        create_encrypted_test_cb7(&cb7, &[("001.png", png_bytes())]);

        match import_cb7(&mut library, &cb7.to_string_lossy()) {
            Err(error) => assert!(
                error.contains("已加密") || error.contains("password"),
                "unexpected error: {error}"
            ),
            Ok(_) => panic!("expected encrypted cb7 import to fail"),
        }
    }

    #[test]
    fn rejects_cb7_without_pages() {
        let app_data = temp_dir("empty-app");
        let mut library = Library::open(app_data).expect("open library");
        let cb7 = temp_dir("empty").join("empty.cb7");
        create_test_cb7(&cb7, &[], Some("<ComicInfo/>"));

        match import_cb7(&mut library, &cb7.to_string_lossy()) {
            Err(error) => assert!(error.contains("未找到可用的 Page Image"), "{error}"),
            Ok(_) => panic!("expected empty cb7 import to fail"),
        }
    }
}
