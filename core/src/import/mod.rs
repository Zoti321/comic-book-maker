//! Archive import pipeline: scan → stage → commit.
//!
//! Format-specific adapters live in [`cbz`], [`cbr`], [`cb7`], and [`epub`]; shared staging,
//! metadata mapping, and transaction orchestration are internal to this module.

pub mod archive_path;
pub mod cb7;
pub mod cbz;
pub mod cbr;
pub mod epub;
mod metadata;
mod orchestration;
mod staging;
mod types;

pub use archive_path::{
    fallback_title_from_path, is_comicinfo_entry, is_ignored_entry, is_page_image_entry,
    normalize_archive_path,
};
pub use cb7::{append_cb7, import_cb7};
pub use cbz::{append_cbz, import_cbz, scan_cbz_entries, ImportCbzOutcome};
pub use cbr::{append_cbr, import_cbr};
pub use epub::{append_epub, import_epub, ImportEpubOutcome};
pub use metadata::build_import_metadata;
pub use orchestration::{
    finalize_import, run_append_import, run_import_with_rollback,
};
pub use staging::{remove_staged_page_assets, scan_archive_tree, stage_pages_from_files, stage_zip_pages};
pub use types::{AppendImportOutcome, ImportArchiveOutcome, StagedImportPage};

use crate::db::Library;

/// Supported archive formats for import dispatch.
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ArchiveImportFormat {
    Cbz,
    Cbr,
    Cb7,
    Epub,
}

pub fn import_archive(
    library: &mut Library,
    format: ArchiveImportFormat,
    source_path: &str,
) -> Result<ImportArchiveOutcome, String> {
    match format {
        ArchiveImportFormat::Cbz => import_cbz(library, source_path),
        ArchiveImportFormat::Cbr => import_cbr(library, source_path),
        ArchiveImportFormat::Cb7 => import_cb7(library, source_path),
        ArchiveImportFormat::Epub => import_epub(library, source_path),
    }
}

pub fn append_archive(
    library: &mut Library,
    project_id: &str,
    format: ArchiveImportFormat,
    source_path: &str,
) -> Result<AppendImportOutcome, String> {
    match format {
        ArchiveImportFormat::Cbz => append_cbz(library, project_id, source_path),
        ArchiveImportFormat::Cbr => append_cbr(library, project_id, source_path),
        ArchiveImportFormat::Cb7 => append_cb7(library, project_id, source_path),
        ArchiveImportFormat::Epub => append_epub(library, project_id, source_path),
    }
}
