import 'package:comic_book_maker/domain/models/app_update_release.dart';
import 'package:comic_book_maker/domain/use_cases/app_release_notes_format.dart';
import 'package:comic_book_maker/domain/use_cases/app_version_utils.dart';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;

abstract class AppUpdateRepository {
  Future<AppUpdateRelease> fetchLatestRelease();

  Future<String> downloadReleaseAsset(
    AppUpdateRelease release, {
    required String directory,
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  });
}

class GitHubAppUpdateRepository implements AppUpdateRepository {
  GitHubAppUpdateRepository({
    required Dio apiDio,
    Dio? downloadDio,
    this.owner = 'Zoti321',
    this.repo = 'comic-book-maker',
    AppUpdateTargetPlatform Function()? platform,
  })  : _apiDio = apiDio,
        _downloadDio = downloadDio ?? apiDio,
        _platform = platform ?? currentAppUpdateTargetPlatform;

  final Dio _apiDio;
  final Dio _downloadDio;
  final String owner;
  final String repo;
  final AppUpdateTargetPlatform Function() _platform;

  @override
  Future<AppUpdateRelease> fetchLatestRelease() async {
    final response = await _apiDio.get<Map<String, dynamic>>(
      '/repos/$owner/$repo/releases/latest',
    );
    final data = response.data;
    if (data == null) {
      throw const AppUpdateRepositoryException('GitHub API 返回空响应');
    }
    return parseLatestReleaseJson(data, platform: _platform());
  }

  @override
  Future<String> downloadReleaseAsset(
    AppUpdateRelease release, {
    required String directory,
    void Function(int receivedBytes, int? totalBytes)? onProgress,
  }) async {
    final fileName = fileNameFromDownloadUrl(release.downloadUrl);
    final destinationPath = p.join(directory, fileName);

    await _downloadDio.download(
      release.downloadUrl,
      destinationPath,
      onReceiveProgress: onProgress,
    );

    return destinationPath;
  }

  static AppUpdateRelease parseLatestReleaseJson(
    Map<String, dynamic> json, {
    required AppUpdateTargetPlatform platform,
  }) {
    final tagName = json['tag_name'];
    if (tagName is! String || tagName.isEmpty) {
      throw const AppUpdateRepositoryException('Release 缺少 tag_name');
    }

    final htmlUrl = json['html_url'];
    if (htmlUrl is! String || htmlUrl.isEmpty) {
      throw const AppUpdateRepositoryException('Release 缺少 html_url');
    }

    final assets = json['assets'];
    if (assets is! List<dynamic>) {
      throw const AppUpdateRepositoryException('Release 缺少 assets');
    }

    final downloadUrl = selectAssetDownloadUrl(assets, platform);
    if (downloadUrl == null) {
      throw AppUpdateRepositoryException(
        '未找到适用于 ${assetSuffixForPlatform(platform)} 的发布资产',
      );
    }

    final body = json['body'];
    final releaseNotes = body is String ? body.trim() : '';
    final publishedAt = parseReleasePublishedAt(json['published_at']);

    final normalizedTag = normalizeReleaseTagName(tagName);
    return AppUpdateRelease(
      version: versionFromTagName(tagName),
      tagName: normalizedTag,
      releaseNotes: releaseNotes,
      releasePageUrl: htmlUrl,
      downloadUrl: downloadUrl,
      publishedAt: publishedAt,
    );
  }
}

class AppUpdateRepositoryException implements Exception {
  const AppUpdateRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
