//! Atomic export destination writes: temp file in the target directory, then rename.

use std::fs;
use std::path::{Path, PathBuf};

use uuid::Uuid;

use crate::export_error::{ExportError, ExportErrorKind};

const TEMP_FILE_PREFIX: &str = ".cbm-export-";
const TEMP_FILE_SUFFIX: &str = ".tmp";

pub fn prepare_export_destination(destination: &Path) -> Result<(), ExportError> {
    ExportError::ensure_destination_is_file(destination)?;
    if let Some(parent) = destination.parent() {
        if !parent.as_os_str().is_empty() {
            fs::create_dir_all(parent)
                .map_err(|error| ExportError::map_create_directory(error, parent))?;
        }
    }
    Ok(())
}

pub fn atomic_write_destination(
    destination: &Path,
    write: impl FnOnce(&Path) -> Result<(), ExportError>,
) -> Result<(), ExportError> {
    prepare_export_destination(destination)?;

    let temp_path = temp_export_path(destination);
    match write(&temp_path) {
        Ok(()) => finalize_export_destination(&temp_path, destination),
        Err(error) => {
            let _ = fs::remove_file(&temp_path);
            Err(error)
        }
    }
}

fn temp_export_path(destination: &Path) -> PathBuf {
    let parent = destination
        .parent()
        .filter(|path| !path.as_os_str().is_empty())
        .unwrap_or_else(|| Path::new("."));
    parent.join(format!(
        "{TEMP_FILE_PREFIX}{uuid}{TEMP_FILE_SUFFIX}",
        uuid = Uuid::new_v4()
    ))
}

fn finalize_export_destination(temp_path: &Path, destination: &Path) -> Result<(), ExportError> {
    replace_destination(temp_path, destination).map_err(|error| {
        let _ = fs::remove_file(temp_path);
        ExportError::new(
            ExportErrorKind::DestinationFinalizeFailed,
            format!(
                "rename {} to {}: {error}",
                temp_path.display(),
                destination.display()
            ),
        )
    })
}

fn replace_destination(temp_path: &Path, destination: &Path) -> Result<(), std::io::Error> {
    #[cfg(unix)]
    {
        fs::rename(temp_path, destination)
    }
    #[cfg(windows)]
    {
        if destination.exists() {
            fs::remove_file(destination)?;
        }
        fs::rename(temp_path, destination)
    }
}

pub fn is_export_temp_file_name(file_name: &str) -> bool {
    file_name.starts_with(TEMP_FILE_PREFIX) && file_name.ends_with(TEMP_FILE_SUFFIX)
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::path::PathBuf;

    fn temp_dir(name: &str) -> PathBuf {
        let dir = std::env::temp_dir().join(format!("cbm-export-atomic-{name}-{}", Uuid::new_v4()));
        fs::create_dir_all(&dir).expect("create temp dir");
        dir
    }

    fn list_export_temp_files(dir: &Path) -> Vec<PathBuf> {
        fs::read_dir(dir)
            .expect("read dir")
            .filter_map(|entry| entry.ok())
            .map(|entry| entry.path())
            .filter(|path| {
                path.file_name()
                    .and_then(|name| name.to_str())
                    .is_some_and(is_export_temp_file_name)
            })
            .collect()
    }

    #[test]
    fn failed_write_preserves_existing_destination() {
        let dir = temp_dir("preserve");
        let destination = dir.join("out.cbz");
        let original = b"original export bytes";
        fs::write(&destination, original).expect("seed destination");

        let error = atomic_write_destination(&destination, |_temp| {
            Err(ExportError::new(
                ExportErrorKind::ArchiveWriteFailed,
                "simulated write failure",
            ))
        })
        .expect_err("write should fail");

        assert_eq!(error.kind, ExportErrorKind::ArchiveWriteFailed);
        assert_eq!(fs::read(&destination).expect("read destination"), original);
        assert!(list_export_temp_files(&dir).is_empty());
    }

    #[test]
    fn failed_write_after_partial_content_preserves_existing_destination() {
        let dir = temp_dir("partial");
        let destination = dir.join("out.epub");
        let original = b"keep this file intact";
        fs::write(&destination, original).expect("seed destination");

        atomic_write_destination(&destination, |temp| {
            fs::write(temp, b"partial export data").expect("write temp");
            Err(ExportError::new(
                ExportErrorKind::PageAssetMissing,
                "simulated missing page",
            ))
        })
        .expect_err("write should fail");

        assert_eq!(fs::read(&destination).expect("read destination"), original);
        assert!(list_export_temp_files(&dir).is_empty());
    }

    #[test]
    fn successful_write_replaces_destination() {
        let dir = temp_dir("replace");
        let destination = dir.join("out.cbr");
        fs::write(&destination, b"old").expect("seed destination");
        let updated = b"new archive bytes";

        atomic_write_destination(&destination, |temp| {
            fs::write(temp, updated).map_err(|error| {
                ExportError::map_create_destination(error, temp)
            })
        })
        .expect("write should succeed");

        assert_eq!(fs::read(&destination).expect("read destination"), updated);
        assert!(list_export_temp_files(&dir).is_empty());
    }

    #[test]
    fn successful_write_creates_new_destination() {
        let dir = temp_dir("create");
        let destination = dir.join("new.cbz");
        let bytes = b"fresh export";

        atomic_write_destination(&destination, |temp| {
            fs::write(temp, bytes).map_err(|error| {
                ExportError::map_create_destination(error, temp)
            })
        })
        .expect("write should succeed");

        assert_eq!(fs::read(&destination).expect("read destination"), bytes);
        assert!(list_export_temp_files(&dir).is_empty());
    }
}
