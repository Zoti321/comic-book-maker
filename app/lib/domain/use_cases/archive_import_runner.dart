import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/domain/models/append_archive_format.dart';
import 'package:comic_book_maker/domain/models/import_archive_format.dart';
import 'package:file_picker/file_picker.dart';

export 'package:comic_book_maker/domain/models/append_archive_format.dart'
    show AppendArchiveFormat;
export 'package:comic_book_maker/domain/models/import_archive_format.dart'
    show ImportArchiveFormat;

/// 归档导入：FilePicker + 按格式分发 [CoreGateway]（新建项目 / 追加页面共用）。
class ArchiveImportRunner {
  ArchiveImportRunner({CoreGateway? gateway})
      : _gateway = gateway ?? const FrbCoreGateway();

  final CoreGateway _gateway;

  static String displayName(ImportArchiveFormat format) {
    return switch (format) {
      ImportArchiveFormat.cbr => 'CBR',
      ImportArchiveFormat.cbz => 'CBZ',
      ImportArchiveFormat.cb7 => 'CB7',
      ImportArchiveFormat.epub => 'EPUB',
    };
  }

  static List<String> allowedExtensions(ImportArchiveFormat format) {
    return switch (format) {
      ImportArchiveFormat.cbr => const ['cbr'],
      ImportArchiveFormat.cbz => const ['cbz'],
      ImportArchiveFormat.cb7 => const ['cb7', '7z'],
      ImportArchiveFormat.epub => const ['epub'],
    };
  }

  /// 漫画压缩包文件选择器允许的扩展名（含容器扩展名）。
  static const comicArchiveExtensions = [
    'cbz',
    'zip',
    'cbr',
    'rar',
    'cb7',
    '7z',
  ];

  /// 按路径扩展名推断 [ImportArchiveFormat]；无法识别时返回 `null`。
  static ImportArchiveFormat? inferFormatFromPath(String path) {
    final dot = path.lastIndexOf('.');
    if (dot < 0 || dot == path.length - 1) return null;

    return switch (path.substring(dot + 1).toLowerCase()) {
      'cbz' || 'zip' => ImportArchiveFormat.cbz,
      'cbr' || 'rar' => ImportArchiveFormat.cbr,
      'cb7' || '7z' => ImportArchiveFormat.cb7,
      _ => null,
    };
  }

  /// 选择漫画压缩包并推断 CBZ/CBR/CB7 格式；取消返回 `null`。
  Future<({ImportArchiveFormat format, String path})?> pickComicArchivePath() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: comicArchiveExtensions,
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final sourcePath = result.files.single.path;
    if (sourcePath == null || sourcePath.isEmpty) {
      throw StateError('无法读取所选漫画压缩包文件路径');
    }

    final format = inferFormatFromPath(sourcePath);
    if (format == null) {
      throw StateError('不支持的漫画压缩包格式：$sourcePath');
    }

    return (format: format, path: sourcePath);
  }

  static ImportArchiveFormat fromAppendFormat(AppendArchiveFormat format) {
    return switch (format) {
      AppendArchiveFormat.cbz => ImportArchiveFormat.cbz,
      AppendArchiveFormat.cbr => ImportArchiveFormat.cbr,
      AppendArchiveFormat.cb7 => ImportArchiveFormat.cb7,
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

  static ArchiveFormatKind archiveFormatKind(ImportArchiveFormat format) {
    return switch (format) {
      ImportArchiveFormat.cbz => ArchiveFormatKind.cbz,
      ImportArchiveFormat.cbr => ArchiveFormatKind.cbr,
      ImportArchiveFormat.cb7 => ArchiveFormatKind.cb7,
      ImportArchiveFormat.epub => ArchiveFormatKind.epub,
    };
  }

  /// 从归档创建新项目（漫画库导入 / 向导归档源）。
  ImportCbzResult importNewProject({
    required ImportArchiveFormat format,
    required String sourcePath,
  }) {
    return _gateway.importArchive(
      format: archiveFormatKind(format),
      sourcePath: sourcePath,
    );
  }

  /// 向已有项目追加页面。
  AppendImportResult appendToProject({
    required String projectId,
    required ImportArchiveFormat format,
    required String sourcePath,
  }) {
    return _gateway.appendArchive(
      projectId: projectId,
      format: archiveFormatKind(format),
      sourcePath: sourcePath,
    );
  }

  String importBlockingMessage(ImportArchiveFormat format) =>
      '正在导入 ${displayName(format)}…';

  String appendBlockingMessage(ImportArchiveFormat format) =>
      '正在从 ${displayName(format)} 追加页面…';
}
