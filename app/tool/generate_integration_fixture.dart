import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

/// 生成 `integration_test/fixtures/two_pages.cbz`（一次性工具脚本）。
Future<void> main() async {
  final repoRoot = Directory.current.path.endsWith('app')
      ? Directory.current.path
      : p.join(Directory.current.path, 'app');
  final fixtureDir = Directory(p.join(repoRoot, 'integration_test', 'fixtures'));
  fixtureDir.createSync(recursive: true);

  final workDir = Directory.systemTemp.createTempSync('cbm-cbz-fixture-');
  final png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
  );
  File(p.join(workDir.path, '001.png')).writeAsBytesSync(png);
  File(p.join(workDir.path, '002.png')).writeAsBytesSync(png);
  File(p.join(workDir.path, 'ComicInfo.xml')).writeAsStringSync('''<?xml version="1.0"?>
<ComicInfo>
  <Title>集成测试漫画</Title>
  <Series>Sample Series</Series>
  <Number>1</Number>
  <PageCount>2</PageCount>
</ComicInfo>
''');

  final outPath = p.join(fixtureDir.path, 'two_pages.cbz');
  if (File(outPath).existsSync()) {
    File(outPath).deleteSync();
  }

  if (Platform.isWindows) {
    final result = await Process.run(
      'powershell',
      [
        '-NoProfile',
        '-Command',
        "Set-Location '${workDir.path}'; Compress-Archive -Path '001.png','002.png','ComicInfo.xml' -DestinationPath 'bundle.zip' -Force",
      ],
    );
    if (result.exitCode != 0) {
      stderr.writeln(result.stderr);
      exit(result.exitCode);
    }
    final zipPath = p.join(workDir.path, 'bundle.zip');
    await File(zipPath).copy(outPath);
  } else {
    final result = await Process.run(
      'tar',
      ['-a', '-cf', outPath, '001.png', '002.png', 'ComicInfo.xml'],
      workingDirectory: workDir.path,
    );
    if (result.exitCode != 0) {
      stderr.writeln(result.stderr);
      exit(result.exitCode);
    }
  }

  workDir.deleteSync(recursive: true);
  stdout.writeln('Wrote $outPath (${File(outPath).lengthSync()} bytes)');
}
