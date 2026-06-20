import 'dart:io';

import 'integration_fixture_cbz.dart';

/// 生成 `integration_test/fixtures/two_pages.cbz`（跨平台 ZIP，供 Core Import 使用）。
Future<void> main() async {
  final outPath = integrationFixtureCbzOutputPath();
  Directory(File(outPath).parent.path).createSync(recursive: true);

  writeIntegrationFixtureCbz(outPath);
  ensureValidIntegrationFixtureCbzFile(outPath);

  stdout.writeln('Wrote $outPath (${File(outPath).lengthSync()} bytes)');
}
