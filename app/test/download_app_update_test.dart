import 'dart:io';
import 'dart:typed_data';

import 'package:comic_book_maker/data/repositories/app_update_repository.dart';
import 'package:comic_book_maker/domain/models/app_update_release.dart';
import 'package:comic_book_maker/domain/use_cases/app_version_utils.dart';
import 'package:comic_book_maker/domain/use_cases/download_app_update.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tempDir;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('cbm-app-update-download-');
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('downloads release asset to destination directory', () async {
    final dio = Dio();
    dio.httpClientAdapter = _FakeDownloadAdapter(
      content: List<int>.filled(128, 7),
    );

    final repository = GitHubAppUpdateRepository(
      apiDio: dio,
      downloadDio: dio,
      platform: () => AppUpdateTargetPlatform.windows,
    );

    const release = AppUpdateRelease(
      version: '2.0.0',
      tagName: 'v2.0.0',
      releaseNotes: '',
      releasePageUrl: 'https://example.com/release',
      downloadUrl: 'https://example.com/comic-book-maker-2.0.0-windows-x64-setup.exe',
    );

    var lastReceived = 0;
    int? lastTotal;

    final downloader = DownloadAppUpdate(
      repository: repository,
      tempDirectory: () async => tempDir,
    );

    final filePath = await downloader.call(
      release,
      onProgress: (receivedBytes, totalBytes) {
        lastReceived = receivedBytes;
        lastTotal = totalBytes;
      },
    );

    final file = File(filePath);
    expect(await file.exists(), isTrue);
    expect(file.lengthSync(), 128);
    expect(lastReceived, 128);
    expect(lastTotal, 128);
    expect(
      filePath,
      endsWith('comic-book-maker-2.0.0-windows-x64-setup.exe'),
    );
  });
}

class _FakeDownloadAdapter implements HttpClientAdapter {
  _FakeDownloadAdapter({required this.content});

  final List<int> content;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    return ResponseBody.fromBytes(
      content,
      200,
      headers: {
        Headers.contentLengthHeader: [content.length.toString()],
      },
    );
  }
}
