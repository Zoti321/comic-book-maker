import 'dart:io';

import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../../tool/seed_library_benchmark.dart';

void main() {
  setUpAll(() async {
    await ensureSeedRustReady();
  });

  tearDown(() {
    resetLibraryForTesting();
  });

  test('seeds projects with cover thumbnails', () async {
    final dir = await Directory.systemTemp.createTemp('cbm-seed-test-');
    addTearDown(() async {
      resetLibraryForTesting();
      if (dir.existsSync()) {
        await dir.delete(recursive: true);
      }
    });

    final result = await seedLibraryBenchmark(
      SeedLibraryBenchmarkOptions(
        appDataDir: dir,
        count: 2,
        clean: true,
      ),
    );

    expect(result.projectCount, 2);
    expect(result.coverThumbnailCount, 2);

    final projects = listProjects();
    expect(projects, hasLength(2));
    expect(projects.every((project) => project.title.startsWith('Profile 基准')), isTrue);
  });

  test('parseSeedLibraryBenchmarkArgs applies defaults and flags', () {
    final options = parseSeedLibraryBenchmarkArgs([
      '--count',
      '3',
      '--app-data-dir',
      r'C:\bench',
      '--clean',
      '--title-prefix',
      'Bench',
    ]);

    expect(options.count, 3);
    expect(options.appDataDir.path, r'C:\bench');
    expect(options.clean, isTrue);
    expect(options.titlePrefix, 'Bench');
  });

  test('rejects existing library without clean', () async {
    final dir = Directory.systemTemp.createTempSync('cbm-seed-parse-');
    addTearDown(() {
      if (dir.existsSync()) {
        dir.deleteSync(recursive: true);
      }
    });
    File(p.join(dir.path, 'library.db')).writeAsStringSync('');

    await expectLater(
      seedLibraryBenchmark(
        SeedLibraryBenchmarkOptions(appDataDir: dir, count: 1),
      ),
      throwsA(isA<StateError>()),
    );
  });
}
