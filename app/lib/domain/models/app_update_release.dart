/// GitHub Release 解析结果，供检查更新与下载流程使用。
class AppUpdateRelease {
  const AppUpdateRelease({
    required this.version,
    required this.tagName,
    required this.releaseNotes,
    required this.releasePageUrl,
    required this.downloadUrl,
  });

  /// 不含 `v` 前缀的 semver，例如 `1.2.0`。
  final String version;

  /// 原始 tag，例如 `v1.2.0`。
  final String tagName;

  final String releaseNotes;
  final String releasePageUrl;
  final String downloadUrl;
}
