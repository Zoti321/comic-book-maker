import 'package:flutter/foundation.dart';

TargetPlatform? appUpdatePlatformOverride;

/// 支持应用内更新检查与安装的平台（桌面 + Android）。
bool isAppUpdateSupportedPlatform() {
  if (kIsWeb) {
    return false;
  }

  final platform = appUpdatePlatformOverride ?? defaultTargetPlatform;
  return switch (platform) {
    TargetPlatform.windows ||
    TargetPlatform.macOS ||
    TargetPlatform.linux ||
    TargetPlatform.android =>
      true,
    _ => false,
  };
}

@Deprecated('Use isAppUpdateSupportedPlatform')
bool isAppUpdateDesktopPlatform() => isAppUpdateSupportedPlatform();

@visibleForTesting
void resetAppUpdatePlatformOverride() {
  appUpdatePlatformOverride = null;
}
