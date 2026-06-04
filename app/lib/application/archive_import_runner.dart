import 'package:comic_book_maker/application/core_gateway.dart';
import 'package:comic_book_maker/ui/design_system/append_archive_sheet.dart';
import 'package:comic_book_maker/ui/design_system/import_archive_sheet.dart';
import 'package:file_picker/file_picker.dart';

/// 归档导入：FilePicker + 按格式分发 [CoreGateway]（新建项目 / 追加页面共用）。
class ArchiveImportRunner {
  ArchiveImportRunner({CoreGateway? gateway})
      : _gateway = gateway ?? const FrbCoreGateway();

  final CoreGateway _gateway;

  static String displayName(ImportArchiveFormat format) {
    return switch (format) {
      ImportArchiveFormat.cbr => 'CBR',
      ImportArchiveFormat.cbz => 'CBZ',
      ImportArchiveFormat.epub => 'EPUB',
    };
  }

  static List<String> allowedExtensions(ImportArchiveFormat format) {
    return switch (format) {
      ImportArchiveFormat.cbr => const ['cbr'],
      ImportArchiveFormat.cbz => const ['cbz'],
      ImportArchiveFormat.epub => const ['epub'],
    };
  }

  static ImportArchiveFormat fromAppendFormat(AppendArchiveFormat format) {
    return switch (format) {
      AppendArchiveFormat.cbz => ImportArchiveFormat.cbz,
      AppendArchiveFormat.cbr => ImportArchiveFormat.cbr,
    };
  }

  /// 选择本地归档文件；取消返回 `null`；路径无效时抛出 [StateError]。
  Future<String?> pickSourcePath(ImportArchiveFormat format) async {
    final displayName = ArchiveImportRunner.displayName(format);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions(format),
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final sourcePath = result.files.single.path;
    if (sourcePath == null || sourcePath.isEmpty) {
      throw StateError('无法读取所选 $displayName 文件路径');
    }
    return sourcePath;
  }

  /// 从归档创建新项目（漫画库导入 / 向导归档源）。
  ImportCbzResult importNewProject({
    required ImportArchiveFormat format,
    required String sourcePath,
  }) {
    return switch (format) {
      ImportArchiveFormat.cbz => _gateway.importCbz(sourcePath: sourcePath),
      ImportArchiveFormat.cbr => _gateway.importCbr(sourcePath: sourcePath),
      ImportArchiveFormat.epub => _gateway.importEpub(sourcePath: sourcePath),
    };
  }

  /// 向已有项目追加页面。
  AppendImportResult appendToProject({
    required String projectId,
    required ImportArchiveFormat format,
    required String sourcePath,
  }) {
    return switch (format) {
      ImportArchiveFormat.cbz => _gateway.appendCbz(
          projectId: projectId,
          sourcePath: sourcePath,
        ),
      ImportArchiveFormat.cbr => _gateway.appendCbr(
          projectId: projectId,
          sourcePath: sourcePath,
        ),
      ImportArchiveFormat.epub => _gateway.appendEpub(
          projectId: projectId,
          sourcePath: sourcePath,
        ),
    };
  }

  String importBlockingMessage(ImportArchiveFormat format) =>
      '正在导入 ${displayName(format)}…';

  String appendBlockingMessage(ImportArchiveFormat format) =>
      '正在从 ${displayName(format)} 追加页面…';
}
