//! Export 路径规划与导出前 preflight（Flutter 侧不再重复实现）。

use std::fs::{self, File};
use std::io::Write;
use std::path::Path;

use crate::export_presentation::ExportFailurePresentation;
use crate::project_format::ExportFormat;
use crate::project_workflow::ComicArchiveContainer;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ExportPlanBlockReason {
    SettingsNotLoaded,
    ArchiveContainerNotImplemented,
    ExportDirectoryMissing,
    NoPages,
    PreflightBlocked,
    TargetUnresolved,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ExportPreflightStatus {
    Ready,
    Blocked(ExportFailurePresentation),
    NeedsOverwriteConfirmation,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ExportPlanSettings {
    pub export_format: ExportFormat,
    pub delete_project_after_export: bool,
    pub use_default_export_directory: bool,
    pub export_directory: Option<String>,
    pub comic_archive_container: ComicArchiveContainer,
    pub use_comic_archive_extension: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ResolvedExportTarget {
    pub destination_path: String,
    pub format_label: String,
    pub export_comic_archive: bool,
    pub comic_archive_container: Option<ComicArchiveContainer>,
    pub export_pdf: bool,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ExportPlanReady {
    pub target: ResolvedExportTarget,
    pub delete_after_export: bool,
    pub needs_overwrite_confirmation: bool,
    pub progress_message: String,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub enum ExportPlanResult {
    Blocked {
        reason: ExportPlanBlockReason,
        presentation: ExportFailurePresentation,
    },
    Ready(ExportPlanReady),
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ExportPlanRequest {
    pub project_title: String,
    pub settings: Option<ExportPlanSettings>,
    pub global_export_directory: Option<String>,
    pub has_pages: bool,
}

pub fn sanitize_export_title(title: &str) -> String {
    title
        .chars()
        .map(|ch| match ch {
            '<' | '>' | ':' | '"' | '/' | '\\' | '|' | '?' | '*' => '_',
            other => other,
        })
        .collect()
}

pub fn comic_archive_container_label(container: ComicArchiveContainer) -> &'static str {
    match container {
        ComicArchiveContainer::Zip => "ZIP",
        ComicArchiveContainer::SevenZip => "7Z",
        ComicArchiveContainer::Rar => "RAR",
    }
}

pub fn is_comic_archive_container_implemented(container: ComicArchiveContainer) -> bool {
    match container {
        ComicArchiveContainer::Zip | ComicArchiveContainer::Rar | ComicArchiveContainer::SevenZip => {
            true
        }
    }
}

pub fn is_comic_archive_container_selectable(container: ComicArchiveContainer) -> bool {
    is_comic_archive_container_implemented(container)
}

pub fn comic_archive_file_extension(
    container: ComicArchiveContainer,
    use_comic_archive_extension: bool,
) -> &'static str {
    match container {
        ComicArchiveContainer::Zip => {
            if use_comic_archive_extension {
                "cbz"
            } else {
                "zip"
            }
        }
        ComicArchiveContainer::SevenZip => {
            if use_comic_archive_extension {
                "cb7"
            } else {
                "7z"
            }
        }
        ComicArchiveContainer::Rar => {
            if use_comic_archive_extension {
                "cbr"
            } else {
                "rar"
            }
        }
    }
}

pub fn comic_archive_export_format_label(settings: &ExportPlanSettings) -> String {
    match settings.comic_archive_container {
        ComicArchiveContainer::Zip => {
            if settings.use_comic_archive_extension {
                "CBZ".to_string()
            } else {
                "ZIP".to_string()
            }
        }
        ComicArchiveContainer::Rar => {
            if settings.use_comic_archive_extension {
                "CBR".to_string()
            } else {
                "RAR".to_string()
            }
        }
        ComicArchiveContainer::SevenZip => {
            if settings.use_comic_archive_extension {
                "CB7".to_string()
            } else {
                "7Z".to_string()
            }
        }
    }
}

pub fn comic_archive_export_file_name(settings: &ExportPlanSettings, safe_title: &str) -> String {
    format!(
        "{}.{}",
        safe_title,
        comic_archive_file_extension(
            settings.comic_archive_container,
            settings.use_comic_archive_extension,
        )
    )
}

pub fn resolve_export_directory(
    settings: &ExportPlanSettings,
    global_export_directory: Option<&str>,
) -> Option<String> {
    if settings.use_default_export_directory {
        let trimmed = global_export_directory?.trim();
        if trimmed.is_empty() {
            return None;
        }
        return Some(trimmed.to_string());
    }

    let project_dir = settings.export_directory.as_deref()?.trim();
    if project_dir.is_empty() {
        return None;
    }
    Some(project_dir.to_string())
}

pub fn resolve_export_block(
    settings: Option<&ExportPlanSettings>,
    global_export_directory: Option<&str>,
    safe_title: &str,
) -> Option<(ExportPlanBlockReason, ExportFailurePresentation)> {
    let settings = settings?;
    if settings.export_format == ExportFormat::ComicArchive
        && !is_comic_archive_container_implemented(settings.comic_archive_container)
    {
        let label = comic_archive_container_label(settings.comic_archive_container);
        return Some((
            ExportPlanBlockReason::ArchiveContainerNotImplemented,
            ExportFailurePresentation::new(
                "无法导出",
                format!("「{label}」容器 Export 尚未实现。"),
                Some(
                    "请在项目属性中将压缩算法改为 ZIP 或 RAR，或等待后续版本支持。"
                        .to_string(),
                ),
            ),
        ));
    }

    if resolve_export_directory(settings, global_export_directory).is_none() {
        let use_global = settings.use_default_export_directory;
        return Some((
            ExportPlanBlockReason::ExportDirectoryMissing,
            ExportFailurePresentation::new(
                "无法导出",
                if use_global {
                    "尚未配置应用默认导出目录。"
                } else {
                    "尚未配置本项目的专用导出目录。"
                },
                Some(
                    if use_global {
                        "请在「设置」中配置默认导出目录。"
                    } else {
                        "请在项目属性 → 导出中配置专用导出目录，或改为沿用全局默认目录。"
                    }
                    .to_string(),
                ),
            ),
        ));
    }

    let _ = safe_title;
    None
}

pub fn resolve_export_target(
    settings: &ExportPlanSettings,
    global_export_directory: Option<&str>,
    safe_title: &str,
) -> Option<ResolvedExportTarget> {
    if resolve_export_block(Some(settings), global_export_directory, safe_title).is_some() {
        return None;
    }

    let directory = resolve_export_directory(settings, global_export_directory)?;
    let export_comic_archive = settings.export_format == ExportFormat::ComicArchive;
    let export_pdf = settings.export_format == ExportFormat::Pdf;
    let file_name = if export_comic_archive {
        comic_archive_export_file_name(settings, safe_title)
    } else if export_pdf {
        format!("{safe_title}.pdf")
    } else {
        format!("{safe_title}.epub")
    };
    let format_label = if export_comic_archive {
        comic_archive_export_format_label(settings)
    } else if export_pdf {
        "PDF".to_string()
    } else {
        "EPUB".to_string()
    };

    Some(ResolvedExportTarget {
        destination_path: Path::new(&directory)
            .join(file_name)
            .to_string_lossy()
            .into_owned(),
        format_label,
        export_comic_archive,
        comic_archive_container: export_comic_archive.then_some(settings.comic_archive_container),
        export_pdf,
    })
}

pub fn check_export_preflight(destination_path: &str) -> ExportPreflightStatus {
    let normalized = destination_path.trim();
    if normalized.is_empty() {
        return ExportPreflightStatus::Blocked(ExportFailurePresentation::new(
            "无法导出",
            "导出目标路径无效。",
            Some("请在项目属性或设置中检查导出目录配置。".to_string()),
        ));
    }

    let destination = Path::new(normalized);
    if destination.exists() && destination.is_dir() {
        return ExportPreflightStatus::Blocked(ExportFailurePresentation::new(
            "无法导出",
            "导出目标不能是文件夹，请检查项目或全局导出目录设置。",
            Some(normalized.to_string()),
        ));
    }

    if destination.is_file() {
        return ExportPreflightStatus::NeedsOverwriteConfirmation;
    }

    let Some(parent) = destination.parent() else {
        return ExportPreflightStatus::Ready;
    };
    if parent.as_os_str().is_empty() || parent == destination {
        return ExportPreflightStatus::Ready;
    }

    if !parent.exists() {
        return ExportPreflightStatus::Blocked(ExportFailurePresentation::new(
            "无法导出",
            "无法写入导出目录，请检查路径是否存在以及是否有写入权限。",
            Some(format!("export directory does not exist: {}", parent.display())),
        ));
    }

    if !parent.is_dir() {
        return ExportPreflightStatus::Blocked(ExportFailurePresentation::new(
            "无法导出",
            "无法写入导出目录，请检查路径是否存在以及是否有写入权限。",
            Some(format!(
                "export parent path is not a directory: {}",
                parent.display()
            )),
        ));
    }

    if !is_directory_writable(parent) {
        return ExportPreflightStatus::Blocked(ExportFailurePresentation::new(
            "无法导出",
            "无法写入导出目录，请检查路径是否存在以及是否有写入权限。",
            Some(format!(
                "export directory is not writable: {}",
                parent.display()
            )),
        ));
    }

    ExportPreflightStatus::Ready
}

pub fn plan_export(request: ExportPlanRequest) -> ExportPlanResult {
    if !request.has_pages {
        return ExportPlanResult::Blocked {
            reason: ExportPlanBlockReason::NoPages,
            presentation: ExportFailurePresentation::new(
                "无法导出",
                "Export 需要至少一页。",
                Some("请先为项目添加页面后再导出。".to_string()),
            ),
        };
    }

    let safe_title = sanitize_export_title(&request.project_title);
    let global = request.global_export_directory.as_deref();

    if request.settings.is_none() {
        return ExportPlanResult::Blocked {
            reason: ExportPlanBlockReason::SettingsNotLoaded,
            presentation: ExportFailurePresentation::new(
                "无法导出",
                "项目设置尚未加载，请稍后重试。",
                Some("若问题持续，请返回漫画库后重新打开项目。".to_string()),
            ),
        };
    }

    let settings = request.settings.expect("checked above");
    if let Some((reason, presentation)) =
        resolve_export_block(Some(&settings), global, &safe_title)
    {
        return ExportPlanResult::Blocked {
            reason,
            presentation,
        };
    }

    let Some(target) = resolve_export_target(&settings, global, &safe_title) else {
        return ExportPlanResult::Blocked {
            reason: ExportPlanBlockReason::TargetUnresolved,
            presentation: ExportFailurePresentation::new(
                "无法导出",
                "无法解析导出目标，请检查项目设置。",
                Some("若问题持续，请返回漫画库后重新打开项目。".to_string()),
            ),
        };
    };

    match check_export_preflight(&target.destination_path) {
        ExportPreflightStatus::Blocked(presentation) => ExportPlanResult::Blocked {
            reason: ExportPlanBlockReason::PreflightBlocked,
            presentation,
        },
        ExportPreflightStatus::NeedsOverwriteConfirmation => {
            let format_label = target.format_label.clone();
            ExportPlanResult::Ready(ExportPlanReady {
                target,
                delete_after_export: settings.delete_project_after_export,
                needs_overwrite_confirmation: true,
                progress_message: format!("正在导出 {format_label}…"),
            })
        }
        ExportPreflightStatus::Ready => {
            let format_label = target.format_label.clone();
            ExportPlanResult::Ready(ExportPlanReady {
                target,
                delete_after_export: settings.delete_project_after_export,
                needs_overwrite_confirmation: false,
                progress_message: format!("正在导出 {format_label}…"),
            })
        }
    }
}

fn is_directory_writable(directory: &Path) -> bool {
    let nanos = std::time::SystemTime::now()
        .duration_since(std::time::UNIX_EPOCH)
        .map(|duration| duration.as_nanos())
        .unwrap_or(0);
    let probe_path = directory.join(format!(".cbm-write-probe-{nanos}"));
    match File::create(&probe_path) {
        Ok(mut file) => {
            let _ = file.write_all(b"x");
            let _ = fs::remove_file(probe_path);
            true
        }
        Err(_) => false,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    fn base_settings() -> ExportPlanSettings {
        ExportPlanSettings {
            export_format: ExportFormat::ComicArchive,
            delete_project_after_export: false,
            use_default_export_directory: true,
            export_directory: None,
            comic_archive_container: ComicArchiveContainer::Zip,
            use_comic_archive_extension: true,
        }
    }

    #[test]
    fn resolve_export_target_uses_global_directory() {
        let target = resolve_export_target(
            &base_settings(),
            Some(r"D:\exports"),
            "My Comic",
        )
        .expect("target");

        assert_eq!(target.destination_path, r"D:\exports\My Comic.cbz");
        assert!(target.export_comic_archive);
        assert_eq!(target.format_label, "CBZ");
    }

    #[test]
    fn resolve_export_target_uses_project_directory() {
        let settings = ExportPlanSettings {
            use_default_export_directory: false,
            export_directory: Some(r"E:\project-out".to_string()),
            use_comic_archive_extension: false,
            ..base_settings()
        };
        let target = resolve_export_target(&settings, Some(r"D:\exports"), "Issue 1").expect("target");
        assert_eq!(target.destination_path, r"E:\project-out\Issue 1.zip");
        assert_eq!(target.format_label, "ZIP");
    }

    #[test]
    fn pdf_export_resolves_pdf_path_and_label() {
        let settings = ExportPlanSettings {
            export_format: ExportFormat::Pdf,
            ..base_settings()
        };
        let dir = std::env::temp_dir();
        let target = resolve_export_target(&settings, Some(dir.to_str().unwrap()), "Comic")
            .expect("target");
        assert!(target.destination_path.ends_with("Comic.pdf"));
        assert!(!target.export_comic_archive);
        assert!(target.export_pdf);
        assert_eq!(target.format_label, "PDF");
    }

    #[test]
    fn blocks_when_global_directory_missing() {
        let block = resolve_export_block(Some(&base_settings()), None, "x").expect("block");
        assert_eq!(block.0, ExportPlanBlockReason::ExportDirectoryMissing);
    }

    #[test]
    fn comic_archive_file_extension_follows_strategy() {
        assert_eq!(
            comic_archive_file_extension(ComicArchiveContainer::Zip, false),
            "zip"
        );
        assert_eq!(
            comic_archive_file_extension(ComicArchiveContainer::Rar, true),
            "cbr"
        );
        assert_eq!(
            comic_archive_file_extension(ComicArchiveContainer::SevenZip, true),
            "cb7"
        );
        assert_eq!(
            comic_archive_file_extension(ComicArchiveContainer::SevenZip, false),
            "7z"
        );
    }
}
