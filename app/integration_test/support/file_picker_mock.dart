import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// 集成测试用 [FilePicker.platform] 替身，返回固定本地路径。
class IntegrationTestFilePicker extends FilePicker {
  IntegrationTestFilePicker(this.pickedFilePath);

  final String pickedFilePath;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    @Deprecated(
      'allowCompression is deprecated and has no effect. Use compressionQuality instead.',
    )
    bool allowCompression = false,
    int compressionQuality = 0,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    final file = File(pickedFilePath);
    return FilePickerResult([
      PlatformFile(
        path: pickedFilePath,
        name: p.basename(pickedFilePath),
        size: file.lengthSync(),
      ),
    ]);
  }

  @override
  Future<String?> getDirectoryPath({
    String? dialogTitle,
    bool lockParentWindow = false,
    String? initialDirectory,
  }) async =>
      null;

  @override
  Future<bool?> clearTemporaryFiles() async => true;

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async =>
      null;
}

FilePicker? _restoredFilePickerPlatform;

void installFilePickerMock(String pickedFilePath) {
  _restoredFilePickerPlatform = FilePicker.platform;
  FilePicker.platform = IntegrationTestFilePicker(pickedFilePath);
  addTearDown(() {
    if (_restoredFilePickerPlatform != null) {
      FilePicker.platform = _restoredFilePickerPlatform!;
      _restoredFilePickerPlatform = null;
    }
  });
}
