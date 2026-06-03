use std::path::{Path, PathBuf};

const ALLOWED_EXTENSIONS: &[&str] = &["jpg", "jpeg", "png", "webp", "gif", "avif", "bmp"];

pub fn normalize_extension(path: &Path) -> Result<String, String> {
    let file_name = path
        .file_name()
        .and_then(|value| value.to_str())
        .ok_or_else(|| "invalid file path".to_string())?;

    let extension = Path::new(file_name)
        .extension()
        .and_then(|value| value.to_str())
        .map(str::to_ascii_lowercase)
        .ok_or_else(|| format!("unsupported image format: {file_name} (missing extension)"))?;

    if ALLOWED_EXTENSIONS.contains(&extension.as_str()) {
        Ok(extension)
    } else {
        Err(format!(
            "unsupported image format: .{extension} (supported: jpg, jpeg, png, webp, gif, avif, bmp)"
        ))
    }
}

pub fn asset_file_name(page_id: &str, extension: &str) -> String {
    format!("{page_id}.{extension}")
}

pub fn relative_asset_path(file_name: &str) -> String {
    format!("assets/{file_name}")
}

pub fn absolute_asset_path(storage_dir: &Path, asset_path: &str) -> PathBuf {
    storage_dir.join(asset_path)
}

/// Basename from an archive entry path (e.g. `pages/001.png` → `001.png`).
pub fn import_asset_file_name(entry_path: &str) -> Result<String, String> {
    let file_name = Path::new(entry_path)
        .file_name()
        .and_then(|value| value.to_str())
        .ok_or_else(|| format!("invalid archive entry path: {entry_path}"))?;
    normalize_extension(Path::new(file_name))?;
    Ok(file_name.to_string())
}

/// 1-based page number for CBZ zip entries (`00001`, `00002`, …).
/// Uses at least 5 digits so names stay stable for typical comic archives.
/// ComicInfo `Page@Image` is the separate 0-based index (`0`, `1`, …).
pub fn cbz_page_number(sort_index: i32, total_pages: usize) -> String {
    let width = 5_usize.max(total_pages.to_string().len());
    format!("{:0width$}", sort_index + 1, width = width)
}

/// Zip entry file name inside a CBZ (`00001.jpg`, `00002.png`, …).
pub fn cbz_zip_entry_name(sort_index: i32, total_pages: usize, extension: &str) -> String {
    format!("{}.{}", cbz_page_number(sort_index, total_pages), extension)
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn accepts_supported_extensions() {
        assert_eq!(
            normalize_extension(Path::new("page.JPG")).expect("jpg"),
            "jpg"
        );
        assert_eq!(
            normalize_extension(Path::new("/tmp/photo.avif")).expect("avif"),
            "avif"
        );
    }

    #[test]
    fn rejects_unsupported_extensions() {
        assert!(normalize_extension(Path::new("page.tiff")).is_err());
    }

    #[test]
    fn derives_import_name_from_archive_path() {
        assert_eq!(
            import_asset_file_name("pages/001.png").expect("import name"),
            "001.png"
        );
    }

    #[test]
    fn cbz_export_uses_zero_padded_page_numbers() {
        assert_eq!(cbz_page_number(0, 47), "00001");
        assert_eq!(cbz_page_number(46, 47), "00047");
        assert_eq!(
            cbz_zip_entry_name(1, 2, "png"),
            "00002.png"
        );
    }
}
