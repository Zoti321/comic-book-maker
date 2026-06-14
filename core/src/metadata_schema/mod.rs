//! Metadata 编辑 schema：canonical 字段定义与表单合并规则。

mod view;

pub use view::{
    editor_schema_dto, MetadataEditorSchemaDto, MetadataFieldSpecDto, MetadataSectionSpecDto,
};

use std::collections::HashMap;

use crate::db::{normalize_metadata, MetadataRecord};
use crate::project_format::ExportFormat;
use crate::published_date::{
    merge_published_date_form_fields, published_date_day_display, published_date_month_display,
    published_date_year_display,
};

pub const AGE_RATING_PRESETS: &[&str] = crate::age_rating::PRESETS;

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MetadataFieldKind {
    Text,
    MultilineText,
    Integer,
    AgeRating,
    PublishedDate,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MetadataFieldSpec {
    pub id: &'static str,
    pub label: &'static str,
    pub kind: MetadataFieldKind,
    pub required: bool,
    pub options: &'static [&'static str],
    pub int_min: Option<i32>,
    pub int_max: Option<i32>,
    pub read_only_value: Option<&'static str>,
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MetadataSectionSpec {
    pub id: &'static str,
    pub label: &'static str,
    pub fields: &'static [MetadataFieldSpec],
}

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub struct MetadataEditorSchema {
    pub editor_title: &'static str,
    pub editable: bool,
    pub pdf_message: Option<&'static str>,
    pub sections: &'static [MetadataSectionSpec],
}

macro_rules! text_field {
    ($id:expr, $label:expr) => {
        MetadataFieldSpec {
            id: $id,
            label: $label,
            kind: MetadataFieldKind::Text,
            required: false,
            options: &[],
            int_min: None,
            int_max: None,
            read_only_value: None,
        }
    };
    ($id:expr, $label:expr, required) => {
        MetadataFieldSpec {
            id: $id,
            label: $label,
            kind: MetadataFieldKind::Text,
            required: true,
            options: &[],
            int_min: None,
            int_max: None,
            read_only_value: None,
        }
    };
}

macro_rules! multiline_field {
    ($id:expr, $label:expr) => {
        MetadataFieldSpec {
            id: $id,
            label: $label,
            kind: MetadataFieldKind::MultilineText,
            required: false,
            options: &[],
            int_min: None,
            int_max: None,
            read_only_value: None,
        }
    };
}

const GENERAL_FIELDS: &[MetadataFieldSpec] = &[
    text_field!("title", "标题", required),
    MetadataFieldSpec {
        id: "published_date",
        label: "发布日期",
        kind: MetadataFieldKind::PublishedDate,
        required: false,
        options: &[],
        int_min: None,
        int_max: None,
        read_only_value: None,
    },
    text_field!("language_iso", "语言 (ISO，如 zh-CN)"),
    MetadataFieldSpec {
        id: "age_rating",
        label: "年龄分级",
        kind: MetadataFieldKind::AgeRating,
        required: false,
        options: &[],
        int_min: None,
        int_max: None,
        read_only_value: None,
    },
    multiline_field!("description", "描述"),
];

const SERIES_FIELDS: &[MetadataFieldSpec] = &[
    text_field!("series", "系列"),
    text_field!("number", "期号"),
    text_field!("series_count", "系列总期数"),
];

const CREATIVE_FIELDS: &[MetadataFieldSpec] = &[
    text_field!("author", "作者"),
    text_field!("tags", "标签（逗号分隔）"),
    text_field!("characters", "登场人物"),
];

const CANONICAL_SECTIONS: &[MetadataSectionSpec] = &[
    MetadataSectionSpec {
        id: "general",
        label: "常规",
        fields: GENERAL_FIELDS,
    },
    MetadataSectionSpec {
        id: "series",
        label: "系列",
        fields: SERIES_FIELDS,
    },
    MetadataSectionSpec {
        id: "creative",
        label: "创作",
        fields: CREATIVE_FIELDS,
    },
];

const CANONICAL_SCHEMA: MetadataEditorSchema = MetadataEditorSchema {
    editor_title: "元数据",
    editable: true,
    pdf_message: None,
    sections: CANONICAL_SECTIONS,
};

pub fn editor_schema(_export_format: ExportFormat) -> &'static MetadataEditorSchema {
    &CANONICAL_SCHEMA
}

pub fn field_display_value(metadata: &MetadataRecord, field_id: &str) -> String {
    match field_id {
        "title" => metadata.title.clone(),
        "series" => metadata.series.clone().unwrap_or_default(),
        "number" => metadata.number.clone().unwrap_or_default(),
        "series_count" => metadata.series_count.clone().unwrap_or_default(),
        "published_date_year" => metadata
            .published_date
            .as_deref()
            .map(published_date_year_display)
            .unwrap_or_default(),
        "published_date_month" => metadata
            .published_date
            .as_deref()
            .map(published_date_month_display)
            .unwrap_or_default(),
        "published_date_day" => metadata
            .published_date
            .as_deref()
            .map(published_date_day_display)
            .unwrap_or_default(),
        "language_iso" => metadata.language_iso.clone().unwrap_or_default(),
        "author" => metadata.author.clone().unwrap_or_default(),
        "tags" => metadata.tags.clone().unwrap_or_default(),
        "characters" => metadata.characters.clone().unwrap_or_default(),
        "age_rating" => crate::age_rating::normalize(metadata.age_rating.as_deref())
            .unwrap_or_default(),
        "description" => metadata.description.clone().unwrap_or_default(),
        "cover_page_index" => metadata.cover_page_index.to_string(),
        "page_count" => metadata.page_count.to_string(),
        _ => String::new(),
    }
}

fn optional_trimmed(value: &str) -> Option<String> {
    let trimmed = value.trim();
    if trimmed.is_empty() {
        None
    } else {
        Some(trimmed.to_string())
    }
}

/// ComicInfo `<Tags>`：逗号分隔，逗号后不含空格（如 `a,b` 而非 `a, b`）。
pub fn normalize_comma_separated_tags(raw: &str) -> Option<String> {
    let parts: Vec<String> = raw
        .split(',')
        .map(str::trim)
        .filter(|part| !part.is_empty())
        .map(ToString::to_string)
        .collect();
    if parts.is_empty() {
        None
    } else {
        Some(parts.join(","))
    }
}

/// 同步 UI 页数到 Metadata（不写入数据库）。
pub fn with_page_count(mut record: MetadataRecord, page_count: i32) -> MetadataRecord {
    record.page_count = page_count;
    record
}

/// 更新封面页索引（不写入数据库）。
pub fn with_cover_page_index(mut record: MetadataRecord, cover_page_index: i32) -> MetadataRecord {
    record.cover_page_index = cover_page_index;
    record
}

/// 保留 FRB API；canonical 模型无下拉字段。
pub fn with_dropdown_field(
    _record: MetadataRecord,
    field_id: &str,
    _value: Option<String>,
) -> Result<MetadataRecord, String> {
    Err(format!("unsupported dropdown field: {field_id}"))
}

pub fn merge_form_values(
    base: &MetadataRecord,
    export_format: ExportFormat,
    values: &HashMap<String, String>,
    page_count: i32,
) -> Result<MetadataRecord, String> {
    let schema = editor_schema(export_format);
    if !schema.editable {
        return Err("metadata editor is not editable for this export format".to_string());
    }

    let title = values
        .get("title")
        .map(|v| v.trim().to_string())
        .filter(|v| !v.is_empty())
        .ok_or_else(|| "title must not be empty".to_string())?;

    let published_date = merge_published_date_form_fields(
        values
            .get("published_date_year")
            .map(String::as_str)
            .unwrap_or(""),
        values
            .get("published_date_month")
            .map(String::as_str)
            .unwrap_or(""),
        values
            .get("published_date_day")
            .map(String::as_str)
            .unwrap_or(""),
    )?;

    let cover_page_index = base.cover_page_index;

    let merged = MetadataRecord {
        title,
        series: optional_trimmed(values.get("series").map(String::as_str).unwrap_or("")),
        number: optional_trimmed(values.get("number").map(String::as_str).unwrap_or("")),
        series_count: optional_trimmed(
            values
                .get("series_count")
                .map(String::as_str)
                .unwrap_or(""),
        ),
        published_date,
        language_iso: optional_trimmed(
            values
                .get("language_iso")
                .map(String::as_str)
                .unwrap_or(""),
        ),
        author: normalize_comma_separated_tags(
            values.get("author").map(String::as_str).unwrap_or(""),
        ),
        tags: normalize_comma_separated_tags(values.get("tags").map(String::as_str).unwrap_or("")),
        characters: normalize_comma_separated_tags(
            values.get("characters").map(String::as_str).unwrap_or(""),
        ),
        age_rating: crate::age_rating::validate_for_save(
            values.get("age_rating").map(String::as_str),
        )?,
        description: optional_trimmed(
            values
                .get("description")
                .map(String::as_str)
                .unwrap_or(""),
        ),
        cover_page_index,
        page_count,
        ..base.clone()
    };

    let normalized = normalize_metadata(merged);
    normalized.validate(page_count)?;
    Ok(normalized)
}

#[cfg(test)]
mod tests {
    use super::*;

    fn sample_base() -> MetadataRecord {
        MetadataRecord {
            title: "Base".to_string(),
            cover_page_index: 1,
            page_count: 3,
            ..Default::default()
        }
    }

    #[test]
    fn canonical_schema_is_format_agnostic() {
        let comic = editor_schema(ExportFormat::ComicArchive);
        let epub = editor_schema(ExportFormat::Epub);
        assert_eq!(comic.editor_title, epub.editor_title);
        assert_eq!(comic.sections.len(), 3);
        assert_eq!(comic.sections[0].id, "general");
        assert_eq!(comic.sections[1].id, "series");
        assert_eq!(comic.sections[2].id, "creative");
    }

    #[test]
    fn merge_updates_canonical_fields() {
        let base = sample_base();
        let mut values = HashMap::new();
        values.insert("title".to_string(), "Comic Title".to_string());
        values.insert("author".to_string(), "Author".to_string());
        values.insert("published_date_year".to_string(), "2024".to_string());
        values.insert("published_date_month".to_string(), "5".to_string());
        values.insert("published_date_day".to_string(), "31".to_string());
        let merged =
            merge_form_values(&base, ExportFormat::ComicArchive, &values, 3).expect("merge");
        assert_eq!(merged.author.as_deref(), Some("Author"));
        assert_eq!(merged.published_date.as_deref(), Some("2024-05-31"));
        assert_eq!(merged.cover_page_index, base.cover_page_index);
    }

    #[test]
    fn merge_rejects_invalid_published_date() {
        let base = sample_base();
        let mut values = HashMap::new();
        values.insert("title".to_string(), "Comic Title".to_string());
        values.insert("published_date_year".to_string(), "2024".to_string());
        values.insert("published_date_month".to_string(), "13".to_string());
        assert!(merge_form_values(&base, ExportFormat::ComicArchive, &values, 3).is_err());
    }

    #[test]
    fn merge_rejects_invalid_age_rating() {
        let base = sample_base();
        let mut values = HashMap::new();
        values.insert("title".to_string(), "Comic Title".to_string());
        values.insert("age_rating".to_string(), "Teen".to_string());
        assert!(merge_form_values(&base, ExportFormat::ComicArchive, &values, 3).is_err());
    }

    #[test]
    fn merge_accepts_canonical_age_rating() {
        let base = sample_base();
        let mut values = HashMap::new();
        values.insert("title".to_string(), "Comic Title".to_string());
        values.insert("age_rating".to_string(), "Everyone".to_string());
        let merged =
            merge_form_values(&base, ExportFormat::ComicArchive, &values, 3).expect("merge");
        assert_eq!(merged.age_rating.as_deref(), Some("Everyone"));
    }

    #[test]
    fn merge_normalizes_author_comma_separated_tags() {
        let base = sample_base();
        let mut values = HashMap::new();
        values.insert("title".to_string(), "Comic Title".to_string());
        values.insert("author".to_string(), "Alice, Bob".to_string());
        let merged =
            merge_form_values(&base, ExportFormat::ComicArchive, &values, 3).expect("merge");
        assert_eq!(merged.author.as_deref(), Some("Alice,Bob"));
    }

    #[test]
    fn normalize_comma_separated_tags_strips_spaces_after_commas() {
        assert_eq!(
            normalize_comma_separated_tags("肉便器, 群交").as_deref(),
            Some("肉便器,群交")
        );
    }
}
