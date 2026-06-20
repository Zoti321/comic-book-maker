import 'dart:io';

import 'package:path/path.dart' as p;

import '../../tool/integration_fixture_cbz.dart';

const integrationFixtureCbzName = 'two_pages.cbz';

/// `integration_test/fixtures/two_pages.cbz` 的绝对路径。
String integrationFixtureCbzPath() {
  return p.join(_integrationTestRoot(), 'fixtures', integrationFixtureCbzName);
}

String _integrationTestRoot() {
  final cwd = Directory.current.path;
  if (p.basename(cwd) == 'app') {
    return p.join(cwd, 'integration_test');
  }
  return p.join(cwd, 'app', 'integration_test');
}

void ensureIntegrationFixtureCbz() {
  ensureValidIntegrationFixtureCbzFile(integrationFixtureCbzPath());
}

/// 从 fixture 文件名推断导入后的库内标题（与 Core 一致）。
String integrationFixtureCatalogTitle() {
  return p.basenameWithoutExtension(integrationFixtureCbzName);
}
