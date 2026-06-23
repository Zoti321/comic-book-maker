import 'package:comic_book_maker/data/repositories/app_update_repository.dart';
import 'package:comic_book_maker/domain/use_cases/app_version_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isVersionNewer', () {
    test('returns true when remote patch is newer', () {
      expect(isVersionNewer('1.0.1', '1.0.0'), isTrue);
    });

    test('returns true when remote minor is newer', () {
      expect(isVersionNewer('1.2.0', '1.1.9'), isTrue);
    });

    test('returns false when versions are equal', () {
      expect(isVersionNewer('1.0.0', '1.0.0'), isFalse);
      expect(isVersionNewer('v1.0.0', '1.0.0'), isFalse);
    });

    test('returns false when remote is older', () {
      expect(isVersionNewer('1.0.0', '2.0.0'), isFalse);
    });
  });

  group('selectAssetDownloadUrl', () {
    const assets = [
      {
        'name': 'comic-book-maker-2.0.0-windows-x64-setup.exe',
        'browser_download_url': 'https://example.com/win.exe',
      },
      {
        'name': 'comic-book-maker-2.0.0-macos-arm64.zip',
        'browser_download_url': 'https://example.com/mac.zip',
      },
      {
        'name': 'comic-book-maker-2.0.0-linux-x64.tar.gz',
        'browser_download_url': 'https://example.com/linux.tar.gz',
      },
      {
        'name': 'comic-book-maker-2.0.0-android-arm64.apk',
        'browser_download_url': 'https://example.com/android.apk',
      },
    ];

    test('selects windows asset', () {
      expect(
        selectAssetDownloadUrl(assets, AppUpdateTargetPlatform.windows),
        'https://example.com/win.exe',
      );
    });

    test('selects macos asset', () {
      expect(
        selectAssetDownloadUrl(assets, AppUpdateTargetPlatform.macos),
        'https://example.com/mac.zip',
      );
    });

    test('selects linux asset', () {
      expect(
        selectAssetDownloadUrl(assets, AppUpdateTargetPlatform.linux),
        'https://example.com/linux.tar.gz',
      );
    });

    test('selects android asset', () {
      expect(
        selectAssetDownloadUrl(assets, AppUpdateTargetPlatform.android),
        'https://example.com/android.apk',
      );
    });

    test('returns null when asset is missing', () {
      expect(
        selectAssetDownloadUrl(const [], AppUpdateTargetPlatform.windows),
        isNull,
      );
    });
  });

  group('fileNameFromDownloadUrl', () {
    test('extracts file name from release asset url', () {
      expect(
        fileNameFromDownloadUrl(
          'https://example.com/comic-book-maker-2.0.0-windows-x64-setup.exe',
        ),
        'comic-book-maker-2.0.0-windows-x64-setup.exe',
      );
    });
  });

  group('parseLatestReleaseJson', () {
    test('parses tag, notes, publishedAt and platform asset', () {
      final release = GitHubAppUpdateRepository.parseLatestReleaseJson(
        const {
          'tag_name': 'v2.1.0',
          'html_url': 'https://github.com/Zoti321/comic-book-maker/releases/tag/v2.1.0',
          'body': '- 修复导出问题',
          'published_at': '2026-06-18T10:15:30Z',
          'assets': [
            {
              'name': 'comic-book-maker-2.1.0-windows-x64-setup.exe',
              'browser_download_url': 'https://example.com/win.exe',
            },
          ],
        },
        platform: AppUpdateTargetPlatform.windows,
      );

      expect(release.version, '2.1.0');
      expect(release.tagName, 'v2.1.0');
      expect(release.releaseNotes, '- 修复导出问题');
      expect(release.publishedAt, DateTime.utc(2026, 6, 18, 10, 15, 30));
      expect(release.downloadUrl, 'https://example.com/win.exe');
      expect(
        release.releasePageUrl,
        'https://github.com/Zoti321/comic-book-maker/releases/tag/v2.1.0',
      );
    });
  });
}
