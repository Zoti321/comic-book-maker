//! Metadata 编辑 schema：按 Export 格式定义分段、字段与表单合并规则。
//! Import/Export 映射仍分别在 `import/metadata`、`export_cbz`、`epub_format`。

mod view;

pub use view::{
    editor_schema_dto, MetadataEditorSchemaDto, MetadataFieldSpecDto, MetadataSectionSpecDto,
};

use std::collections::HashMap;

use crate::comicinfo::{BLACK_AND_WHITE_VALUES, MANGA_VALUES};
use crate::db::{normalize_metadata, MetadataRecord};
use crate::project_format::ExportFormat;

pub const AGE_RATING_PRESETS: &[&str] = &[
    "Adults Only 18+",
    "Everyone",
    "R18+",
    "Unknown",
];

pub const PDF_EDITOR_MESSAGE: &str =
    "PDF Export 尚未实现。请将 Export 格式改为 EPUB 或漫画压缩包后再编辑导出元数据。";

/// EPUB 固定版式 meta（与 `epub_format::append_comic_rendition_metadata` 写入项对齐）。
pub const OPF_FIXED_LAYOUT_FIELDS: &[(&str, &str)] = &[
    ("rendition:layout", "pre-paginated"),
    ("rendition:spread", "landscape"),
    ("book-type", "comic"),
    ("fixed-layout", "true"),
    ("zero-gutter", "true"),
    ("zero-margin", "true"),
    ("RegionMagnification", "true"),
    ("orientation-lock", "portrait"),
    ("primary-writing-mode", "horizontal-rl"),
    (
        "original-resolution",
        "Export 时按封面 Page Image 像素自动写入",
    ),
];

#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum MetadataFieldKind {
    Text,
    MultilineText,
    Integer,
    Dropdown,
    ReadOnly,
    AgeRating,
    CoverPageIndex,
    PageCountInfo,
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

macro_rules! int_field {
    ($id:expr, $label:expr, $min:expr, $max:expr) => {
        MetadataFieldSpec {
            id: $id,
            label: $label,
            kind: MetadataFieldKind::Integer,
            required: false,
            options: &[],
            int_min: Some($min),
            int_max: Some($max),
            read_only_value: None,
        }
    };
}

macro_rules! dropdown_field {
    ($id:expr, $label:expr, $options:expr) => {
        MetadataFieldSpec {
            id: $id,
            label: $label,
            kind: MetadataFieldKind::Dropdown,
            required: false,
            options: $options,
            int_min: None,
            int_max: None,
            read_only_value: None,
        }
    };
}

macro_rules! readonly_field {
    ($id:expr, $label:expr, $value:expr) => {
        MetadataFieldSpec {
            id: $id,
            label: $label,
            kind: MetadataFieldKind::ReadOnly,
            required: false,
            options: &[],
            int_min: None,
            int_max: None,
            read_only_value: Some($value),
        }
    };
}

const COMIC_BASIC: &[MetadataFieldSpec] = &[
    text_field!("title", "标题", required),
    text_field!("series", "系列"),
    text_field!("issue_number", "期号"),
    text_field!("series_count", "系列总期数"),
    text_field!("volume", "卷号"),
    text_field!("alternate_series", "Alternate Series"),
    text_field!("alternate_number", "Alternate Number"),
    text_field!("alternate_count", "Alternate Count"),
];

const COMIC_PUBLISHING: &[MetadataFieldSpec] = &[
    int_field!("year", "年", 1000, 9999),
    int_field!("month", "月", 1, 12),
    int_field!("day", "日", 1, 31),
    text_field!("publisher", "出版社"),
    text_field!("imprint", "品牌线"),
    text_field!("language_iso", "语言 (ISO，如 zh-CN)"),
    text_field!("format", "格式"),
];

const COMIC_PEOPLE: &[MetadataFieldSpec] = &[
    text_field!("writer", "编剧"),
    text_field!("penciller", "铅笔稿"),
    text_field!("inker", "勾线"),
    text_field!("colorist", "上色"),
    text_field!("letterer", "字体"),
    text_field!("cover_artist", "封面"),
    text_field!("editor", "编辑"),
    text_field!("translator", "翻译"),
];

const COMIC_CLASSIFICATION: &[MetadataFieldSpec] = &[
    text_field!("genre", "类型"),
    text_field!("tags", "标签（逗号分隔）"),
    dropdown_field!("black_and_white", "黑白", BLACK_AND_WHITE_VALUES),
    dropdown_field!("manga", "漫画阅读方向", MANGA_VALUES),
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
    text_field!("community_rating", "社区评分 (0–5)"),
];

const COMIC_STORY: &[MetadataFieldSpec] = &[
    text_field!("characters", "角色"),
    text_field!("teams", "团队"),
    text_field!("locations", "地点"),
    text_field!("main_character_or_team", "主角/主团队"),
    text_field!("story_arc", "故事线"),
    text_field!("story_arc_number", "故事线编号"),
    text_field!("series_group", "系列组"),
];

const COMIC_DESCRIPTION: &[MetadataFieldSpec] = &[
    multiline_field!("summary", "简介"),
    multiline_field!("notes", "备注"),
    text_field!("web", "链接"),
    text_field!("scan_information", "扫描信息"),
    text_field!("review", "评论"),
    text_field!("gtin", "GTIN / ISBN"),
];

// 页数、封面页不在元数据 Tab 编辑：页数由应用/导入同步；封面在图片 Tab 设置。

const COMIC_INFO_SECTIONS: &[MetadataSectionSpec] = &[
    MetadataSectionSpec {
        id: "basic",
        label: "基本",
        fields: COMIC_BASIC,
    },
    MetadataSectionSpec {
        id: "publishing",
        label: "出版",
        fields: COMIC_PUBLISHING,
    },
    MetadataSectionSpec {
        id: "people",
        label: "人员",
        fields: COMIC_PEOPLE,
    },
    MetadataSectionSpec {
        id: "classification",
        label: "分类",
        fields: COMIC_CLASSIFICATION,
    },
    MetadataSectionSpec {
        id: "story",
        label: "故事",
        fields: COMIC_STORY,
    },
    MetadataSectionSpec {
        id: "description",
        label: "描述",
        fields: COMIC_DESCRIPTION,
    },
];

const OPF_METADATA: &[MetadataFieldSpec] = &[
    text_field!("title", "标题", required),
    text_field!("series", "系列"),
    text_field!("issue_number", "Number"),
    text_field!("volume", "卷号"),
    text_field!("writer", "作者 / Creator"),
    text_field!("publisher", "出版社 / Publisher"),
    text_field!("language_iso", "语言 (ISO，如 zh-CN)"),
    multiline_field!("summary", "简介"),
    text_field!("web", "来源链接 / Source"),
    text_field!("gtin", "标识符 (GTIN/ISBN)"),
    text_field!("characters", "角色（逗号分隔）"),
    text_field!("tags", "标签（逗号分隔）"),
];

const OPF_FIXED_LAYOUT: &[MetadataFieldSpec] = &[
    readonly_field!("opf_rendition_layout", "rendition:layout", "pre-paginated"),
    readonly_field!("opf_rendition_spread", "rendition:spread", "landscape"),
    readonly_field!("opf_book_type", "book-type", "comic"),
    readonly_field!("opf_fixed_layout", "fixed-layout", "true"),
    readonly_field!("opf_zero_gutter", "zero-gutter", "true"),
    readonly_field!("opf_zero_margin", "zero-margin", "true"),
    readonly_field!(
        "opf_region_magnification",
        "RegionMagnification",
        "true"
    ),
    readonly_field!("opf_orientation_lock", "orientation-lock", "portrait"),
    readonly_field!(
        "opf_primary_writing_mode",
        "primary-writing-mode",
        "horizontal-rl"
    ),
    readonly_field!(
        "opf_original_resolution",
        "original-resolution",
        "Export 时按封面 Page Image 像素自动写入"
    ),
];

const OPF_SECTIONS: &[MetadataSectionSpec] = &[
    MetadataSectionSpec {
        id: "opf",
        label: "OPF 元数据",
        fields: OPF_METADATA,
    },
    MetadataSectionSpec {
        id: "fixed_layout",
        label: "固定版式",
        fields: OPF_FIXED_LAYOUT,
    },
];

const COMIC_ARCHIVE_SCHEMA: MetadataEditorSchema = MetadataEditorSchema {
    editor_title: "ComicInfo",
    editable: true,
    pdf_message: None,
    sections: COMIC_INFO_SECTIONS,
};

const EPUB_SCHEMA: MetadataEditorSchema = MetadataEditorSchema {
    editor_title: "OPF Metadata",
    editable: true,
    pdf_message: None,
    sections: OPF_SECTIONS,
};

const PDF_SCHEMA: MetadataEditorSchema = MetadataEditorSchema {
    editor_title: "PDF Export",
    editable: false,
    pdf_message: Some(PDF_EDITOR_MESSAGE),
    sections: &[],
};

pub fn editor_schema(export_format: ExportFormat) -> &'static MetadataEditorSchema {
    match export_format {
        ExportFormat::ComicArchive => &COMIC_ARCHIVE_SCHEMA,
        ExportFormat::Epub => &EPUB_SCHEMA,
        ExportFormat::Pdf => &PDF_SCHEMA,
    }
}

pub fn field_display_value(metadata: &MetadataRecord, field_id: &str) -> String {
    match field_id {
        "title" => metadata.title.clone(),
        "series" => metadata.series.clone().unwrap_or_default(),
        "issue_number" => metadata.issue_number.clone().unwrap_or_default(),
        "series_count" => metadata.series_count.clone().unwrap_or_default(),
        "volume" => metadata.volume.clone().unwrap_or_default(),
        "alternate_series" => metadata.alternate_series.clone().unwrap_or_default(),
        "alternate_number" => metadata.alternate_number.clone().unwrap_or_default(),
        "alternate_count" => metadata.alternate_count.clone().unwrap_or_default(),
        "summary" => metadata.summary.clone().unwrap_or_default(),
        "notes" => metadata.notes.clone().unwrap_or_default(),
        "year" => metadata.year.map(|v| v.to_string()).unwrap_or_default(),
        "month" => metadata.month.map(|v| v.to_string()).unwrap_or_default(),
        "day" => metadata.day.map(|v| v.to_string()).unwrap_or_default(),
        "writer" => metadata.writer.clone().unwrap_or_default(),
        "penciller" => metadata.penciller.clone().unwrap_or_default(),
        "inker" => metadata.inker.clone().unwrap_or_default(),
        "colorist" => metadata.colorist.clone().unwrap_or_default(),
        "letterer" => metadata.letterer.clone().unwrap_or_default(),
        "cover_artist" => metadata.cover_artist.clone().unwrap_or_default(),
        "editor" => metadata.editor.clone().unwrap_or_default(),
        "translator" => metadata.translator.clone().unwrap_or_default(),
        "publisher" => metadata.publisher.clone().unwrap_or_default(),
        "imprint" => metadata.imprint.clone().unwrap_or_default(),
        "genre" => metadata.genre.clone().unwrap_or_default(),
        "tags" => metadata.tags.clone().unwrap_or_default(),
        "web" => metadata.web.clone().unwrap_or_default(),
        "language_iso" => metadata.language_iso.clone().unwrap_or_default(),
        "format" => metadata.format.clone().unwrap_or_default(),
        "black_and_white" => metadata.black_and_white.clone().unwrap_or_default(),
        "manga" => metadata.manga.clone().unwrap_or_default(),
        "characters" => metadata.characters.clone().unwrap_or_default(),
        "teams" => metadata.teams.clone().unwrap_or_default(),
        "locations" => metadata.locations.clone().unwrap_or_default(),
        "main_character_or_team" => metadata
            .main_character_or_team
            .clone()
            .unwrap_or_default(),
        "scan_information" => metadata.scan_information.clone().unwrap_or_default(),
        "story_arc" => metadata.story_arc.clone().unwrap_or_default(),
        "story_arc_number" => metadata.story_arc_number.clone().unwrap_or_default(),
        "series_group" => metadata.series_group.clone().unwrap_or_default(),
        "age_rating" => metadata.age_rating.clone().unwrap_or_default(),
        "community_rating" => metadata.community_rating.clone().unwrap_or_default(),
        "review" => metadata.review.clone().unwrap_or_default(),
        "gtin" => metadata.gtin.clone().unwrap_or_default(),
        "cover_page_index" => metadata.cover_page_index.to_string(),
        "page_count" => metadata.page_count.to_string(),
        id if id.starts_with("opf_") => find_read_only_field(id)
            .and_then(|field| field.read_only_value)
            .unwrap_or_default()
            .to_string(),
        _ => String::new(),
    }
}

fn find_read_only_field(field_id: &str) -> Option<&'static MetadataFieldSpec> {
    OPF_FIXED_LAYOUT
        .iter()
        .find(|field| field.id == field_id)
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

fn parse_optional_int(value: &str) -> Option<i32> {
    let trimmed = value.trim();
    if trimmed.is_empty() {
        None
    } else {
        trimmed.parse().ok()
    }
}

fn parse_cover_page_index(values: &HashMap<String, String>, base: &MetadataRecord) -> i32 {
    values
        .get("cover_page_index")
        .and_then(|text| text.trim().parse().ok())
        .unwrap_or(base.cover_page_index)
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

/// 更新下拉类字段（`black_and_white` / `manga`）。
pub fn with_dropdown_field(
    mut record: MetadataRecord,
    field_id: &str,
    value: Option<String>,
) -> Result<MetadataRecord, String> {
    match field_id {
        "black_and_white" => record.black_and_white = value,
        "manga" => record.manga = value,
        other => return Err(format!("unsupported dropdown field: {other}")),
    }
    Ok(record)
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

    let cover_page_index = parse_cover_page_index(values, base);

    let merged = match export_format {
        ExportFormat::Epub => MetadataRecord {
            title,
            series: optional_trimmed(values.get("series").map(String::as_str).unwrap_or("")),
            issue_number: optional_trimmed(
                values
                    .get("issue_number")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            volume: optional_trimmed(values.get("volume").map(String::as_str).unwrap_or("")),
            summary: optional_trimmed(values.get("summary").map(String::as_str).unwrap_or("")),
            writer: optional_trimmed(values.get("writer").map(String::as_str).unwrap_or("")),
            publisher: optional_trimmed(
                values
                    .get("publisher")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            language_iso: optional_trimmed(
                values
                    .get("language_iso")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            web: optional_trimmed(values.get("web").map(String::as_str).unwrap_or("")),
            gtin: optional_trimmed(values.get("gtin").map(String::as_str).unwrap_or("")),
            characters: normalize_comma_separated_tags(
                values.get("characters").map(String::as_str).unwrap_or(""),
            ),
            tags: normalize_comma_separated_tags(
                values.get("tags").map(String::as_str).unwrap_or(""),
            ),
            cover_page_index,
            page_count,
            ..base.clone()
        },
        ExportFormat::ComicArchive => MetadataRecord {
            title,
            series: optional_trimmed(values.get("series").map(String::as_str).unwrap_or("")),
            issue_number: optional_trimmed(
                values
                    .get("issue_number")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            series_count: optional_trimmed(
                values
                    .get("series_count")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            volume: optional_trimmed(values.get("volume").map(String::as_str).unwrap_or("")),
            alternate_series: optional_trimmed(
                values
                    .get("alternate_series")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            alternate_number: optional_trimmed(
                values
                    .get("alternate_number")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            alternate_count: optional_trimmed(
                values
                    .get("alternate_count")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            summary: optional_trimmed(values.get("summary").map(String::as_str).unwrap_or("")),
            notes: optional_trimmed(values.get("notes").map(String::as_str).unwrap_or("")),
            year: parse_optional_int(values.get("year").map(String::as_str).unwrap_or("")),
            month: parse_optional_int(values.get("month").map(String::as_str).unwrap_or("")),
            day: parse_optional_int(values.get("day").map(String::as_str).unwrap_or("")),
            writer: optional_trimmed(values.get("writer").map(String::as_str).unwrap_or("")),
            penciller: optional_trimmed(
                values
                    .get("penciller")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            inker: optional_trimmed(values.get("inker").map(String::as_str).unwrap_or("")),
            colorist: optional_trimmed(
                values
                    .get("colorist")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            letterer: optional_trimmed(
                values
                    .get("letterer")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            cover_artist: optional_trimmed(
                values
                    .get("cover_artist")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            editor: optional_trimmed(values.get("editor").map(String::as_str).unwrap_or("")),
            translator: optional_trimmed(
                values
                    .get("translator")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            publisher: optional_trimmed(
                values
                    .get("publisher")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            imprint: optional_trimmed(values.get("imprint").map(String::as_str).unwrap_or("")),
            genre: optional_trimmed(values.get("genre").map(String::as_str).unwrap_or("")),
            tags: normalize_comma_separated_tags(
                values.get("tags").map(String::as_str).unwrap_or(""),
            ),
            web: optional_trimmed(values.get("web").map(String::as_str).unwrap_or("")),
            language_iso: optional_trimmed(
                values
                    .get("language_iso")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            format: optional_trimmed(values.get("format").map(String::as_str).unwrap_or("")),
            black_and_white: values
                .get("black_and_white")
                .and_then(|v| optional_trimmed(v))
                .or(base.black_and_white.clone()),
            manga: values
                .get("manga")
                .and_then(|v| optional_trimmed(v))
                .or(base.manga.clone()),
            characters: optional_trimmed(
                values
                    .get("characters")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            teams: optional_trimmed(values.get("teams").map(String::as_str).unwrap_or("")),
            locations: optional_trimmed(
                values
                    .get("locations")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            main_character_or_team: optional_trimmed(
                values
                    .get("main_character_or_team")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            scan_information: optional_trimmed(
                values
                    .get("scan_information")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            story_arc: optional_trimmed(
                values
                    .get("story_arc")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            story_arc_number: optional_trimmed(
                values
                    .get("story_arc_number")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            series_group: optional_trimmed(
                values
                    .get("series_group")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            age_rating: optional_trimmed(
                values
                    .get("age_rating")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            community_rating: optional_trimmed(
                values
                    .get("community_rating")
                    .map(String::as_str)
                    .unwrap_or(""),
            ),
            review: optional_trimmed(values.get("review").map(String::as_str).unwrap_or("")),
            gtin: optional_trimmed(values.get("gtin").map(String::as_str).unwrap_or("")),
            cover_page_index,
            page_count,
        },
        ExportFormat::Pdf => {
            return Err("metadata editor is not editable for PDF export".to_string())
        }
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
            black_and_white: Some("Yes".to_string()),
            manga: Some("No".to_string()),
            cover_page_index: 1,
            page_count: 3,
            ..Default::default()
        }
    }

    #[test]
    fn comic_archive_schema_has_six_sections() {
        let schema = editor_schema(ExportFormat::ComicArchive);
        assert_eq!(schema.sections.len(), 6);
        assert!(schema.editable);
    }

    #[test]
    fn epub_merge_preserves_non_opf_fields() {
        let base = sample_base();
        let mut values = HashMap::new();
        values.insert("title".to_string(), "EPUB Title".to_string());
        values.insert("series".to_string(), "Series A".to_string());

        let merged =
            merge_form_values(&base, ExportFormat::Epub, &values, 3).expect("merge epub");
        assert_eq!(merged.title, "EPUB Title");
        assert_eq!(merged.series.as_deref(), Some("Series A"));
        assert_eq!(merged.black_and_white, base.black_and_white);
        assert_eq!(merged.penciller, base.penciller);
    }

    #[test]
    fn epub_merge_writes_characters_and_tags() {
        let base = sample_base();
        let mut values = HashMap::new();
        values.insert("title".to_string(), "EPUB Title".to_string());
        values.insert("characters".to_string(), "角色A, 角色B".to_string());
        values.insert("tags".to_string(), "标签A, 标签B".to_string());

        let merged =
            merge_form_values(&base, ExportFormat::Epub, &values, 3).expect("merge epub");
        assert_eq!(merged.characters.as_deref(), Some("角色A,角色B"));
        assert_eq!(merged.tags.as_deref(), Some("标签A,标签B"));
    }

    #[test]
    fn comic_archive_merge_updates_full_record() {
        let base = sample_base();
        let mut values = HashMap::new();
        values.insert("title".to_string(), "Comic Title".to_string());
        values.insert("writer".to_string(), "Author".to_string());
        values.insert("year".to_string(), "2024".to_string());
        let merged =
            merge_form_values(&base, ExportFormat::ComicArchive, &values, 3).expect("merge");
        assert_eq!(merged.writer.as_deref(), Some("Author"));
        assert_eq!(merged.year, Some(2024));
        assert_eq!(merged.cover_page_index, base.cover_page_index);
    }

    #[test]
    fn pdf_schema_is_read_only() {
        let schema = editor_schema(ExportFormat::Pdf);
        assert!(!schema.editable);
        assert!(schema.pdf_message.is_some());
    }

    #[test]
    fn normalize_comma_separated_tags_strips_spaces_after_commas() {
        assert_eq!(
            normalize_comma_separated_tags("肉便器, 群交").as_deref(),
            Some("肉便器,群交")
        );
        assert_eq!(
            normalize_comma_separated_tags("  a , b , ").as_deref(),
            Some("a,b")
        );
    }
}
