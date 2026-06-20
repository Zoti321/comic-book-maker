import 'dart:io';

import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:comic_book_maker/src/rust/frb_generated.dart';
import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as p;

/// 默认 Profile 基准库目录（系统临时目录下固定路径，便于重复 Profile）。
String defaultLibraryProfileBenchDir() {
  return p.join(Directory.systemTemp.path, 'cbm-library-profile-bench');
}

/// `integration_test/fixtures/two_pages.cbz` 绝对路径。
String libraryProfileFixtureCbzPath() {
  final cwd = Directory.current.path;
  final appRoot = p.basename(cwd) == 'app' ? cwd : p.join(cwd, 'app');
  return p.join(appRoot, 'integration_test', 'fixtures', 'two_pages.cbz');
}

void ensureLibraryProfileFixtureCbz() {
  final path = libraryProfileFixtureCbzPath();
  if (!File(path).existsSync()) {
    throw StateError(
      'Missing fixture at $path. Run: dart run tool/generate_integration_fixture.dart',
    );
  }
}

/// Profile 基准 seed 选项。
class SeedLibraryBenchmarkOptions {
  const SeedLibraryBenchmarkOptions({
    required this.appDataDir,
    this.count = 50,
    this.clean = false,
    this.titlePrefix = 'Profile 基准',
  });

  final Directory appDataDir;
  final int count;
  final bool clean;
  final String titlePrefix;
}

/// Profile 基准 seed 结果摘要。
class SeedLibraryBenchmarkResult {
  const SeedLibraryBenchmarkResult({
    required this.appDataDir,
    required this.projectCount,
    required this.coverThumbnailCount,
  });

  final Directory appDataDir;
  final int projectCount;
  final int coverThumbnailCount;
}

/// 在 [options.appDataDir] 批量 Import CBZ 并写入带序号的 Project 标题。
Future<SeedLibraryBenchmarkResult> seedLibraryBenchmark(
  SeedLibraryBenchmarkOptions options,
) async {
  if (options.count < 1) {
    throw ArgumentError.value(options.count, 'count', 'must be >= 1');
  }

  ensureLibraryProfileFixtureCbz();
  final fixturePath = libraryProfileFixtureCbzPath();

  if (options.clean && options.appDataDir.existsSync()) {
    await options.appDataDir.delete(recursive: true);
  } else if (options.appDataDir.existsSync() &&
      File(p.join(options.appDataDir.path, 'library.db')).existsSync()) {
    throw StateError(
      'Library already exists at ${options.appDataDir.path}. '
      'Pass --clean to replace it.',
    );
  }

  options.appDataDir.createSync(recursive: true);

  resetLibraryForTesting();
  initLibrary(appDataDir: options.appDataDir.path);

  for (var index = 1; index <= options.count; index++) {
    final imported = importCbz(sourcePath: fixturePath);
    final label = index.toString().padLeft(
      options.count >= 100 ? 3 : 2,
      '0',
    );
    updateProjectTitle(
      projectId: imported.project.id,
      title: '${options.titlePrefix} $label',
    );
  }

  final projects = listProjects();
  var coverCount = 0;
  for (final project in projects) {
    final coverPath = project.coverThumbnailPath;
    if (coverPath != null &&
        coverPath.isNotEmpty &&
        File(coverPath).existsSync()) {
      coverCount++;
    }
  }

  if (projects.length != options.count) {
    throw StateError(
      'Expected ${options.count} projects, got ${projects.length}',
    );
  }
  if (coverCount != options.count) {
    throw StateError(
      'Expected ${options.count} projects with Cover Thumbnail, got $coverCount',
    );
  }

  return SeedLibraryBenchmarkResult(
    appDataDir: options.appDataDir,
    projectCount: projects.length,
    coverThumbnailCount: coverCount,
  );
}

/// 解析 CLI 参数；非法参数时抛出 [FormatException]。
SeedLibraryBenchmarkOptions parseSeedLibraryBenchmarkArgs(List<String> args) {
  var count = 50;
  String? appDataDir;
  var clean = false;
  var titlePrefix = 'Profile 基准';

  for (var index = 0; index < args.length; index++) {
    final arg = args[index];
    switch (arg) {
      case '--help':
      case '-h':
        throw _SeedCliHelpRequest();
      case '--count':
        index++;
        if (index >= args.length) {
          throw FormatException('Missing value for --count');
        }
        count = int.tryParse(args[index]) ?? -1;
        if (count < 1) {
          throw FormatException('Invalid --count: ${args[index]}');
        }
      case '--app-data-dir':
        index++;
        if (index >= args.length) {
          throw FormatException('Missing value for --app-data-dir');
        }
        appDataDir = args[index];
      case '--clean':
        clean = true;
      case '--title-prefix':
        index++;
        if (index >= args.length) {
          throw FormatException('Missing value for --title-prefix');
        }
        titlePrefix = args[index];
        if (titlePrefix.trim().isEmpty) {
          throw FormatException('--title-prefix must not be empty');
        }
      default:
        throw FormatException('Unknown argument: $arg');
    }
  }

  return SeedLibraryBenchmarkOptions(
    appDataDir: Directory(appDataDir ?? defaultLibraryProfileBenchDir()),
    count: count,
    clean: clean,
    titlePrefix: titlePrefix,
  );
}

class _SeedCliHelpRequest implements Exception {}

const seedLibraryBenchmarkHelp = '''
Comic Book Maker — Library Profile 基准 seed 工具

用法（需 Flutter 引擎与 Core 动态库，见 docs/agents/library-profile-benchmark.md）：
  .\\scripts\\seed-library-benchmark.ps1 [options]

或在 app/ 目录：
  flutter test test/tool/seed_library_benchmark_cli_test.dart \\
    --dart-define=SEED_COUNT=50 \\
    --dart-define=SEED_APP_DATA_DIR=C:\\\\temp\\\\cbm-library-profile-bench \\
    --dart-define=SEED_CLEAN=true

选项：
  --count <n>           创建 Project 数量（默认 50）
  --app-data-dir <path> 应用数据目录（默认 %TEMP%\\cbm-library-profile-bench）
  --clean               若目录已存在则先删除再 seed
  --title-prefix <text> Project 标题前缀（默认「Profile 基准」）
  -h, --help            显示此帮助

前置：integration_test/fixtures/two_pages.cbz
  dart run tool/generate_integration_fixture.dart
''';

Future<void> ensureSeedRustReady() async {
  WidgetsFlutterBinding.ensureInitialized();
  await RustLib.init();
}

Future<int> runSeedLibraryBenchmarkCli(List<String> args) async {
  try {
    final options = parseSeedLibraryBenchmarkArgs(args);
    await ensureSeedRustReady();
    final result = await seedLibraryBenchmark(options);

    stdout.writeln(
      'Seeded ${result.projectCount} projects '
      '(${result.coverThumbnailCount} with Cover Thumbnail)',
    );
    stdout.writeln('App data: ${result.appDataDir.path}');
    stdout.writeln();
    stdout.writeln('Profile 验收：');
    stdout.writeln(
      '  flutter run --profile -d windows '
      '--dart-define=CBM_APP_DATA_DIR=${result.appDataDir.path}',
    );
    stdout.writeln('详见 docs/agents/library-profile-benchmark.md');
    return 0;
  } on _SeedCliHelpRequest {
    stdout.writeln(seedLibraryBenchmarkHelp);
    return 0;
  } on FormatException catch (error) {
    stderr.writeln('Error: ${error.message}');
    stderr.writeln('Run with --help for usage.');
    return 64;
  } catch (error, stackTrace) {
    stderr.writeln('Error: $error');
    stderr.writeln(stackTrace);
    return 1;
  }
}

/// 入口：请通过 [scripts/seed-library-benchmark.ps1] 或 flutter test CLI 测试调用。
Future<void> main(List<String> args) async {
  exit(await runSeedLibraryBenchmarkCli(args));
}
