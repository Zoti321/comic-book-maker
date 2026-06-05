import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:flutter/foundation.dart';
import 'package:window_manager/window_manager.dart';

/// 桌面端设置窗口最小尺寸，防止缩放过窄导致布局溢出。
Future<void> configureDesktopWindow() async {
  if (kIsWeb) return;
  switch (defaultTargetPlatform) {
    case TargetPlatform.windows:
    case TargetPlatform.macOS:
    case TargetPlatform.linux:
      break;
    default:
      return;
  }

  await windowManager.ensureInitialized();
  await windowManager.setMinimumSize(appDesktopMinWindowSize);
}
