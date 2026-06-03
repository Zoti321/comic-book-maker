//! Persisted XML snapshot of metadata from the import source archive.

use std::path::Path;

use crate::paths::{import_metadata_kind_path, import_metadata_xml_path};

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum ImportMetadataKind {
    ComicInfo,
    Opf,
    None,
}

#[derive(Debug, Clone, PartialEq, Eq)]
pub struct ImportMetadataSnapshot {
    pub kind: ImportMetadataKind,
    pub xml: Option<String>,
}

impl ImportMetadataSnapshot {
    pub fn comicinfo(xml: &str) -> Self {
        Self {
            kind: ImportMetadataKind::ComicInfo,
            xml: Some(xml.to_string()),
        }
    }

    pub fn opf(xml: &str) -> Self {
        Self {
            kind: ImportMetadataKind::Opf,
            xml: Some(xml.to_string()),
        }
    }

    pub fn none() -> Self {
        Self {
            kind: ImportMetadataKind::None,
            xml: None,
        }
    }

    pub fn from_comicinfo_xml(comicinfo_xml: &Option<String>) -> Self {
        match comicinfo_xml {
            Some(xml) if !xml.trim().is_empty() => Self::comicinfo(xml),
            _ => Self::none(),
        }
    }
}

impl ImportMetadataKind {
    pub const fn as_str(self) -> &'static str {
        match self {
            Self::ComicInfo => "comicinfo",
            Self::Opf => "opf",
            Self::None => "none",
        }
    }

    pub fn from_str(value: &str) -> Result<Self, String> {
        match value.trim() {
            "comicinfo" => Ok(Self::ComicInfo),
            "opf" => Ok(Self::Opf),
            "none" => Ok(Self::None),
            other => Err(format!("unknown import metadata kind: {other}")),
        }
    }
}

pub fn write_import_metadata_snapshot(
    storage_dir: &Path,
    snapshot: &ImportMetadataSnapshot,
) -> Result<(), String> {
    std::fs::write(
        import_metadata_kind_path(storage_dir),
        snapshot.kind.as_str(),
    )
    .map_err(|error| format!("write import metadata kind: {error}"))?;

    let xml_path = import_metadata_xml_path(storage_dir);
    if let Some(xml) = snapshot.xml.as_deref().filter(|v| !v.trim().is_empty()) {
        std::fs::write(&xml_path, xml)
            .map_err(|error| format!("write import metadata xml: {error}"))?;
    } else if xml_path.exists() {
        std::fs::remove_file(&xml_path)
            .map_err(|error| format!("remove import metadata xml: {error}"))?;
    }

    Ok(())
}

pub fn read_import_metadata_snapshot(storage_dir: &Path) -> ImportMetadataSnapshot {
    let kind_path = import_metadata_kind_path(storage_dir);
    if !kind_path.is_file() {
        return ImportMetadataSnapshot::none();
    }

    let kind_raw = std::fs::read_to_string(&kind_path).unwrap_or_default();
    let kind = ImportMetadataKind::from_str(&kind_raw).unwrap_or(ImportMetadataKind::None);
    if kind == ImportMetadataKind::None {
        return ImportMetadataSnapshot::none();
    }

    let xml_path = import_metadata_xml_path(storage_dir);
    let xml = xml_path
        .is_file()
        .then(|| std::fs::read_to_string(&xml_path).ok())
        .flatten()
        .filter(|value| !value.trim().is_empty());

    ImportMetadataSnapshot { kind, xml }
}

#[cfg(test)]
mod tests {
    use super::*;
    use uuid::Uuid;

    fn temp_storage() -> std::path::PathBuf {
        let dir = std::env::temp_dir().join(format!("cbm-snapshot-{}", Uuid::new_v4()));
        std::fs::create_dir_all(&dir).expect("create dir");
        dir
    }

    #[test]
    fn round_trip_comicinfo_snapshot() {
        let dir = temp_storage();
        let xml = r#"<?xml version="1.0"?><ComicInfo><Title>T</Title></ComicInfo>"#;
        write_import_metadata_snapshot(&dir, &ImportMetadataSnapshot::comicinfo(xml))
            .expect("write");

        let loaded = read_import_metadata_snapshot(&dir);
        assert_eq!(loaded.kind, ImportMetadataKind::ComicInfo);
        assert_eq!(loaded.xml.as_deref(), Some(xml));
    }

    #[test]
    fn none_snapshot_writes_kind_only() {
        let dir = temp_storage();
        write_import_metadata_snapshot(&dir, &ImportMetadataSnapshot::none()).expect("write");
        let loaded = read_import_metadata_snapshot(&dir);
        assert_eq!(loaded.kind, ImportMetadataKind::None);
        assert!(loaded.xml.is_none());
    }

    #[test]
    fn missing_files_read_as_none() {
        let dir = temp_storage();
        let loaded = read_import_metadata_snapshot(&dir);
        assert_eq!(loaded, ImportMetadataSnapshot::none());
    }
}
