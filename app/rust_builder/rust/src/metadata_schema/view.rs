//! 跨 FRB 的 Metadata 编辑 schema DTO（由静态 schema 物化，避免在 api 层重复 From 实现）。

use crate::metadata_schema::{MetadataFieldKind, MetadataFieldSpec, MetadataSectionSpec};
use crate::project_format::ExportFormat;

#[derive(Clone, Debug)]
pub struct MetadataFieldSpecDto {
    pub id: String,
    pub label: String,
    pub hint: Option<String>,
    pub kind: MetadataFieldKind,
    pub required: bool,
    pub options: Vec<String>,
    pub int_min: Option<i32>,
    pub int_max: Option<i32>,
    pub read_only_value: Option<String>,
    pub form_field_ids: Vec<String>,
}

#[derive(Clone, Debug)]
pub struct MetadataSectionSpecDto {
    pub id: String,
    pub label: String,
    pub fields: Vec<MetadataFieldSpecDto>,
}

#[derive(Clone, Debug)]
pub struct MetadataEditorSchemaDto {
    pub editor_title: String,
    pub editable: bool,
    pub pdf_message: Option<String>,
    pub sections: Vec<MetadataSectionSpecDto>,
    pub age_rating_presets: Vec<String>,
}

pub fn editor_schema_dto(export_format: ExportFormat) -> MetadataEditorSchemaDto {
    let schema = crate::metadata_schema::editor_schema(export_format);
    MetadataEditorSchemaDto {
        editor_title: schema.editor_title.to_string(),
        editable: schema.editable,
        pdf_message: schema.pdf_message.map(str::to_string),
        sections: schema.sections.iter().map(section_to_dto).collect(),
        age_rating_presets: crate::metadata_schema::AGE_RATING_PRESETS
            .iter()
            .map(|preset| (*preset).to_string())
            .collect(),
    }
}

fn section_to_dto(section: &MetadataSectionSpec) -> MetadataSectionSpecDto {
    MetadataSectionSpecDto {
        id: section.id.to_string(),
        label: section.label.to_string(),
        fields: section.fields.iter().map(field_to_dto).collect(),
    }
}

fn field_to_dto(field: &MetadataFieldSpec) -> MetadataFieldSpecDto {
    MetadataFieldSpecDto {
        id: field.id.to_string(),
        label: field.label.to_string(),
        hint: field.hint.map(str::to_string),
        kind: field.kind,
        required: field.required,
        options: field.options.iter().map(|option| (*option).to_string()).collect(),
        int_min: field.int_min,
        int_max: field.int_max,
        read_only_value: field.read_only_value.map(str::to_string),
        form_field_ids: crate::metadata_schema::form_field_ids(field)
            .iter()
            .map(|id| (*id).to_string())
            .collect(),
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::project_format::ExportFormat;

    #[test]
    fn editor_schema_dto_propagates_field_hints() {
        let dto = editor_schema_dto(ExportFormat::ComicArchive);
        let general = &dto.sections[0];
        let language = general
            .fields
            .iter()
            .find(|field| field.id == "language_iso")
            .expect("language_iso");
        assert_eq!(language.hint.as_deref(), Some("如 zh-CN"));

        let series = &dto.sections[1];
        let number = series
            .fields
            .iter()
            .find(|field| field.id == "number")
            .expect("number");
        assert_eq!(number.hint.as_deref(), Some("如 1A"));
    }
}
