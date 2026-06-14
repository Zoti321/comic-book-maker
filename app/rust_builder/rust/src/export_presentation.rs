//! Export 失败的用户可见文案（与 [`crate::export_error::ExportError`] 一一对应）。

use crate::export_error::{ExportError, ExportErrorKind};

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ExportFailurePresentation {
    pub title: String,
    pub message: String,
    pub next_step_hint: Option<String>,
}

impl ExportFailurePresentation {
    pub fn new(
        title: impl Into<String>,
        message: impl Into<String>,
        next_step_hint: Option<String>,
    ) -> Self {
        Self {
            title: title.into(),
            message: message.into(),
            next_step_hint,
        }
    }
}

pub fn presentation_for_export_error(error: &ExportError) -> ExportFailurePresentation {
    let detail_hint = optional_detail_hint(&error.detail);
    match error.kind {
        ExportErrorKind::DestinationExists => ExportFailurePresentation::new(
            "无法导出",
            "目标位置已存在同名文件。",
            detail_hint,
        ),
        ExportErrorKind::DestinationIsDirectory => ExportFailurePresentation::new(
            "无法导出",
            "导出目标不能是文件夹，请检查项目或全局导出目录设置。",
            detail_hint,
        ),
        ExportErrorKind::DestinationNotWritable => ExportFailurePresentation::new(
            "无法导出",
            "无法写入导出目录，请检查路径是否存在以及是否有写入权限。",
            detail_hint,
        ),
        ExportErrorKind::DestinationLocked => ExportFailurePresentation::new(
            "无法导出",
            "目标文件正被其他程序占用，请关闭相关程序后重试。",
            detail_hint,
        ),
        ExportErrorKind::DestinationFinalizeFailed => ExportFailurePresentation::new(
            "导出失败",
            "文件已写入但无法完成保存，请检查目标路径后重试。",
            detail_hint,
        ),
        ExportErrorKind::PageAssetMissing => ExportFailurePresentation::new(
            "无法导出",
            "某页图片文件找不到，项目资源可能已损坏或被移动。",
            detail_hint,
        ),
        ExportErrorKind::PageAssetUnreadable => ExportFailurePresentation::new(
            "无法导出",
            "无法读取某页图片，请检查文件权限或是否被占用。",
            detail_hint,
        ),
        ExportErrorKind::InsufficientSpace => ExportFailurePresentation::new(
            "无法导出",
            "磁盘空间不足，无法完成导出。",
            detail_hint,
        ),
        ExportErrorKind::ArchiveWriteFailed => ExportFailurePresentation::new(
            "导出失败",
            "生成档案文件时出错，请稍后重试。",
            detail_hint,
        ),
        ExportErrorKind::NoPages => ExportFailurePresentation::new(
            "无法导出",
            "Export 需要至少一页。",
            Some("请先为项目添加页面后再导出。".to_string()),
        ),
        ExportErrorKind::ProjectNotFound => ExportFailurePresentation::new(
            "无法导出",
            "找不到当前项目，可能已被删除。",
            detail_hint,
        ),
        ExportErrorKind::DeleteAfterExportFailed => ExportFailurePresentation::new(
            "导出部分完成",
            "文件已导出，但删除本地项目失败。",
            detail_hint,
        ),
    }
}

fn optional_detail_hint(detail: &str) -> Option<String> {
    let trimmed = detail.trim();
    if trimmed.is_empty() {
        None
    } else {
        Some(trimmed.to_string())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::export_error::ExportError;

    #[test]
    fn maps_no_pages_to_chinese_copy() {
        let presentation = presentation_for_export_error(&ExportError::no_pages());
        assert_eq!(presentation.title, "无法导出");
        assert!(presentation.message.contains("至少一页"));
        assert!(presentation.next_step_hint.is_some());
    }

    #[test]
    fn maps_page_asset_missing_with_detail_hint() {
        let error = ExportError::new(
            ExportErrorKind::PageAssetMissing,
            "open page asset /tmp/001.png: not found",
        );
        let presentation = presentation_for_export_error(&error);
        assert!(presentation.message.contains("找不到"));
        assert!(presentation.next_step_hint.unwrap().contains("001.png"));
    }
}
