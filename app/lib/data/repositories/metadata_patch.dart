import 'package:comic_book_maker/src/rust/api/metadata.dart';

/// 仅更新 [Metadata.title]，其余字段原样保留。
Metadata metadataWithTitle(Metadata source, String title) {
  return Metadata(
    title: title,
    series: source.series,
    number: source.number,
    seriesCount: source.seriesCount,
    publishedDate: source.publishedDate,
    languageIso: source.languageIso,
    author: source.author,
    tags: source.tags,
    characters: source.characters,
    ageRating: source.ageRating,
    description: source.description,
    coverPageIndex: source.coverPageIndex,
    pageCount: source.pageCount,
  );
}
