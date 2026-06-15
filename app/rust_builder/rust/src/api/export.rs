//! Export 规划与用户可见错误文案 FRB。

use crate::export_error::ExportError;
use crate::export_plan::{
    self, ExportPlanBlockReason, ExportPlanRequest, ExportPlanResult, ExportPlanSettings,
};
use crate::export_presentation::{self, ExportFailurePresentation};
use crate::project_format::ExportFormat;

use super::simple::{ComicArchiveContainerFrb, ExportFormatFrb, ProjectSettings};

#[derive(Clone, Debug)]
#[flutter_rust_bridge::frb]
pub enum ExportPlanBlockReasonFrb {
    SettingsNotLoaded,
    ArchiveContainerNotImplemented,
    ExportDirectoryMissing,
    NoPages,
    PreflightBlocked,
    TargetUnresolved,
}

#[derive(Clone, Debug)]
#[flutter_rust_bridge::frb(non_final)]
pub struct ExportFailurePresentationFrb {
    pub title: String,
    pub message: String,
    pub next_step_hint: Option<String>,
}

#[derive(Clone, Debug)]
#[flutter_rust_bridge::frb(non_final)]
pub struct ResolvedExportTargetFrb {
    pub destination_path: String,
    pub format_label: String,
    pub export_comic_archive: bool,
    pub comic_archive_container: Option<ComicArchiveContainerFrb>,
    pub export_pdf: bool,
}

#[derive(Clone, Debug)]
#[flutter_rust_bridge::frb(non_final)]
pub struct ExportPlanReadyFrb {
    pub target: ResolvedExportTargetFrb,
    pub delete_after_export: bool,
    pub needs_overwrite_confirmation: bool,
    pub progress_message: String,
}

#[derive(Clone, Debug)]
#[flutter_rust_bridge::frb]
pub enum ExportPlanResultFrb {
    Blocked {
        reason: ExportPlanBlockReasonFrb,
        presentation: ExportFailurePresentationFrb,
    },
    Ready(ExportPlanReadyFrb),
}

#[derive(Clone, Debug)]
#[flutter_rust_bridge::frb(non_final)]
pub struct ExportPlanRequestFrb {
    pub project_title: String,
    pub settings: Option<ProjectSettings>,
    pub global_export_directory: Option<String>,
    pub has_pages: bool,
}

#[flutter_rust_bridge::frb(sync)]
pub fn plan_export(request: ExportPlanRequestFrb) -> ExportPlanResultFrb {
    plan_export_inner(request).into()
}

#[flutter_rust_bridge::frb(sync)]
pub fn export_error_presentation(error: ExportError) -> ExportFailurePresentationFrb {
    export_presentation::presentation_for_export_error(&error).into()
}

#[flutter_rust_bridge::frb(sync)]
pub fn sanitize_export_title(title: String) -> String {
    export_plan::sanitize_export_title(&title)
}

#[flutter_rust_bridge::frb(sync)]
pub fn comic_archive_container_label(container: ComicArchiveContainerFrb) -> String {
    export_plan::comic_archive_container_label(container.into()).to_string()
}

#[flutter_rust_bridge::frb(sync)]
pub fn is_comic_archive_container_implemented(container: ComicArchiveContainerFrb) -> bool {
    export_plan::is_comic_archive_container_implemented(container.into())
}

#[flutter_rust_bridge::frb(sync)]
pub fn is_comic_archive_container_selectable(container: ComicArchiveContainerFrb) -> bool {
    export_plan::is_comic_archive_container_selectable(container.into())
}

#[flutter_rust_bridge::frb(sync)]
pub fn comic_archive_file_extension(settings: ProjectSettings) -> String {
    let settings = export_plan_settings_from_frb(&settings);
    export_plan::comic_archive_file_extension(
        settings.comic_archive_container,
        settings.use_comic_archive_extension,
    )
    .to_string()
}

fn plan_export_inner(request: ExportPlanRequestFrb) -> ExportPlanResult {
    export_plan::plan_export(ExportPlanRequest {
        project_title: request.project_title,
        settings: request.settings.as_ref().map(export_plan_settings_from_frb),
        global_export_directory: request.global_export_directory,
        has_pages: request.has_pages,
    })
}

fn export_plan_settings_from_frb(settings: &ProjectSettings) -> ExportPlanSettings {
    ExportPlanSettings {
        export_format: export_format_from_frb(settings.export_format.clone()),
        delete_project_after_export: settings.delete_project_after_export,
        use_default_export_directory: settings.use_default_export_directory,
        export_directory: settings.export_directory.clone(),
        comic_archive_container: settings.comic_archive_container.clone().into(),
        use_comic_archive_extension: settings.use_comic_archive_extension,
    }
}

fn export_format_from_frb(format: ExportFormatFrb) -> ExportFormat {
    match format {
        ExportFormatFrb::Epub => ExportFormat::Epub,
        ExportFormatFrb::ComicArchive => ExportFormat::ComicArchive,
        ExportFormatFrb::Pdf => ExportFormat::Pdf,
    }
}

impl From<ExportFailurePresentation> for ExportFailurePresentationFrb {
    fn from(value: ExportFailurePresentation) -> Self {
        Self {
            title: value.title,
            message: value.message,
            next_step_hint: value.next_step_hint,
        }
    }
}

impl From<ExportPlanBlockReason> for ExportPlanBlockReasonFrb {
    fn from(value: ExportPlanBlockReason) -> Self {
        match value {
            ExportPlanBlockReason::SettingsNotLoaded => Self::SettingsNotLoaded,
            ExportPlanBlockReason::ArchiveContainerNotImplemented => {
                Self::ArchiveContainerNotImplemented
            }
            ExportPlanBlockReason::ExportDirectoryMissing => Self::ExportDirectoryMissing,
            ExportPlanBlockReason::NoPages => Self::NoPages,
            ExportPlanBlockReason::PreflightBlocked => Self::PreflightBlocked,
            ExportPlanBlockReason::TargetUnresolved => Self::TargetUnresolved,
        }
    }
}

impl From<export_plan::ResolvedExportTarget> for ResolvedExportTargetFrb {
    fn from(value: export_plan::ResolvedExportTarget) -> Self {
        Self {
            destination_path: value.destination_path,
            format_label: value.format_label,
            export_comic_archive: value.export_comic_archive,
            comic_archive_container: value
                .comic_archive_container
                .map(ComicArchiveContainerFrb::from),
            export_pdf: value.export_pdf,
        }
    }
}

impl From<export_plan::ExportPlanReady> for ExportPlanReadyFrb {
    fn from(value: export_plan::ExportPlanReady) -> Self {
        Self {
            target: value.target.into(),
            delete_after_export: value.delete_after_export,
            needs_overwrite_confirmation: value.needs_overwrite_confirmation,
            progress_message: value.progress_message,
        }
    }
}

impl From<ExportPlanResult> for ExportPlanResultFrb {
    fn from(value: ExportPlanResult) -> Self {
        match value {
            ExportPlanResult::Blocked {
                reason,
                presentation,
            } => Self::Blocked {
                reason: reason.into(),
                presentation: presentation.into(),
            },
            ExportPlanResult::Ready(ready) => Self::Ready(ready.into()),
        }
    }
}
