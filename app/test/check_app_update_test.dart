import 'package:comic_book_maker/data/repositories/app_update_repository.dart';
import 'package:comic_book_maker/domain/models/app_update_release.dart';
import 'package:comic_book_maker/domain/use_cases/check_app_update.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAppUpdateRepository implements AppUpdateRepository {
  _FakeAppUpdateRepository(this._release);

  final AppUpdateRelease _release;

  @override
  Future<AppUpdateRelease> fetchLatestRelease() async => _release;

  @override
  Future<String> downloadReleaseAsset(
    AppUpdateRelease release, {
    required String directory,
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  }) {
    throw UnimplementedError();
  }
}

const _sampleRelease = AppUpdateRelease(
  version: '2.0.0',
  tagName: 'v2.0.0',
  releaseNotes: '新功能',
  releasePageUrl:
      'https://github.com/Zoti321/comic-book-maker/releases/tag/v2.0.0',
  downloadUrl: 'https://example.com/win.exe',
);

void main() {
  test('returns up to date when remote is not newer', () async {
    final checker = CheckAppUpdate(
      repository: _FakeAppUpdateRepository(_sampleRelease),
    );

    final result = await checker.call(currentVersion: '2.0.0');

    expect(result, isA<AppUpdateUpToDate>());
  });

  test('returns available when remote is newer', () async {
    final checker = CheckAppUpdate(
      repository: _FakeAppUpdateRepository(_sampleRelease),
    );

    final result = await checker.call(currentVersion: '1.0.0');

    expect(result, isA<AppUpdateAvailable>());
    final available = result as AppUpdateAvailable;
    expect(available.release.version, '2.0.0');
  });
}
