//! Staging page assets from ZIP archives or extracted file trees.

use std::fs::File;
use std::io::{copy, Read};
use std::path::{Path, PathBuf};

use uuid::Uuid;
use zip::read::ZipArchive;

use crate::epub_format::find_zip_entry;
use crate::natural_sort;
use crate::page_image::{cbz_page_number, import_asset_file_name, normalize_extension, relative_asset_path};
use crate::paths::{project_assets_dir, project_storage_dir};

use super::archive_path::{
    is_comicinfo_entry, is_ignored_entry, is_page_image_entry, normalize_archive_path,
};
use super::types::StagedImportPage;

pub fn scan_archive_tree(root: &Path) -> Result<(Vec<String>, Option<String>), String> {
    let mut page_paths = Vec::new();
    let mut comicinfo_xml = None;
    collect_archive_entries(root, root, &mut page_paths, &mut comicinfo_xml)?;
    natural_sort::sort_paths(&mut page_paths);
    Ok((page_paths, comicinfo_xml))
}

fn collect_archive_entries(
    root: &Path,
    current: &Path,
    page_paths: &mut Vec<String>,
    comicinfo_xml: &mut Option<String>,
) -> Result<(), String> {
    for entry in std::fs::read_dir(current).map_err(|error| format!("read directory: {error}"))? {
        let entry = entry.map_err(|error| format!("read directory entry: {error}"))?;
        let path = entry.path();
        if path.is_dir() {
            collect_archive_entries(root, &path, page_paths, comicinfo_xml)?;
            continue;
        }

        let relative = path
            .strip_prefix(root)
            .map_err(|_| format!("invalid path under archive root: {}", path.display()))?;
        let entry_path = normalize_archive_path(&relative.to_string_lossy())?;

        if is_ignored_entry(&entry_path) {
            continue;
        }

        if is_comicinfo_entry(&entry_path) {
            if comicinfo_xml.is_none() {
                let xml = std::fs::read_to_string(&path)
                    .map_err(|error| format!("read ComicInfo.xml: {error}"))?;
                *comicinfo_xml = Some(xml);
            }
            continue;
        }

        if is_page_image_entry(&entry_path) {
            page_paths.push(entry_path);
        }
    }

    Ok(())
}

pub fn scan_zip_archive(path: &Path) -> Result<(Vec<String>, Option<String>), String> {
    let file = File::open(path).map_err(|error| format!("open archive: {error}"))?;
    let mut archive =
        ZipArchive::new(file).map_err(|error| format!("read ZIP archive: {error}"))?;

    let mut page_paths = Vec::new();
    let mut comicinfo_xml = None;

    for index in 0..archive.len() {
        let mut entry = archive
            .by_index(index)
            .map_err(|error| format!("read ZIP entry {index}: {error}"))?;
        if entry.is_dir() {
            continue;
        }

        let entry_path = normalize_archive_path(entry.name())?;
        if is_ignored_entry(&entry_path) {
            continue;
        }

        if is_comicinfo_entry(&entry_path) {
            let mut xml = String::new();
            entry
                .read_to_string(&mut xml)
                .map_err(|error| format!("read ComicInfo.xml: {error}"))?;
            comicinfo_xml = Some(xml);
            continue;
        }

        if is_page_image_entry(&entry_path) {
            page_paths.push(entry_path);
        }
    }

    natural_sort::sort_paths(&mut page_paths);
    Ok((page_paths, comicinfo_xml))
}

pub fn stage_zip_pages(
    app_data_dir: &Path,
    project_id: &str,
    zip_path: &Path,
    page_paths: &[String],
    start_sort_index: i32,
) -> Result<Vec<StagedImportPage>, String> {
    let storage_dir = project_storage_dir(app_data_dir, project_id);
    let assets_dir = project_assets_dir(&storage_dir);
    std::fs::create_dir_all(&assets_dir).map_err(|error| format!("create assets dir: {error}"))?;

    let file = File::open(zip_path).map_err(|error| format!("reopen archive: {error}"))?;
    let mut archive =
        ZipArchive::new(file).map_err(|error| format!("read ZIP archive: {error}"))?;

    let mut staged = Vec::with_capacity(page_paths.len());
    let mut sort_index = start_sort_index;
    for entry_path in page_paths {
        let mut entry = find_zip_entry(&mut archive, entry_path)?;
        let _extension = normalize_extension(Path::new(entry_path))?;
        let page_id = Uuid::new_v4().to_string();
        let file_name = import_asset_file_name(entry_path)?;
        let asset_path = relative_asset_path(&file_name);
        let destination = assets_dir.join(&file_name);

        {
            let mut output = File::create(&destination)
                .map_err(|error| format!("create page asset {}: {error}", destination.display()))?;
            copy(&mut entry, &mut output)
                .map_err(|error| format!("extract page {}: {error}", entry_path))?;
        }

        staged.push(StagedImportPage {
            page_id,
            sort_index,
            asset_path,
        });
        sort_index += 1;
    }

    Ok(staged)
}

pub fn stage_pages_from_files(
    app_data_dir: &Path,
    project_id: &str,
    page_files: &[PathBuf],
    start_sort_index: i32,
) -> Result<Vec<StagedImportPage>, String> {
    let storage_dir = project_storage_dir(app_data_dir, project_id);
    let assets_dir = project_assets_dir(&storage_dir);
    std::fs::create_dir_all(&assets_dir).map_err(|error| format!("create assets dir: {error}"))?;

    let mut staged = Vec::with_capacity(page_files.len());
    let mut sort_index = start_sort_index;
    for source in page_files {
        let _extension = normalize_extension(source)?;
        let page_id = Uuid::new_v4().to_string();
        let file_name = source
            .file_name()
            .and_then(|value| value.to_str())
            .map(str::to_string)
            .ok_or_else(|| format!("invalid page file path: {}", source.display()))?;
        import_asset_file_name(&file_name)?;
        let asset_path = relative_asset_path(&file_name);
        let destination = assets_dir.join(&file_name);

        std::fs::copy(source, &destination).map_err(|error| {
            format!(
                "copy page image {}: {error}",
                source.display()
            )
        })?;

        staged.push(StagedImportPage {
            page_id,
            sort_index,
            asset_path,
        });
        sort_index += 1;
    }

    Ok(staged)
}

pub fn stage_pdf_pages(
    app_data_dir: &Path,
    project_id: &str,
    pages: &[crate::pdf_format::ExtractedPdfPage],
    start_sort_index: i32,
) -> Result<Vec<StagedImportPage>, String> {
    let storage_dir = project_storage_dir(app_data_dir, project_id);
    let assets_dir = project_assets_dir(&storage_dir);
    std::fs::create_dir_all(&assets_dir).map_err(|error| format!("create assets dir: {error}"))?;

    let mut staged = Vec::with_capacity(pages.len());
    let mut sort_index = start_sort_index;
    for page in pages {
        let page_id = Uuid::new_v4().to_string();
        let file_name = format!(
            "{}.{}",
            cbz_page_number(sort_index, pages.len()),
            page.extension
        );
        let asset_path = relative_asset_path(&file_name);
        let destination = assets_dir.join(&file_name);
        std::fs::write(&destination, &page.bytes)
            .map_err(|error| format!("write page asset {}: {error}", destination.display()))?;

        staged.push(StagedImportPage {
            page_id,
            sort_index,
            asset_path,
        });
        sort_index += 1;
    }

    Ok(staged)
}

pub fn remove_staged_page_assets(
    app_data_dir: &Path,
    project_id: &str,
    pages: &[StagedImportPage],
) {
    let storage_dir = project_storage_dir(app_data_dir, project_id);
    for page in pages {
        let asset_path = storage_dir.join(&page.asset_path);
        if asset_path.is_file() {
            let _ = std::fs::remove_file(asset_path);
        }
    }
}
