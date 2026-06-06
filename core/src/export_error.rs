//! Structured errors for Archive Format Export.

use std::io;
use std::path::Path;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
#[flutter_rust_bridge::frb]
pub enum ExportErrorKind {
    DestinationExists,
    DestinationIsDirectory,
    DestinationNotWritable,
    DestinationLocked,
    DestinationFinalizeFailed,
    PageAssetMissing,
    PageAssetUnreadable,
    InsufficientSpace,
    ArchiveWriteFailed,
    NoPages,
    ProjectNotFound,
    DeleteAfterExportFailed,
}

#[derive(Debug, Clone, PartialEq, Eq)]
#[flutter_rust_bridge::frb]
pub struct ExportError {
    pub kind: ExportErrorKind,
    pub detail: String,
}

impl std::fmt::Display for ExportError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        if self.detail.is_empty() {
            write!(f, "{:?}", self.kind)
        } else {
            write!(f, "{:?}: {}", self.kind, self.detail)
        }
    }
}

impl std::error::Error for ExportError {}

impl ExportError {
    pub fn new(kind: ExportErrorKind, detail: impl Into<String>) -> Self {
        Self {
            kind,
            detail: detail.into(),
        }
    }

    pub fn no_pages() -> Self {
        Self::new(ExportErrorKind::NoPages, "")
    }

    pub fn from_library(message: String) -> Self {
        if message.contains("project not found") {
            Self::new(ExportErrorKind::ProjectNotFound, message)
        } else {
            Self::new(ExportErrorKind::ArchiveWriteFailed, message)
        }
    }

    pub fn ensure_destination_is_file(destination: &Path) -> Result<(), Self> {
        if destination.exists() && destination.is_dir() {
            return Err(Self::new(
                ExportErrorKind::DestinationIsDirectory,
                format!(
                    "export destination is a directory: {}",
                    destination.display()
                ),
            ));
        }
        Ok(())
    }

    pub fn map_create_directory(error: io::Error, path: &Path) -> Self {
        let detail = format!("create export directory {}: {error}", path.display());
        if is_insufficient_space(&error) {
            Self::new(ExportErrorKind::InsufficientSpace, detail)
        } else {
            Self::new(ExportErrorKind::DestinationNotWritable, detail)
        }
    }

    pub fn map_create_destination(error: io::Error, path: &Path) -> Self {
        let detail = format!("create export file {}: {error}", path.display());
        if is_insufficient_space(&error) {
            return Self::new(ExportErrorKind::InsufficientSpace, detail);
        }
        match error.kind() {
            io::ErrorKind::PermissionDenied if path.exists() => {
                Self::new(ExportErrorKind::DestinationLocked, detail)
            }
            io::ErrorKind::PermissionDenied => {
                Self::new(ExportErrorKind::DestinationNotWritable, detail)
            }
            io::ErrorKind::AlreadyExists => Self::new(ExportErrorKind::DestinationExists, detail),
            _ => Self::new(ExportErrorKind::ArchiveWriteFailed, detail),
        }
    }

    pub fn map_open_page_asset(error: io::Error, path: &str) -> Self {
        let detail = format!("open page asset {path}: {error}");
        if error.kind() == io::ErrorKind::NotFound {
            Self::new(ExportErrorKind::PageAssetMissing, detail)
        } else {
            Self::new(ExportErrorKind::PageAssetUnreadable, detail)
        }
    }

    pub fn map_read_page_asset(error: io::Error, path: &str) -> Self {
        let detail = format!("read page asset {path}: {error}");
        if error.kind() == io::ErrorKind::NotFound {
            Self::new(ExportErrorKind::PageAssetMissing, detail)
        } else {
            Self::new(ExportErrorKind::PageAssetUnreadable, detail)
        }
    }

    pub fn map_archive_write(context: &str, error: impl std::fmt::Display) -> Self {
        let detail = format!("{context}: {error}");
        if detail.to_ascii_lowercase().contains("no space")
            || detail.to_ascii_lowercase().contains("disk full")
        {
            Self::new(ExportErrorKind::InsufficientSpace, detail)
        } else {
            Self::new(ExportErrorKind::ArchiveWriteFailed, detail)
        }
    }
}

fn is_insufficient_space(error: &io::Error) -> bool {
    matches!(
        error.kind(),
        io::ErrorKind::StorageFull | io::ErrorKind::WriteZero
    ) || error
        .to_string()
        .to_ascii_lowercase()
        .contains("no space")
        || error
            .to_string()
            .to_ascii_lowercase()
            .contains("disk full")
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn maps_library_project_not_found() {
        let error = ExportError::from_library("project not found: abc".to_string());
        assert_eq!(error.kind, ExportErrorKind::ProjectNotFound);
    }

    #[test]
    fn maps_open_missing_page_asset() {
        let error = ExportError::map_open_page_asset(
            io::Error::new(io::ErrorKind::NotFound, "missing"),
            "/tmp/page.png",
        );
        assert_eq!(error.kind, ExportErrorKind::PageAssetMissing);
    }

    #[test]
    fn maps_permission_denied_on_existing_destination_as_locked() {
        let path = std::env::temp_dir().join(format!(
            "cbm-export-error-{}",
            uuid::Uuid::new_v4()
        ));
        std::fs::write(&path, b"x").expect("seed file");
        let error = ExportError::map_create_destination(
            io::Error::new(io::ErrorKind::PermissionDenied, "access denied"),
            &path,
        );
        let _ = std::fs::remove_file(path);
        assert_eq!(error.kind, ExportErrorKind::DestinationLocked);
    }
}
