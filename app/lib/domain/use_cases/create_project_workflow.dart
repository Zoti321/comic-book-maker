import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/models/create_project_command.dart';
import 'package:comic_book_maker/domain/models/create_project_draft.dart';
import 'package:comic_book_maker/domain/use_cases/archive_import_runner.dart';

export 'package:comic_book_maker/domain/models/create_project_command.dart'
    show CreateProjectCommand, CreateProjectValidationException;

/// [Create Project](CONTEXT.md) 用例：单次事务（创建 + Import + ProjectSettings + 可选标题）。
class CreateProjectWorkflow {
  CreateProjectWorkflow({CoreGateway? gateway})
      : _gateway = gateway ?? const FrbCoreGateway();

  final CoreGateway _gateway;

  /// 执行已校验的 [CreateProjectCommand]；返回新建 [ProjectSummary]。
  ProjectSummary execute(CreateProjectCommand command) {
    return _gateway.createProjectWithImport(_toGatewayRequest(command));
  }

  /// 从向导 [CreateProjectDraft] 构建命令并执行。
  ProjectSummary createFromDraft(CreateProjectDraft draft) {
    return execute(draft.toCommand());
  }

  CreateProjectWithImportRequest _toGatewayRequest(CreateProjectCommand command) {
    final import = switch (command.importSource) {
      CreateProjectImageImport(:final sourcePaths) =>
        CreateProjectFromImages(sourcePaths),
      CreateProjectArchiveImport(:final format, :final sourcePath) =>
        CreateProjectFromArchive(
          format: _archiveFormatKind(format),
          sourcePath: sourcePath,
        ),
    };
    return CreateProjectWithImportRequest(
      title: command.title,
      import: import,
      settingsUpdate: command.settingsUpdate,
    );
  }

  static ArchiveFormatKind _archiveFormatKind(ImportArchiveFormat format) =>
      ArchiveImportRunner.archiveFormatKind(format);
}
