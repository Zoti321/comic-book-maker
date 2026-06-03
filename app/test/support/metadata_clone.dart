import 'package:comic_book_maker/src/rust/api/metadata.dart';

/// 测试专用：在 mock 中克隆 `Metadata` 并覆盖少量字段（生产代码请用 Core patch API）。
Metadata cloneMetadata(
  Metadata source, {
  String? blackAndWhite,
  String? manga,
  int? coverPageIndex,
  int? pageCount,
}) {
  return Metadata(
    title: source.title,
    series: source.series,
    issueNumber: source.issueNumber,
    seriesCount: source.seriesCount,
    volume: source.volume,
    alternateSeries: source.alternateSeries,
    alternateNumber: source.alternateNumber,
    alternateCount: source.alternateCount,
    summary: source.summary,
    notes: source.notes,
    year: source.year,
    month: source.month,
    day: source.day,
    writer: source.writer,
    penciller: source.penciller,
    inker: source.inker,
    colorist: source.colorist,
    letterer: source.letterer,
    coverArtist: source.coverArtist,
    editor: source.editor,
    translator: source.translator,
    publisher: source.publisher,
    imprint: source.imprint,
    genre: source.genre,
    tags: source.tags,
    web: source.web,
    languageIso: source.languageIso,
    format: source.format,
    blackAndWhite: blackAndWhite ?? source.blackAndWhite,
    manga: manga ?? source.manga,
    characters: source.characters,
    teams: source.teams,
    locations: source.locations,
    mainCharacterOrTeam: source.mainCharacterOrTeam,
    scanInformation: source.scanInformation,
    storyArc: source.storyArc,
    storyArcNumber: source.storyArcNumber,
    seriesGroup: source.seriesGroup,
    ageRating: source.ageRating,
    communityRating: source.communityRating,
    review: source.review,
    gtin: source.gtin,
    coverPageIndex: coverPageIndex ?? source.coverPageIndex,
    pageCount: pageCount ?? source.pageCount,
  );
}

Metadata mockMetadataWithPageCount({
  required Metadata metadata,
  required int pageCount,
}) =>
    cloneMetadata(metadata, pageCount: pageCount);

Metadata mockMetadataWithCoverPageIndex({
  required Metadata metadata,
  required int coverPageIndex,
}) =>
    cloneMetadata(metadata, coverPageIndex: coverPageIndex);

Metadata mockMetadataWithDropdownField({
  required Metadata metadata,
  required String fieldId,
  String? value,
}) {
  final trimmed = value?.trim();
  final next = trimmed == null || trimmed.isEmpty ? null : trimmed;
  return switch (fieldId) {
    'black_and_white' => cloneMetadata(metadata, blackAndWhite: next),
    'manga' => cloneMetadata(metadata, manga: next),
    _ => metadata,
  };
}
