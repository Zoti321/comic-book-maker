//! Archive entry path rules shared by ZIP and extracted-tree Import adapters.

use std::path::Path;

use crate::comicinfo::COMICINFO_XML_NAMES;
use crate::page_image::normalize_extension;

pub fn normalize_archive_path(raw: &str) -> Result<String, String> {
    let normalized = raw.replace('\\', "/");
    if normalized.contains("..") {
        return Err(format!("unsafe archive path: {raw}"));
    }
    Ok(normalized.trim_start_matches("./").to_string())
}

pub fn is_ignored_entry(path: &str) -> bool {
    if path.contains("__MACOSX") {
        return true;
    }
    let file_name = path.rsplit('/').next().unwrap_or(path);
    if file_name.starts_with('.') || file_name.eq_ignore_ascii_case(".ds_store") {
        return true;
    }
    false
}

pub fn is_comicinfo_entry(path: &str) -> bool {
    let file_name = path.rsplit('/').next().unwrap_or(path);
    COMICINFO_XML_NAMES
        .iter()
        .any(|name| file_name.eq_ignore_ascii_case(name))
}

pub fn is_page_image_entry(path: &str) -> bool {
    normalize_extension(Path::new(path)).is_ok()
}

pub fn fallback_title_from_path(path: &Path) -> String {
    path.file_stem()
        .and_then(|value| value.to_str())
        .unwrap_or("未命名")
        .to_string()
}
