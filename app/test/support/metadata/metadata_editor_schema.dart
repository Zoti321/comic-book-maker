import 'package:comic_book_maker/src/rust/api/metadata.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart';

/// 测试用 schema fixture（与 Core `metadata_schema` 结构对齐，仅覆盖 widget 测试所需字段）。
MetadataEditorSchemaFrb metadataEditorSchemaFixture(ExportFormatFrb exportFormat) {
  const agePresets = ['Adults Only 18+', 'Everyone', 'R18+', 'Unknown'];

  switch (exportFormat) {
    case ExportFormatFrb.comicArchive:
    case ExportFormatFrb.pdf:
      return MetadataEditorSchemaFrb(
        editorTitle: 'ComicInfo',
        editable: true,
        sections: [
          MetadataSectionSpecFrb(
            id: 'basic',
            label: '基本',
            fields: [
              MetadataFieldSpecFrb(
                id: 'title',
                label: '标题',
                kind: MetadataFieldKindFrb.text,
                required_: true,
                options: [],
              ),
              MetadataFieldSpecFrb(
                id: 'volume',
                label: '卷号',
                kind: MetadataFieldKindFrb.text,
                required_: false,
                options: [],
              ),
            ],
          ),
        ],
        ageRatingPresets: agePresets,
      );
    case ExportFormatFrb.epub:
      return MetadataEditorSchemaFrb(
        editorTitle: 'OPF Metadata',
        editable: true,
        sections: [
          MetadataSectionSpecFrb(
            id: 'opf',
            label: 'OPF 元数据',
            fields: [
              MetadataFieldSpecFrb(
                id: 'title',
                label: '标题',
                kind: MetadataFieldKindFrb.text,
                required_: true,
                options: [],
              ),
              MetadataFieldSpecFrb(
                id: 'gtin',
                label: '标识符 (GTIN/ISBN)',
                kind: MetadataFieldKindFrb.text,
                required_: false,
                options: [],
              ),
            ],
          ),
          MetadataSectionSpecFrb(
            id: 'fixed_layout',
            label: '固定版式',
            fields: [
              MetadataFieldSpecFrb(
                id: 'opf_rendition_layout',
                label: 'rendition:layout',
                kind: MetadataFieldKindFrb.readOnly,
                required_: false,
                options: [],
                readOnlyValue: 'pre-paginated',
              ),
            ],
          ),
        ],
        ageRatingPresets: agePresets,
      );
  }
}

String mockMetadataFieldDisplayValue({
  required Metadata metadata,
  required String fieldId,
}) {
  return switch (fieldId) {
    'title' => metadata.title,
    'volume' => metadata.volume ?? '',
    'gtin' => metadata.gtin ?? '',
    'black_and_white' => metadata.blackAndWhite ?? '',
    'manga' => metadata.manga ?? '',
    'cover_page_index' => metadata.coverPageIndex.toString(),
    'opf_rendition_layout' => 'pre-paginated',
    _ => '',
  };
}

Metadata mockMergeMetadataFromForm({
  required Metadata base,
  required List<MetadataFieldValueFrb> fieldValues,
  required int pageCount,
}) {
  var title = base.title;
  String? volume = base.volume;
  for (final entry in fieldValues) {
    if (entry.fieldId == 'title' && entry.value.trim().isNotEmpty) {
      title = entry.value.trim();
    }
    if (entry.fieldId == 'volume') {
      final trimmed = entry.value.trim();
      volume = trimmed.isEmpty ? null : trimmed;
    }
  }
  return Metadata(
    title: title,
    series: base.series,
    issueNumber: base.issueNumber,
    seriesCount: base.seriesCount,
    volume: volume,
    alternateSeries: base.alternateSeries,
    alternateNumber: base.alternateNumber,
    alternateCount: base.alternateCount,
    summary: base.summary,
    notes: base.notes,
    year: base.year,
    month: base.month,
    day: base.day,
    writer: base.writer,
    penciller: base.penciller,
    inker: base.inker,
    colorist: base.colorist,
    letterer: base.letterer,
    coverArtist: base.coverArtist,
    editor: base.editor,
    translator: base.translator,
    publisher: base.publisher,
    imprint: base.imprint,
    genre: base.genre,
    tags: base.tags,
    web: base.web,
    languageIso: base.languageIso,
    format: base.format,
    blackAndWhite: base.blackAndWhite,
    manga: base.manga,
    characters: base.characters,
    teams: base.teams,
    locations: base.locations,
    mainCharacterOrTeam: base.mainCharacterOrTeam,
    scanInformation: base.scanInformation,
    storyArc: base.storyArc,
    storyArcNumber: base.storyArcNumber,
    seriesGroup: base.seriesGroup,
    ageRating: base.ageRating,
    communityRating: base.communityRating,
    review: base.review,
    gtin: base.gtin,
    coverPageIndex: base.coverPageIndex,
    pageCount: pageCount,
  );
}
