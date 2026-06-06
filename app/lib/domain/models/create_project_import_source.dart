import 'package:comic_book_maker/domain/models/import_archive_format.dart';

/// [Create Project](CONTEXT.md) 向导已选定的 Import 来源。
sealed class CreateProjectImportSource {
  const CreateProjectImportSource();
}

final class CreateProjectImageImport extends CreateProjectImportSource {
  const CreateProjectImageImport(this.sourcePaths);

  final List<String> sourcePaths;
}

final class CreateProjectArchiveImport extends CreateProjectImportSource {
  const CreateProjectArchiveImport({
    required this.format,
    required this.sourcePath,
  });

  final ImportArchiveFormat format;
  final String sourcePath;
}
