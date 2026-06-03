//! Project-level export workflow preferences (paths, delete-after-export, archive container).

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ComicArchiveContainer {
    Zip,
    SevenZip,
    Rar,
}

impl Default for ComicArchiveContainer {
    fn default() -> Self {
        Self::Zip
    }
}

impl ComicArchiveContainer {
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::Zip => "zip",
            Self::SevenZip => "seven_zip",
            Self::Rar => "rar",
        }
    }

    pub fn from_db(value: &str) -> Result<Self, String> {
        match value {
            "zip" => Ok(Self::Zip),
            "seven_zip" => Ok(Self::SevenZip),
            "rar" => Ok(Self::Rar),
            other => Err(format!("unknown comic_archive_container: {other}")),
        }
    }
}

/// Defaults applied when creating a Project (Create Project / Library Import).
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ProjectWorkflowDefaults {
    pub delete_project_after_export: bool,
    pub use_default_export_directory: bool,
    pub export_directory: Option<String>,
    pub comic_archive_container: ComicArchiveContainer,
    pub use_comic_archive_extension: bool,
}

impl Default for ProjectWorkflowDefaults {
    fn default() -> Self {
        Self {
            delete_project_after_export: false,
            use_default_export_directory: true,
            export_directory: None,
            comic_archive_container: ComicArchiveContainer::default(),
            use_comic_archive_extension: true,
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn round_trip_comic_archive_container() {
        for container in [
            ComicArchiveContainer::Zip,
            ComicArchiveContainer::SevenZip,
            ComicArchiveContainer::Rar,
        ] {
            assert_eq!(
                ComicArchiveContainer::from_db(container.as_str()).expect("parse"),
                container
            );
        }
    }

    #[test]
    fn rejects_unknown_comic_archive_container() {
        assert!(ComicArchiveContainer::from_db("tar").is_err());
    }
}
