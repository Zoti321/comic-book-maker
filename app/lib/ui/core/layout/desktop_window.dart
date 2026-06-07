import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

/// 抽象 [window_manager] 调用，便于单测注入 fake，不依赖真机 DWM。
abstract class DesktopWindowManagerClient {
  Future<void> ensureInitialized();
  Future<void> setMinimumSize(Size size);
  Future<void> setTitleBarStyle(TitleBarStyle style);
}

class _WindowManagerClient implements DesktopWindowManagerClient {
  const _WindowManagerClient();

  @override
  Future<void> ensureInitialized() => windowManager.ensureInitialized();

  @override
  Future<void> setMinimumSize(Size size) =>
      windowManager.setMinimumSize(size);

  @override
  Future<void> setTitleBarStyle(TitleBarStyle style) =>
      windowManager.setTitleBarStyle(style);
}

@visibleForTesting
bool isDesktopTargetPlatform(TargetPlatform platform) {
  return switch (platform) {
    TargetPlatform.windows || TargetPlatform.macOS || TargetPlatform.linux =>
      true,
    _ => false,
  };
}

@visibleForTesting
void resetDesktopWindowConfigForTesting() {
  desktopWindowConfig = DesktopWindowConfig.disabled;
}

/// 桌面端初始化无边框窗口与最小尺寸；失败时保留系统标题栏。
Future<void> configureDesktopWindow({
  @visibleForTesting DesktopWindowManagerClient? managerOverride,
  @visibleForTesting TargetPlatform? platformOverride,
}) async {
  if (kIsWeb) {
    desktopWindowConfig = DesktopWindowConfig.disabled;
    return;
  }

  final platform = platformOverride ?? defaultTargetPlatform;
  if (!isDesktopTargetPlatform(platform)) {
    desktopWindowConfig = DesktopWindowConfig.disabled;
    return;
  }

  final manager = managerOverride ?? const _WindowManagerClient();

  try {
    await manager.ensureInitialized();
    await manager.setMinimumSize(appDesktopMinWindowSize);
    await manager.setTitleBarStyle(TitleBarStyle.hidden);
    desktopWindowConfig = const DesktopWindowConfig(chromeEnabled: true);
  } on Object {
    desktopWindowConfig = DesktopWindowConfig.disabled;
  }
}
