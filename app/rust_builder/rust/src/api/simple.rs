use anyhow::Result;

use crate::db::Library;
use crate::export_error::ExportError;
use crate::project_format::{ExportFormat, InferredImportKind};

pub use crate::api::metadata::{
    get_metadata_editor_schema, get_project_metadata, merge_metadata_from_form,
    metadata_field_display_value, metadata_with_cover_page_index, metadata_with_dropdown_field,
    metadata_with_page_count, update_project_metadata, Metadata, MetadataEditorSchemaFrb,
    MetadataFieldKindFrb, MetadataFieldSpecFrb, MetadataFieldValueFrb, MetadataSectionSpecFrb,
};

#[flutter_rust_bridge::frb(sync)]
pub fn greet(name: String) -> String {
    format!("Hello, {name}!")
}

#[flutter_rust_bridge::frb(sync)]
pub fn core_ping() -> String {
    "Comic Book Maker Core connected".to_string()
}

#[flutter_rust_bridge::frb(init)]
pub fn init_app() {
    flutter_rust_bridge::setup_default_user_utils();
}

#[flutter_rust_bridge::frb(non_final)]
#[derive(Clone, Debug)]
pub struct ProjectSummary {
    pub id: String,
    pub title: String,
    pub updated_at_ms: i64,
    pub created_at_ms: i64,
    pub last_opened_at_ms: Option<i64>,
    pub cover_thumbnail_path: Option<String>,
}

#[flutter_rust_bridge::frb(sync)]
pub fn init_library(app_data_dir: String) -> Result<()> {
    Library::install(app_data_dir.into()).map_err(|error| anyhow::anyhow!(error))
}

#[flutter_rust_bridge::frb(sync)]
pub fn reset_library_for_testing() -> Result<()> {
    Library::reset_for_test().map_err(|error| anyhow::anyhow!(error))
}

#[flutter_rust_bridge::frb(sync)]
pub fn create_project(title: Option<String>) -> Result<ProjectSummary> {
    Library::create_project(title)
        .map(Into::into)
        .map_err(|error| anyhow::anyhow!(error))
}

#[flutter_rust_bridge::frb(sync)]
pub fn update_project_title(project_id: String, title: String) -> Result<ProjectSummary> {
    Library::update_project_title(&project_id, title)
        .map(Into::into)
        .map_err(|error| anyhow::anyhow!(error))
}

#[flutter_rust_bridge::frb(sync)]
pub fn list_projects() -> Result<Vec<ProjectSummary>> {
    Library::list_projects()
        .map(|projects| projects.into_iter().map(Into::into).collect())
        .map_err(|error| anyhow::anyhow!(error))
}

#[flutter_rust_bridge::frb(non_final)]
#[derive(Clone, Debug)]
pub struct ImportCbzResult {
    pub project: ProjectSummary,
    pub warnings: Vec<String>,
}

#[derive(Clone, Debug)]
#[flutter_rust_bridge::frb]
pub enum ArchiveFormatFrb {
    Cbz,
    Cbr,
    Cb7,
    Epub,
}

#[flutter_rust_bridge::frb(sync)]
pub fn import_archive(
    format: ArchiveFormatFrb,
    source_path: String,
) -> Result<ImportCbzResult> {
    Library::import_archive(format.into(), &source_path)
        .map(import_outcome_to_result)
        .map_err(|error| anyhow::anyhow!(error))
}

#[flutter_rust_bridge::frb(sync)]
pub fn import_cbz(source_path: String) -> Result<ImportCbzResult> {
    import_archive(ArchiveFormatFrb::Cbz, source_path)
}

#[flutter_rust_bridge::frb(sync)]
pub fn import_cbr(source_path: String) -> Result<ImportCbzResult> {
    import_archive(ArchiveFormatFrb::Cbr, source_path)
}

#[flutter_rust_bridge::frb(sync)]
pub fn import_cb7(source_path: String) -> Result<ImportCbzResult> {
    import_archive(ArchiveFormatFrb::Cb7, source_path)
}

#[flutter_rust_bridge::frb(sync)]
pub fn import_epub(source_path: String) -> Result<ImportCbzResult> {
    import_archive(ArchiveFormatFrb::Epub, source_path)
}

#[flutter_rust_bridge::frb(non_final)]
#[derive(Clone, Debug)]
pub struct AppendImportResult {
    pub warnings: Vec<String>,
    pub added_page_count: i32,
    pub pages: Vec<PageSummary>,
    pub cover_page_index: i32,
}

#[flutter_rust_bridge::frb(sync)]
pub fn append_archive(
    project_id: String,
    format: ArchiveFormatFrb,
    source_path: String,
) -> Result<AppendImportResult> {
    let outcome = Library::append_archive(&project_id, format.into(), &source_path)
        .map_err(|error| anyhow::anyhow!(error))?;
    let structure = Library::load_page_structure(&project_id)
        .map_err(|error| anyhow::anyhow!(error))?;
    Ok(append_import_outcome_to_result(outcome, structure))
}

#[flutter_rust_bridge::frb(sync)]
pub fn append_cbz(project_id: String, source_path: String) -> Result<AppendImportResult> {
    append_archive(project_id, ArchiveFormatFrb::Cbz, source_path)
}

#[flutter_rust_bridge::frb(sync)]
pub fn append_cbr(project_id: String, source_path: String) -> Result<AppendImportResult> {
    append_archive(project_id, ArchiveFormatFrb::Cbr, source_path)
}

#[flutter_rust_bridge::frb(sync)]
pub fn append_cb7(project_id: String, source_path: String) -> Result<AppendImportResult> {
    append_archive(project_id, ArchiveFormatFrb::Cb7, source_path)
}

#[flutter_rust_bridge::frb(sync)]
pub fn append_epub(project_id: String, source_path: String) -> Result<AppendImportResult> {
    append_archive(project_id, ArchiveFormatFrb::Epub, source_path)
}

#[flutter_rust_bridge::frb(sync)]
pub fn infer_archive_format_from_path(path: String) -> Option<ArchiveFormatFrb> {
    crate::import::infer_archive_format_from_path(&path).map(Into::into)
}

#[flutter_rust_bridge::frb(sync)]
pub fn infer_comic_archive_format_from_path(path: String) -> Option<ArchiveFormatFrb> {
    crate::import::infer_comic_archive_format_from_path(&path).map(Into::into)
}

#[flutter_rust_bridge::frb(sync)]
pub fn archive_format_display_name(format: ArchiveFormatFrb) -> String {
    crate::import::archive_format_display_name(format.into()).to_string()
}

#[flutter_rust_bridge::frb(sync)]
pub fn archive_format_allowed_extensions(format: ArchiveFormatFrb) -> Vec<String> {
    crate::import::archive_format_allowed_extensions(format.into())
        .iter()
        .map(|ext| (*ext).to_string())
        .collect()
}

#[flutter_rust_bridge::frb(sync)]
pub fn comic_archive_picker_extensions() -> Vec<String> {
    crate::import::COMIC_ARCHIVE_PICKER_EXTENSIONS
        .iter()
        .map(|ext| (*ext).to_string())
        .collect()
}

fn append_import_outcome_to_result(
    outcome: crate::import::AppendImportOutcome,
    structure: crate::db::PageStructureSnapshot,
) -> AppendImportResult {
    AppendImportResult {
        warnings: outcome.warnings,
        added_page_count: outcome.added_page_count,
        pages: structure
            .pages
            .into_iter()
            .map(Into::into)
            .collect(),
        cover_page_index: structure.cover_page_index,
    }
}

fn import_outcome_to_result(outcome: crate::import::ImportArchiveOutcome) -> ImportCbzResult {
    ImportCbzResult {
        project: ProjectSummary {
            id: outcome.project_id,
            title: outcome.title,
            updated_at_ms: outcome.updated_at_ms,
            created_at_ms: outcome.created_at_ms,
            last_opened_at_ms: outcome.last_opened_at_ms,
            cover_thumbnail_path: outcome.cover_thumbnail_path,
        },
        warnings: outcome.warnings,
    }
}

#[flutter_rust_bridge::frb]
pub fn export_cbz(
    project_id: String,
    destination_path: String,
    delete_project_after_export: bool,
) -> Result<(), ExportError> {
    Library::export_cbz(&project_id, &destination_path, delete_project_after_export)
}

#[flutter_rust_bridge::frb]
pub fn export_cbr(
    project_id: String,
    destination_path: String,
    delete_project_after_export: bool,
) -> Result<(), ExportError> {
    Library::export_cbr(&project_id, &destination_path, delete_project_after_export)
}

#[flutter_rust_bridge::frb]
pub fn export_cb7(
    project_id: String,
    destination_path: String,
    delete_project_after_export: bool,
) -> Result<(), ExportError> {
    Library::export_cb7(&project_id, &destination_path, delete_project_after_export)
}

#[flutter_rust_bridge::frb]
pub fn export_epub(
    project_id: String,
    destination_path: String,
    delete_project_after_export: bool,
) -> Result<(), ExportError> {
    Library::export_epub(&project_id, &destination_path, delete_project_after_export)
}

#[flutter_rust_bridge::frb]
pub fn export_pdf(
    project_id: String,
    destination_path: String,
    delete_project_after_export: bool,
) -> Result<(), ExportError> {
    Library::export_pdf(&project_id, &destination_path, delete_project_after_export)
}

#[flutter_rust_bridge::frb(sync)]
pub fn delete_project(project_id: String) -> Result<()> {
    Library::delete_project(&project_id).map_err(|error| anyhow::anyhow!(error))
}

#[flutter_rust_bridge::frb(sync)]
pub fn touch_project(project_id: String) -> Result<()> {
    Library::touch_project(&project_id).map_err(|error| anyhow::anyhow!(error))
}

#[derive(Clone, Debug)]
#[flutter_rust_bridge::frb]
pub enum ExportFormatFrb {
    Epub,
    ComicArchive,
    Pdf,
}

#[derive(Clone, Debug)]
#[flutter_rust_bridge::frb]
pub enum InferredImportKindFrb {
    Images,
    ComicArchive,
    Epub,
    Pdf,
}

#[derive(Clone, Debug)]
#[flutter_rust_bridge::frb]
pub enum ComicArchiveContainerFrb {
    Zip,
    SevenZip,
    Rar,
}

#[flutter_rust_bridge::frb(non_final)]
#[derive(Clone, Debug)]
pub struct ProjectSettings {
    pub export_format: ExportFormatFrb,
    pub inferred_import_kind: InferredImportKindFrb,
    pub delete_project_after_export: bool,
    pub use_default_export_directory: bool,
    pub export_directory: Option<String>,
    pub comic_archive_container: ComicArchiveContainerFrb,
    pub use_comic_archive_extension: bool,
}

/// Writable project workflow fields (`inferred_import_kind` is not changed here).
#[flutter_rust_bridge::frb(non_final)]
#[derive(Clone, Debug)]
pub struct ProjectSettingsUpdate {
    pub export_format: ExportFormatFrb,
    pub delete_project_after_export: bool,
    pub use_default_export_directory: bool,
    pub export_directory: Option<String>,
    pub comic_archive_container: ComicArchiveContainerFrb,
    pub use_comic_archive_extension: bool,
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_project_settings(project_id: String) -> Result<ProjectSettings> {
    Library::get_project_settings(&project_id)
        .map(project_settings_from_record)
        .map_err(|error| anyhow::anyhow!(error))
}

#[flutter_rust_bridge::frb(sync)]
pub fn update_project_settings(
    project_id: String,
    update: ProjectSettingsUpdate,
) -> Result<ProjectSettings> {
    Library::update_project_settings(&project_id, update.into())
        .map(project_settings_from_record)
        .map_err(|error| anyhow::anyhow!(error))
}

#[flutter_rust_bridge::frb(sync)]
pub fn update_project_export_format(
    project_id: String,
    export_format: ExportFormatFrb,
) -> Result<ProjectSettings> {
    Library::update_project_export_format(&project_id, export_format.into())
        .map(project_settings_from_record)
        .map_err(|error| anyhow::anyhow!(error))
}

#[flutter_rust_bridge::frb(sync)]
pub fn change_project_inferred_import_kind(
    project_id: String,
    inferred_import_kind: InferredImportKindFrb,
) -> Result<ProjectSettings> {
    Library::change_inferred_import_kind(&project_id, inferred_import_kind.into())
        .map(project_settings_from_record)
        .map_err(|error| anyhow::anyhow!(error))
}

fn project_settings_from_record(
    record: crate::db::ProjectSettingsRecord,
) -> ProjectSettings {
    ProjectSettings {
        export_format: record.export_format.into(),
        inferred_import_kind: record.inferred_import_kind.into(),
        delete_project_after_export: record.delete_project_after_export,
        use_default_export_directory: record.use_default_export_directory,
        export_directory: record.export_directory,
        comic_archive_container: record.comic_archive_container.into(),
        use_comic_archive_extension: record.use_comic_archive_extension,
    }
}

impl From<ProjectSettingsUpdate> for crate::db::ProjectSettingsPatch {
    fn from(value: ProjectSettingsUpdate) -> Self {
        Self {
            export_format: value.export_format.into(),
            delete_project_after_export: value.delete_project_after_export,
            use_default_export_directory: value.use_default_export_directory,
            export_directory: value.export_directory,
            comic_archive_container: value.comic_archive_container.into(),
            use_comic_archive_extension: value.use_comic_archive_extension,
        }
    }
}

impl From<crate::project_workflow::ComicArchiveContainer> for ComicArchiveContainerFrb {
    fn from(value: crate::project_workflow::ComicArchiveContainer) -> Self {
        match value {
            crate::project_workflow::ComicArchiveContainer::Zip => Self::Zip,
            crate::project_workflow::ComicArchiveContainer::SevenZip => Self::SevenZip,
            crate::project_workflow::ComicArchiveContainer::Rar => Self::Rar,
        }
    }
}

impl From<ComicArchiveContainerFrb> for crate::project_workflow::ComicArchiveContainer {
    fn from(value: ComicArchiveContainerFrb) -> Self {
        match value {
            ComicArchiveContainerFrb::Zip => Self::Zip,
            ComicArchiveContainerFrb::SevenZip => Self::SevenZip,
            ComicArchiveContainerFrb::Rar => Self::Rar,
        }
    }
}

impl From<ExportFormat> for ExportFormatFrb {
    fn from(value: ExportFormat) -> Self {
        match value {
            ExportFormat::Epub => Self::Epub,
            ExportFormat::ComicArchive => Self::ComicArchive,
            ExportFormat::Pdf => Self::Pdf,
        }
    }
}

impl From<ExportFormatFrb> for ExportFormat {
    fn from(value: ExportFormatFrb) -> Self {
        match value {
            ExportFormatFrb::Epub => Self::Epub,
            ExportFormatFrb::ComicArchive => Self::ComicArchive,
            ExportFormatFrb::Pdf => Self::Pdf,
        }
    }
}

impl From<InferredImportKind> for InferredImportKindFrb {
    fn from(value: InferredImportKind) -> Self {
        match value {
            InferredImportKind::Images => Self::Images,
            InferredImportKind::ComicArchive => Self::ComicArchive,
            InferredImportKind::Epub => Self::Epub,
            InferredImportKind::Pdf => Self::Pdf,
        }
    }
}

impl From<InferredImportKindFrb> for InferredImportKind {
    fn from(value: InferredImportKindFrb) -> Self {
        match value {
            InferredImportKindFrb::Images => Self::Images,
            InferredImportKindFrb::ComicArchive => Self::ComicArchive,
            InferredImportKindFrb::Epub => Self::Epub,
            InferredImportKindFrb::Pdf => Self::Pdf,
        }
    }
}

#[flutter_rust_bridge::frb(non_final)]
#[derive(Clone, Debug)]
pub struct PageSummary {
    pub id: String,
    pub sort_index: i32,
    pub asset_path: String,
    pub absolute_path: String,
}

#[flutter_rust_bridge::frb(non_final)]
#[derive(Clone, Debug)]
pub struct ProjectPageStructureFrb {
    pub pages: Vec<PageSummary>,
    pub cover_page_index: i32,
}

#[flutter_rust_bridge::frb(non_final)]
#[derive(Clone, Debug)]
pub struct ProjectEditorSnapshotFrb {
    pub pages: Vec<PageSummary>,
    pub settings: ProjectSettings,
    pub cover_page_index: i32,
}

#[flutter_rust_bridge::frb(sync)]
pub fn load_page_structure(project_id: String) -> Result<ProjectPageStructureFrb> {
    Library::load_page_structure(&project_id)
        .map(page_structure_to_frb)
        .map_err(|error| anyhow::anyhow!(error))
}

#[flutter_rust_bridge::frb(sync)]
pub fn load_project_editor_snapshot(
    project_id: String,
) -> Result<ProjectEditorSnapshotFrb> {
    Library::load_project_editor_snapshot(&project_id)
        .map(|(pages, settings, cover_page_index)| ProjectEditorSnapshotFrb {
            pages: pages.into_iter().map(Into::into).collect(),
            settings: project_settings_from_record(settings),
            cover_page_index,
        })
        .map_err(|error| anyhow::anyhow!(error))
}

#[flutter_rust_bridge::frb(sync)]
pub fn set_cover_page(project_id: String, cover_page_index: i32) -> Result<i32> {
    Library::set_cover_page(&project_id, cover_page_index)
        .map_err(|error| anyhow::anyhow!(error))
}

#[flutter_rust_bridge::frb(sync)]
pub fn add_page_images(
    project_id: String,
    source_paths: Vec<String>,
) -> Result<ProjectPageStructureFrb> {
    Library::add_page_images(&project_id, source_paths)
        .map(page_structure_to_frb)
        .map_err(|error| anyhow::anyhow!(error))
}

#[flutter_rust_bridge::frb(sync)]
pub fn list_pages(project_id: String) -> Result<Vec<PageSummary>> {
    Library::list_pages(&project_id)
        .map(|pages| pages.into_iter().map(Into::into).collect())
        .map_err(|error| anyhow::anyhow!(error))
}

#[flutter_rust_bridge::frb(sync)]
pub fn delete_page(project_id: String, page_id: String) -> Result<ProjectPageStructureFrb> {
    Library::delete_page(&project_id, &page_id)
        .map(page_structure_to_frb)
        .map_err(|error| anyhow::anyhow!(error))
}

#[flutter_rust_bridge::frb(sync)]
pub fn replace_page_image(
    project_id: String,
    page_id: String,
    source_path: String,
) -> Result<ProjectPageStructureFrb> {
    Library::replace_page_image(&project_id, &page_id, source_path)
        .map(page_structure_to_frb)
        .map_err(|error| anyhow::anyhow!(error))
}

#[flutter_rust_bridge::frb(sync)]
pub fn reorder_pages(
    project_id: String,
    ordered_page_ids: Vec<String>,
) -> Result<ProjectPageStructureFrb> {
    Library::reorder_pages(&project_id, ordered_page_ids)
        .map(page_structure_to_frb)
        .map_err(|error| anyhow::anyhow!(error))
}

fn page_structure_to_frb(
    snapshot: crate::db::PageStructureSnapshot,
) -> ProjectPageStructureFrb {
    ProjectPageStructureFrb {
        pages: snapshot.pages.into_iter().map(Into::into).collect(),
        cover_page_index: snapshot.cover_page_index,
    }
}

impl From<crate::db::PageRecord> for PageSummary {
    fn from(value: crate::db::PageRecord) -> Self {
        Self {
            id: value.id,
            sort_index: value.sort_index,
            asset_path: value.asset_path,
            absolute_path: value.absolute_path,
        }
    }
}

impl From<crate::db::ProjectRecord> for ProjectSummary {
    fn from(value: crate::db::ProjectRecord) -> Self {
        Self {
            id: value.id,
            title: value.title,
            updated_at_ms: value.updated_at_ms,
            created_at_ms: value.created_at_ms,
            last_opened_at_ms: value.last_opened_at_ms,
            cover_thumbnail_path: value.cover_thumbnail_path,
        }
    }
}

impl From<ArchiveFormatFrb> for crate::import::ArchiveImportFormat {
    fn from(value: ArchiveFormatFrb) -> Self {
        match value {
            ArchiveFormatFrb::Cbz => Self::Cbz,
            ArchiveFormatFrb::Cbr => Self::Cbr,
            ArchiveFormatFrb::Cb7 => Self::Cb7,
            ArchiveFormatFrb::Epub => Self::Epub,
        }
    }
}

impl From<crate::import::ArchiveImportFormat> for ArchiveFormatFrb {
    fn from(value: crate::import::ArchiveImportFormat) -> Self {
        match value {
            crate::import::ArchiveImportFormat::Cbz => Self::Cbz,
            crate::import::ArchiveImportFormat::Cbr => Self::Cbr,
            crate::import::ArchiveImportFormat::Cb7 => Self::Cb7,
            crate::import::ArchiveImportFormat::Epub => Self::Epub,
        }
    }
}
