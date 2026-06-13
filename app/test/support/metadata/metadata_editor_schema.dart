import 'package:comic_book_maker/src/rust/api/metadata.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart';

/// 测试用 canonical schema fixture（与 Core `metadata_schema` 结构对齐）。
MetadataEditorSchemaFrb metadataEditorSchemaFixture(ExportFormatFrb exportFormat) {
  const agePresets = ['Adults Only 18+', 'Everyone', 'R18+', 'Unknown'];

  return MetadataEditorSchemaFrb(
    editorTitle: '元数据',
    editable: true,
    sections: [
      MetadataSectionSpecFrb(
        id: 'general',
        label: '常规',
        fields: [
          MetadataFieldSpecFrb(
            id: 'title',
            label: '标题',
            kind: MetadataFieldKindFrb.text,
            required_: true,
            options: [],
          ),
          MetadataFieldSpecFrb(
            id: 'published_date',
            label: '发布日期',
            kind: MetadataFieldKindFrb.publishedDate,
            required_: false,
            options: [],
          ),
          MetadataFieldSpecFrb(
            id: 'language_iso',
            label: '语言 (ISO，如 zh-CN)',
            kind: MetadataFieldKindFrb.text,
            required_: false,
            options: [],
          ),
          MetadataFieldSpecFrb(
            id: 'age_rating',
            label: '年龄分级',
            kind: MetadataFieldKindFrb.ageRating,
            required_: false,
            options: [],
          ),
          MetadataFieldSpecFrb(
            id: 'description',
            label: '描述',
            kind: MetadataFieldKindFrb.multilineText,
            required_: false,
            options: [],
          ),
        ],
      ),
      MetadataSectionSpecFrb(
        id: 'series',
        label: '系列',
        fields: [
          MetadataFieldSpecFrb(
            id: 'series',
            label: '系列',
            kind: MetadataFieldKindFrb.text,
            required_: false,
            options: [],
          ),
          MetadataFieldSpecFrb(
            id: 'number',
            label: '期号',
            kind: MetadataFieldKindFrb.text,
            required_: false,
            options: [],
          ),
          MetadataFieldSpecFrb(
            id: 'series_count',
            label: '系列总期数',
            kind: MetadataFieldKindFrb.text,
            required_: false,
            options: [],
          ),
        ],
      ),
      MetadataSectionSpecFrb(
        id: 'creative',
        label: '创作',
        fields: [
          MetadataFieldSpecFrb(
            id: 'author',
            label: '作者',
            kind: MetadataFieldKindFrb.text,
            required_: false,
            options: [],
          ),
          MetadataFieldSpecFrb(
            id: 'tags',
            label: '标签（逗号分隔）',
            kind: MetadataFieldKindFrb.text,
            required_: false,
            options: [],
          ),
          MetadataFieldSpecFrb(
            id: 'characters',
            label: '登场人物',
            kind: MetadataFieldKindFrb.text,
            required_: false,
            options: [],
          ),
        ],
      ),
    ],
    ageRatingPresets: agePresets,
  );
}

String _publishedDatePart(String? publishedDate, int partIndex) {
  final value = publishedDate?.trim();
  if (value == null || value.isEmpty) return '';
  final segments = value.split('-');
  if (partIndex >= segments.length) return '';
  final segment = segments[partIndex];
  if (segment.isEmpty) return '';
  return int.tryParse(segment)?.toString() ?? segment;
}

String? _mergePublishedDateFromFormValues(
  Map<String, String> valuesByFieldId,
) {
  final year = valuesByFieldId['published_date_year']?.trim() ?? '';
  final month = valuesByFieldId['published_date_month']?.trim() ?? '';
  final day = valuesByFieldId['published_date_day']?.trim() ?? '';

  if (year.isEmpty && month.isEmpty && day.isEmpty) {
    return null;
  }
  if (year.isEmpty || (day.isNotEmpty && month.isEmpty)) {
    throw ArgumentError('invalid published_date');
  }

  if (month.isEmpty) {
    return year;
  }
  final monthValue = int.parse(month);
  final normalizedMonth = monthValue.toString().padLeft(2, '0');
  if (day.isEmpty) {
    return '$year-$normalizedMonth';
  }
  final dayValue = int.parse(day);
  final normalizedDay = dayValue.toString().padLeft(2, '0');
  return '$year-$normalizedMonth-$normalizedDay';
}

String mockMetadataFieldDisplayValue({
  required Metadata metadata,
  required String fieldId,
}) {
  return switch (fieldId) {
    'title' => metadata.title,
    'series' => metadata.series ?? '',
    'number' => metadata.number ?? '',
    'series_count' => metadata.seriesCount ?? '',
    'published_date_year' => _publishedDatePart(metadata.publishedDate, 0),
    'published_date_month' => _publishedDatePart(metadata.publishedDate, 1),
    'published_date_day' => _publishedDatePart(metadata.publishedDate, 2),
    'language_iso' => metadata.languageIso ?? '',
    'author' => metadata.author ?? '',
    'tags' => metadata.tags ?? '',
    'characters' => metadata.characters ?? '',
    'age_rating' => metadata.ageRating ?? '',
    'description' => metadata.description ?? '',
    'cover_page_index' => metadata.coverPageIndex.toString(),
    'page_count' => metadata.pageCount.toString(),
    _ => '',
  };
}

Metadata mockMergeMetadataFromForm({
  required Metadata base,
  required List<MetadataFieldValueFrb> fieldValues,
  required int pageCount,
}) {
  final valuesByFieldId = {
    for (final entry in fieldValues) entry.fieldId: entry.value,
  };

  var title = base.title;
  String? number = base.number;
  String? publishedDate = base.publishedDate;

  if (valuesByFieldId.containsKey('title')) {
    final trimmed = valuesByFieldId['title']!.trim();
    if (trimmed.isNotEmpty) {
      title = trimmed;
    }
  }
  if (valuesByFieldId.containsKey('number')) {
    final trimmed = valuesByFieldId['number']!.trim();
    number = trimmed.isEmpty ? null : trimmed;
  }
  if (valuesByFieldId.containsKey('published_date_year')) {
    publishedDate = _mergePublishedDateFromFormValues(valuesByFieldId);
  }

  return Metadata(
    title: title,
    series: base.series,
    number: number,
    seriesCount: base.seriesCount,
    publishedDate: publishedDate,
    languageIso: base.languageIso,
    author: base.author,
    tags: base.tags,
    characters: base.characters,
    ageRating: base.ageRating,
    description: base.description,
    coverPageIndex: base.coverPageIndex,
    pageCount: pageCount,
  );
}
