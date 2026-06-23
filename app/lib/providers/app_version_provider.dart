import 'package:package_info_plus/package_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_version_provider.g.dart';

@Riverpod(keepAlive: true)
class AppVersion extends _$AppVersion {
  @override
  Future<String> build() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }
}
