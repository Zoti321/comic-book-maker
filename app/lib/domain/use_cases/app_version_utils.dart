import 'package:comic_book_maker/ui/features/settings/app_update_platform.dart';
import 'package:flutter/foundation.dart';

enum AppUpdateTargetPlatform {
  windows,
  macos,
  linux,
  android,
}

/// 当前应用内更新目标平台；不支持的平台调用将抛出 [StateError]。
AppUpdateTargetPlatform currentAppUpdateTargetPlatform() {
  if (kIsWeb) {
    throw StateError('Web 平台不支持应用内更新');
  }

  final platform = appUpdatePlatformOverride ?? defaultTargetPlatform;
  return switch (platform) {
    TargetPlatform.windows => AppUpdateTargetPlatform.windows,
    TargetPlatform.macOS => AppUpdateTargetPlatform.macos,
    TargetPlatform.linux => AppUpdateTargetPlatform.linux,
    TargetPlatform.android => AppUpdateTargetPlatform.android,
    _ => throw StateError('当前平台不支持应用内更新：$platform'),
  };
}

String assetSuffixForPlatform(AppUpdateTargetPlatform platform) {
  return switch (platform) {
    AppUpdateTargetPlatform.windows => 'windows-x64-setup.exe',
    AppUpdateTargetPlatform.macos => 'macos-arm64.zip',
    AppUpdateTargetPlatform.linux => 'linux-x64.tar.gz',
    AppUpdateTargetPlatform.android => 'android-arm64.apk',
  };
}

/// 从 GitHub Release `assets` JSON 列表中选取当前平台的安装包 URL。
String? selectAssetDownloadUrl(
  List<dynamic> assets,
  AppUpdateTargetPlatform platform,
) {
  final suffix = assetSuffixForPlatform(platform);
  for (final asset in assets) {
    if (asset is! Map) continue;
    final name = asset['name'];
    final url = asset['browser_download_url'];
    if (name is String &&
        url is String &&
        name.endsWith(suffix)) {
      return url;
    }
  }
  return null;
}

List<int> parseVersionParts(String version) {
  final normalized = version.trim().replaceFirst(RegExp(r'^v'), '');
  final core = normalized.split('+').first;
  final segments = core.split('.');
  if (segments.length < 3) {
    throw FormatException('无效的版本号：$version');
  }

  return [
    for (final segment in segments.take(3))
      int.parse(segment, radix: 10),
  ];
}

/// `remote` 是否严格新于 `local`（仅比较 major.minor.patch）。
bool isVersionNewer(String remote, String local) {
  final remoteParts = parseVersionParts(remote);
  final localParts = parseVersionParts(local);

  for (var index = 0; index < 3; index++) {
    final difference = remoteParts[index] - localParts[index];
    if (difference > 0) return true;
    if (difference < 0) return false;
  }
  return false;
}

String normalizeReleaseTagName(String tagName) {
  final trimmed = tagName.trim();
  return trimmed.startsWith('v') ? trimmed : 'v$trimmed';
}

String versionFromTagName(String tagName) {
  return tagName.trim().replaceFirst(RegExp(r'^v'), '');
}

String fileNameFromDownloadUrl(String downloadUrl) {
  final segments = Uri.parse(downloadUrl).pathSegments;
  if (segments.isEmpty) {
    throw FormatException('无法从 URL 解析文件名：$downloadUrl');
  }
  return segments.last;
}
