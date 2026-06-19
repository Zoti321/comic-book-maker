import 'package:comic_book_maker/comic_book_maker_app.dart';
import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/src/rust/frb_generated.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';

bool _rustLibInitialized = false;

/// 幂等加载 Core 动态库。
Future<void> ensureRustLibInitialized() async {
  if (_rustLibInitialized) return;
  await RustLib.init();
  _rustLibInitialized = true;
}

/// 应用启动入口；集成测试可注入 [appDataDir] 并跳过桌面窗口初始化。
Future<void> bootstrapComicBookMaker({
  String? appDataDir,
  bool skipDesktopWindowSetup = false,
}) async {
  WidgetsFlutterBinding.ensureInitialized();
  if (skipDesktopWindowSetup) {
    desktopWindowConfig = DesktopWindowConfig.disabled;
  } else {
    await configureDesktopWindow();
  }
  await ensureRustLibInitialized();

  final dir = appDataDir ?? (await getApplicationSupportDirectory()).path;
  initLibrary(appDataDir: dir);

  runApp(const ProviderScope(child: ComicBookMakerApp()));
}
