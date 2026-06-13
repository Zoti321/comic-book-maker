import 'package:comic_book_maker/src/rust/api/metadata.dart';

/// 测试专用：在 mock 中克隆 `Metadata` 并覆盖少量字段（生产代码请用 Core patch API）。
Metadata cloneMetadata(
  Metadata source, {
  String? author,
  String? number,
  int? coverPageIndex,
  int? pageCount,
}) {
  return Metadata(
    title: source.title,
    series: source.series,
    number: number ?? source.number,
    seriesCount: source.seriesCount,
    publishedDate: source.publishedDate,
    languageIso: source.languageIso,
    author: author ?? source.author,
    tags: source.tags,
    characters: source.characters,
    ageRating: source.ageRating,
    description: source.description,
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
  return metadata;
}
