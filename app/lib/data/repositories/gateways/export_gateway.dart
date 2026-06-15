import 'package:comic_book_maker/data/repositories/core_gateway_types.dart';

/// [Export](CONTEXT.md) 归档写出。
abstract class ExportGateway {
  Future<void> exportArchive({
    required String projectId,
    required String destinationPath,
    required bool exportComicArchive,
    ComicArchiveContainerFrb? comicArchiveContainer,
    required bool exportPdf,
    required bool deleteProjectAfterExport,
  });
}
