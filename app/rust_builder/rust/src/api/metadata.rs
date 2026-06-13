//! Metadata FRB：以 `#[frb(mirror)]` 对齐 `MetadataRecord`，避免 api 层手写双份字段与 From 转换。

use anyhow::Result;
use std::collections::HashMap;

use crate::api::simple::ExportFormatFrb;
use crate::db::{Library, MetadataRecord};
use crate::metadata_schema::{
    self, editor_schema_dto, MetadataEditorSchemaDto, MetadataFieldSpecDto,
    MetadataSectionSpecDto,
};

/// FRB Metadata DTO；字段与 [`MetadataRecord`] 对齐，经宏与 `MetadataRecord` 互转。
#[flutter_rust_bridge::frb(non_final)]
#[derive(Clone, Debug, Default)]
pub struct Metadata {
    pub title: String,
    pub series: Option<String>,
    pub number: Option<String>,
    pub series_count: Option<String>,
    pub published_date: Option<String>,
    pub language_iso: Option<String>,
    pub author: Option<String>,
    pub tags: Option<String>,
    pub characters: Option<String>,
    pub age_rating: Option<String>,
    pub description: Option<String>,
    pub cover_page_index: i32,
    pub page_count: i32,
}

macro_rules! metadata_struct {
    ($src:ident) => {
        Metadata {
            title: $src.title,
            series: $src.series,
            number: $src.number,
            series_count: $src.series_count,
            published_date: $src.published_date,
            language_iso: $src.language_iso,
            author: $src.author,
            tags: $src.tags,
            characters: $src.characters,
            age_rating: $src.age_rating,
            description: $src.description,
            cover_page_index: $src.cover_page_index,
            page_count: $src.page_count,
        }
    };
}

macro_rules! metadata_record_struct {
    ($src:ident) => {
        MetadataRecord {
            title: $src.title,
            series: $src.series,
            number: $src.number,
            series_count: $src.series_count,
            published_date: $src.published_date,
            language_iso: $src.language_iso,
            author: $src.author,
            tags: $src.tags,
            characters: $src.characters,
            age_rating: $src.age_rating,
            description: $src.description,
            cover_page_index: $src.cover_page_index,
            page_count: $src.page_count,
        }
    };
}

impl From<MetadataRecord> for Metadata {
    fn from(record: MetadataRecord) -> Self {
        metadata_struct!(record)
    }
}

impl From<Metadata> for MetadataRecord {
    fn from(metadata: Metadata) -> Self {
        metadata_record_struct!(metadata)
    }
}

#[derive(Clone, Debug)]
#[flutter_rust_bridge::frb]
pub enum MetadataFieldKindFrb {
    Text,
    MultilineText,
    Integer,
    Dropdown,
    ReadOnly,
    AgeRating,
    PublishedDate,
    CoverPageIndex,
    PageCountInfo,
}

#[flutter_rust_bridge::frb(non_final)]
#[derive(Clone, Debug)]
pub struct MetadataFieldSpecFrb {
    pub id: String,
    pub label: String,
    pub kind: MetadataFieldKindFrb,
    pub required: bool,
    pub options: Vec<String>,
    pub int_min: Option<i32>,
    pub int_max: Option<i32>,
    pub read_only_value: Option<String>,
}

#[flutter_rust_bridge::frb(non_final)]
#[derive(Clone, Debug)]
pub struct MetadataSectionSpecFrb {
    pub id: String,
    pub label: String,
    pub fields: Vec<MetadataFieldSpecFrb>,
}

#[flutter_rust_bridge::frb(non_final)]
#[derive(Clone, Debug)]
pub struct MetadataEditorSchemaFrb {
    pub editor_title: String,
    pub editable: bool,
    pub pdf_message: Option<String>,
    pub sections: Vec<MetadataSectionSpecFrb>,
    pub age_rating_presets: Vec<String>,
}

#[flutter_rust_bridge::frb(non_final)]
#[derive(Clone, Debug)]
pub struct MetadataFieldValueFrb {
    pub field_id: String,
    pub value: String,
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_project_metadata(project_id: String) -> Result<Metadata> {
    Library::get_project_metadata(&project_id)
        .map(Into::into)
        .map_err(|error| anyhow::anyhow!(error))
}

#[flutter_rust_bridge::frb(sync)]
pub fn update_project_metadata(project_id: String, metadata: Metadata) -> Result<Metadata> {
    let record: MetadataRecord = metadata.into();
    Library::update_project_metadata(&project_id, record)
        .map(Into::into)
        .map_err(|error| anyhow::anyhow!(error))
}

#[flutter_rust_bridge::frb(sync)]
pub fn metadata_with_page_count(metadata: Metadata, page_count: i32) -> Metadata {
    metadata_schema::with_page_count(metadata.into(), page_count).into()
}

#[flutter_rust_bridge::frb(sync)]
pub fn metadata_with_cover_page_index(metadata: Metadata, cover_page_index: i32) -> Metadata {
    metadata_schema::with_cover_page_index(metadata.into(), cover_page_index).into()
}

#[flutter_rust_bridge::frb(sync)]
pub fn metadata_with_dropdown_field(
    metadata: Metadata,
    field_id: String,
    value: Option<String>,
) -> Result<Metadata> {
    metadata_schema::with_dropdown_field(metadata.into(), &field_id, value)
        .map(Into::into)
        .map_err(|error| anyhow::anyhow!(error))
}

#[flutter_rust_bridge::frb(sync)]
pub fn get_metadata_editor_schema(
    export_format: ExportFormatFrb,
) -> MetadataEditorSchemaFrb {
    editor_schema_dto(export_format.into()).into()
}

#[flutter_rust_bridge::frb(sync)]
pub fn metadata_field_display_value(metadata: Metadata, field_id: String) -> String {
    metadata_schema::field_display_value(&metadata.into(), &field_id)
}

#[flutter_rust_bridge::frb(sync)]
pub fn merge_metadata_from_form(
    export_format: ExportFormatFrb,
    base: Metadata,
    field_values: Vec<MetadataFieldValueFrb>,
    page_count: i32,
) -> Result<Metadata> {
    let values: HashMap<String, String> = field_values
        .into_iter()
        .map(|entry| (entry.field_id, entry.value))
        .collect();
    metadata_schema::merge_form_values(&base.into(), export_format.into(), &values, page_count)
        .map(Into::into)
        .map_err(|error| anyhow::anyhow!(error))
}

impl From<metadata_schema::MetadataFieldKind> for MetadataFieldKindFrb {
    fn from(value: metadata_schema::MetadataFieldKind) -> Self {
        match value {
            metadata_schema::MetadataFieldKind::Text => Self::Text,
            metadata_schema::MetadataFieldKind::MultilineText => Self::MultilineText,
            metadata_schema::MetadataFieldKind::Integer => Self::Integer,
            metadata_schema::MetadataFieldKind::Dropdown => Self::Dropdown,
            metadata_schema::MetadataFieldKind::ReadOnly => Self::ReadOnly,
            metadata_schema::MetadataFieldKind::AgeRating => Self::AgeRating,
            metadata_schema::MetadataFieldKind::PublishedDate => Self::PublishedDate,
            metadata_schema::MetadataFieldKind::CoverPageIndex => Self::CoverPageIndex,
            metadata_schema::MetadataFieldKind::PageCountInfo => Self::PageCountInfo,
        }
    }
}

impl From<MetadataFieldSpecDto> for MetadataFieldSpecFrb {
    fn from(value: MetadataFieldSpecDto) -> Self {
        Self {
            id: value.id,
            label: value.label,
            kind: value.kind.into(),
            required: value.required,
            options: value.options,
            int_min: value.int_min,
            int_max: value.int_max,
            read_only_value: value.read_only_value,
        }
    }
}

impl From<MetadataSectionSpecDto> for MetadataSectionSpecFrb {
    fn from(value: MetadataSectionSpecDto) -> Self {
        Self {
            id: value.id,
            label: value.label,
            fields: value.fields.into_iter().map(Into::into).collect(),
        }
    }
}

impl From<MetadataEditorSchemaDto> for MetadataEditorSchemaFrb {
    fn from(value: MetadataEditorSchemaDto) -> Self {
        Self {
            editor_title: value.editor_title,
            editable: value.editable,
            pdf_message: value.pdf_message,
            sections: value.sections.into_iter().map(Into::into).collect(),
            age_rating_presets: value.age_rating_presets,
        }
    }
}
