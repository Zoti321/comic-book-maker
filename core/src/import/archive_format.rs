//! [Archive Format](CONTEXT.md) metadata and path inference for Import / Append.

use super::ArchiveImportFormat;

/// File-picker extensions for comic archive sources (container aliases included).
pub const COMIC_ARCHIVE_PICKER_EXTENSIONS: &[&str] =
    &["cbz", "zip", "cbr", "rar", "cb7", "7z"];

/// Infer [Archive Format] from a file path extension; `None` when unrecognized.
pub fn infer_archive_format_from_path(path: &str) -> Option<ArchiveImportFormat> {
    let ext = std::path::Path::new(path)
        .extension()?
        .to_str()?
        .to_ascii_lowercase();
    match ext.as_str() {
        "cbz" | "zip" => Some(ArchiveImportFormat::Cbz),
        "cbr" | "rar" => Some(ArchiveImportFormat::Cbr),
        "cb7" | "7z" => Some(ArchiveImportFormat::Cb7),
        "epub" => Some(ArchiveImportFormat::Epub),
        _ => None,
    }
}

/// Comic archive only (excludes EPUB); used when picking CBZ/CBR/CB7 without format preset.
pub fn infer_comic_archive_format_from_path(path: &str) -> Option<ArchiveImportFormat> {
    infer_archive_format_from_path(path).filter(|format| !matches!(format, ArchiveImportFormat::Epub))
}

pub fn archive_format_display_name(format: ArchiveImportFormat) -> &'static str {
    match format {
        ArchiveImportFormat::Cbz => "CBZ",
        ArchiveImportFormat::Cbr => "CBR",
        ArchiveImportFormat::Cb7 => "CB7",
        ArchiveImportFormat::Epub => "EPUB",
    }
}

pub fn archive_format_allowed_extensions(format: ArchiveImportFormat) -> &'static [&'static str] {
    match format {
        ArchiveImportFormat::Cbz => &["cbz"],
        ArchiveImportFormat::Cbr => &["cbr"],
        ArchiveImportFormat::Cb7 => &["cb7", "7z"],
        ArchiveImportFormat::Epub => &["epub"],
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn infer_maps_comic_archive_extensions() {
        assert_eq!(
            infer_comic_archive_format_from_path(r"C:\comic.cbz"),
            Some(ArchiveImportFormat::Cbz)
        );
        assert_eq!(
            infer_comic_archive_format_from_path("/books/comic.zip"),
            Some(ArchiveImportFormat::Cbz)
        );
        assert_eq!(
            infer_comic_archive_format_from_path("/books/comic.cbr"),
            Some(ArchiveImportFormat::Cbr)
        );
        assert_eq!(
            infer_comic_archive_format_from_path("/books/comic.rar"),
            Some(ArchiveImportFormat::Cbr)
        );
        assert_eq!(
            infer_comic_archive_format_from_path("/books/comic.cb7"),
            Some(ArchiveImportFormat::Cb7)
        );
        assert_eq!(
            infer_comic_archive_format_from_path("/books/comic.7z"),
            Some(ArchiveImportFormat::Cb7)
        );
        assert_eq!(
            infer_comic_archive_format_from_path("/books/comic.epub"),
            None
        );
        assert_eq!(
            infer_archive_format_from_path("/books/comic.epub"),
            Some(ArchiveImportFormat::Epub)
        );
    }
}
