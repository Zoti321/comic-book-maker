import 'dart:io';

import 'package:comic_book_maker/data/repositories/app_update_repository.dart';
import 'package:comic_book_maker/domain/models/app_update_release.dart';
import 'package:path_provider/path_provider.dart';

typedef AppUpdateDownloadProgressCallback = void Function(
  int receivedBytes,
  int? totalBytes,
);

typedef AppUpdateTempDirectory = Future<Directory> Function();

class DownloadAppUpdate {
  DownloadAppUpdate({
    required AppUpdateRepository repository,
    AppUpdateTempDirectory? tempDirectory,
  })  : _repository = repository,
        _tempDirectory = tempDirectory ?? getTemporaryDirectory;

  final AppUpdateRepository _repository;
  final AppUpdateTempDirectory _tempDirectory;

  Future<String> call(
    AppUpdateRelease release, {
    AppUpdateDownloadProgressCallback? onProgress,
  }) async {
    final directory = await _tempDirectory();
    return _repository.downloadReleaseAsset(
      release,
      directory: directory.path,
      onProgress: onProgress,
    );
  }
}
