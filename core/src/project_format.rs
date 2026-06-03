//! Project export target and inferred import source (Archive Format).

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ExportFormat {
    Epub,
    ComicArchive,
    Pdf,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum InferredImportKind {
    Images,
    ComicArchive,
    Epub,
    Pdf,
}

impl Default for ExportFormat {
    fn default() -> Self {
        Self::ComicArchive
    }
}

impl Default for InferredImportKind {
    fn default() -> Self {
        Self::Images
    }
}

impl ExportFormat {
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::Epub => "epub",
            Self::ComicArchive => "comic_archive",
            Self::Pdf => "pdf",
        }
    }

    pub fn from_db(value: &str) -> Result<Self, String> {
        match value {
            "epub" => Ok(Self::Epub),
            "comic_archive" => Ok(Self::ComicArchive),
            "pdf" => Ok(Self::Pdf),
            other => Err(format!("unknown export_format: {other}")),
        }
    }

    pub const fn is_exportable(self) -> bool {
        !matches!(self, Self::Pdf)
    }
}

impl InferredImportKind {
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::Images => "images",
            Self::ComicArchive => "comic_archive",
            Self::Epub => "epub",
            Self::Pdf => "pdf",
        }
    }

    pub fn from_db(value: &str) -> Result<Self, String> {
        match value {
            "images" => Ok(Self::Images),
            "comic_archive" => Ok(Self::ComicArchive),
            "epub" => Ok(Self::Epub),
            "pdf" => Ok(Self::Pdf),
            other => Err(format!("unknown inferred_import_kind: {other}")),
        }
    }

    pub const fn display_label_zh(self) -> &'static str {
        match self {
            Self::Images => "图片",
            Self::ComicArchive => "漫画压缩包",
            Self::Epub => "EPUB",
            Self::Pdf => "PDF",
        }
    }
}

impl ExportFormat {
    pub const fn display_label_zh(self) -> &'static str {
        match self {
            Self::Epub => "EPUB",
            Self::ComicArchive => "漫画压缩包 (CBZ)",
            Self::Pdf => "PDF",
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trip_export_format() {
        for format in [
            ExportFormat::Epub,
            ExportFormat::ComicArchive,
            ExportFormat::Pdf,
        ] {
            assert_eq!(
                ExportFormat::from_db(format.as_str()).expect("parse"),
                format
            );
        }
    }
}
