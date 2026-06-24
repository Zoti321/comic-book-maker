import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

class _MobileSaveFilePickerStub extends FilePicker {
  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    if (bytes == null) {
      throw ArgumentError(
        'Bytes are required on Android & iOS when saving a file.',
      );
    }
    return '/mock/saved/$fileName';
  }
}

void main() {
  test('mobile saveFile contract rejects missing bytes', () async {
    final picker = _MobileSaveFilePickerStub();
    await expectLater(
      picker.saveFile(fileName: 'demo.cbz'),
      throwsArgumentError,
    );
  });

  test('mobile saveFile contract accepts bytes', () async {
    final picker = _MobileSaveFilePickerStub();
    final path = await picker.saveFile(
      fileName: 'demo.cbz',
      bytes: Uint8List.fromList([0x50, 0x4b]),
    );
    expect(path, '/mock/saved/demo.cbz');
  });
}
