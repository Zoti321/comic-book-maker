import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart' as simple_api;
import 'package:file_picker/file_picker.dart';

export 'package:comic_book_maker/data/repositories/core_gateway.dart'
    show ArchiveFormatFrb;

/// 归档导入：FilePicker + [ArchiveGateway] 统一 Archive Format 入口。
class ArchiveImportRunner {
  ArchiveImportRunner({ArchiveGateway? gateway})
      : _gateway = gateway ?? const FrbCoreGateway();

  final ArchiveGateway _gateway;

  static String displayName(ArchiveFormatFrb format) =>
      simple_api.archiveFormatDisplayName(format: format);

  static List<String> allowedExtensions(ArchiveFormatFrb format) =>
      simple_api.archiveFormatAllowedExtensions(format: format);

  /// 漫画压缩包文件选择器允许的扩展名（含容器扩展名）。
  static List<String> get comicArchiveExtensions =>
      simple_api.comicArchivePickerExtensions();

  /// 按路径扩展名推断漫画压缩包格式；无法识别时返回 `null`（不含 EPUB）。
  static ArchiveFormatFrb? inferComicArchiveFormatFromPath(String path) =>
      simple_api.inferComicArchiveFormatFromPath(path: path);

  /// 按路径扩展名推断 [Archive Format]；无法识别时返回 `null`。
  static ArchiveFormatFrb? inferFormatFromPath(String path) =>
      simple_api.inferArchiveFormatFromPath(path: path);

  /// 选择漫画压缩包并推断 CBZ/CBR/CB7 格式；取消返回 `null`。
  Future<({ArchiveFormatFrb format, String path})?> pickComicArchivePath() async {
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

    final format = inferComicArchiveFormatFromPath(sourcePath);
    if (format == null) {
      throw StateError('不支持的漫画压缩包格式：$sourcePath');
    }

    return (format: format, path: sourcePath);
  }

  /// 选择本地归档文件；取消返回 `null`；路径无效时抛出 [StateError]。
  Future<String?> pickSourcePath(ArchiveFormatFrb format) async {
    final label = displayName(format);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: allowedExtensions(format),
      allowMultiple: false,
    );
    if (result == null || result.files.isEmpty) return null;

    final sourcePath = result.files.single.path;
    if (sourcePath == null || sourcePath.isEmpty) {
      throw StateError('无法读取所选 $label 文件路径');
    }
    return sourcePath;
  }

  /// 从归档创建新项目（漫画库导入 / 向导归档源）。
  ImportCbzResult importNewProject({
    required ArchiveFormatFrb format,
    required String sourcePath,
  }) {
    return _gateway.importArchive(format: format, sourcePath: sourcePath);
  }

  /// 向已有项目追加页面。
  AppendImportResult appendToProject({
    required String projectId,
    required ArchiveFormatFrb format,
    required String sourcePath,
  }) {
    return _gateway.appendArchive(
      projectId: projectId,
      format: format,
      sourcePath: sourcePath,
    );
  }

  String importBlockingMessage(ArchiveFormatFrb format) =>
      '正在导入 ${displayName(format)}…';

  String appendBlockingMessage(ArchiveFormatFrb format) =>
      '正在从 ${displayName(format)} 追加页面…';
}
