import 'dart:io';

import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/src/rust/frb_generated.dart';
import 'package:flutter_test/flutter_test.dart';

bool _rustLibInitialized = false;

/// 加载 Core 动态库（集成测试用）。
Future<void> initRustLib() async {
  if (_rustLibInitialized) return;
  await RustLib.init();
  _rustLibInitialized = true;
}

/// 在独立临时目录安装 Library Database（每个测试前后应 reset）。
Future<Directory> installRustLibraryInTemp() async {
  await initRustLib();
  resetLibraryForTesting();
  final dir = await Directory.systemTemp.createTemp('cbm-frb-integration-');
  initLibrary(appDataDir: dir.path);
  return dir;
}

void rustIntegrationTestSetUp({
  required void Function(Directory tempDir) onReady,
}) {
  late Directory tempDir;

  setUp(() async {
    tempDir = await installRustLibraryInTemp();
    onReady(tempDir);
  });

  tearDown(() async {
    resetLibraryForTesting();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });
}

void rustIntegrationTestSetUpAll() {
  setUpAll(() async {
    await initRustLib();
  });
}

/// 兼容 #7 export 测试：仅初始化 RustLib，Library 由调用方 install。
Future<void> initRustForExportTests() => initRustLib();

void exportRustTestSetUpAll() {
  rustIntegrationTestSetUpAll();
}
