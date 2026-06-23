import 'package:flutter/foundation.dart';

TargetPlatform? appUpdatePlatformOverride;

/// 桌面端（Windows / macOS / Linux）支持应用更新偏好与手动检查；移动端仅 UI 占位。
bool isAppUpdateDesktopPlatform() {
  if (kIsWeb) {
    return false;
  }

  final platform = appUpdatePlatformOverride ?? defaultTargetPlatform;
  return switch (platform) {
    TargetPlatform.windows || TargetPlatform.macOS || TargetPlatform.linux =>
      true,
    _ => false,
  };
}

@visibleForTesting
void resetAppUpdatePlatformOverride() {
  appUpdatePlatformOverride = null;
}
