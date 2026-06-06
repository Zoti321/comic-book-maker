import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/models/create_project_import_source.dart';

/// [Create Project](CONTEXT.md) 事务命令：向导校验通过后的一次性持久化意图。
class CreateProjectCommand {
  const CreateProjectCommand({
    this.title,
    required this.importSource,
    required this.settingsUpdate,
  });

  final String? title;
  final CreateProjectImportSource importSource;
  final ProjectSettingsUpdate settingsUpdate;
}

/// 向导状态无法转为有效命令时抛出。
class CreateProjectValidationException implements Exception {
  CreateProjectValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
