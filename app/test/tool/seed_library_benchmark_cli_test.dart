import 'dart:io';

import '../../tool/seed_library_benchmark.dart';
import 'package:flutter_test/flutter_test.dart';

/// 经 `flutter test` + `--dart-define` 驱动，等价于 CLI seed。
///
/// 通常通过 `scripts/seed-library-benchmark.ps1` 调用，勿直接运行本文件。
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seed library profile benchmark CLI', () async {
    const count = int.fromEnvironment('SEED_COUNT', defaultValue: 50);
    const appDataDir = String.fromEnvironment('SEED_APP_DATA_DIR');
    const clean = bool.fromEnvironment('SEED_CLEAN');
    const titlePrefix = String.fromEnvironment(
      'SEED_TITLE_PREFIX',
      defaultValue: 'Profile 基准',
    );

    await ensureSeedRustReady();

    final result = await seedLibraryBenchmark(
      SeedLibraryBenchmarkOptions(
        appDataDir: Directory(
          appDataDir.isEmpty ? defaultLibraryProfileBenchDir() : appDataDir,
        ),
        count: count,
        clean: clean,
        titlePrefix: titlePrefix,
      ),
    );

    // ignore: avoid_print
    print(
      'Seeded ${result.projectCount} projects '
      '(${result.coverThumbnailCount} with Cover Thumbnail)',
    );
    // ignore: avoid_print
    print('App data: ${result.appDataDir.path}');
  });
}
