import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:path/path.dart' as p;

const integrationFixtureComicInfoXml = '''<?xml version="1.0"?>
<ComicInfo>
  <Title>集成测试漫画</Title>
  <Series>Sample Series</Series>
  <Number>1</Number>
  <PageCount>2</PageCount>
</ComicInfo>
''';

const _fixturePngBase64 =
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==';

/// 1×1 PNG，供集成 / Profile 基准 fixture 复用。
Uint8List integrationFixturePngBytes() {
  return Uint8List.fromList(base64Decode(_fixturePngBase64));
}

/// 编码为 CBZ（ZIP）字节；跨平台，不依赖 shell `tar` / PowerShell。
List<int> encodeIntegrationFixtureCbzBytes() {
  final png = integrationFixturePngBytes();
  final comicInfo = utf8.encode(integrationFixtureComicInfoXml);
  final archive = Archive()
    ..addFile(ArchiveFile('001.png', png.length, png))
    ..addFile(ArchiveFile('002.png', png.length, png))
    ..addFile(ArchiveFile('ComicInfo.xml', comicInfo.length, comicInfo));

  final encoded = ZipEncoder().encode(archive);
  if (encoded.isEmpty) {
    throw StateError('Failed to encode integration fixture CBZ');
  }
  return encoded;
}

/// `app/integration_test/fixtures/two_pages.cbz` 绝对路径（cwd 为 app/ 或仓库根）。
String integrationFixtureCbzOutputPath({String? cwd}) {
  final root = cwd ?? Directory.current.path;
  final appRoot = p.basename(root) == 'app' ? root : p.join(root, 'app');
  return p.join(appRoot, 'integration_test', 'fixtures', 'two_pages.cbz');
}

void writeIntegrationFixtureCbz(String outPath) {
  File(outPath).writeAsBytesSync(encodeIntegrationFixtureCbzBytes());
}

/// ZIP 本地文件头魔数 `PK`。
bool isZipArchiveBytes(List<int> bytes) {
  return bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4b;
}

void ensureValidIntegrationFixtureCbzFile(String path) {
  final file = File(path);
  if (!file.existsSync()) {
    throw StateError(
      'Missing fixture at $path. Run: dart run tool/generate_integration_fixture.dart',
    );
  }
  final bytes = file.readAsBytesSync();
  if (!isZipArchiveBytes(bytes)) {
    throw StateError(
      'Invalid CBZ fixture at $path (not a ZIP archive). '
      'Run: dart run tool/generate_integration_fixture.dart',
    );
  }
}
