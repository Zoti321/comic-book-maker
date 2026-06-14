import 'package:comic_book_maker/data/repositories/core_gateway.dart';

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

  final ArchiveFormatFrb format;
  final String sourcePath;
}
