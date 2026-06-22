/// This is copied from Cargokit (which is the official way to use it currently)
/// Details: https://fzyzcjy.github.io/flutter_rust_bridge/manual/integrate/builtin

import 'dart:io';

import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;

import 'artifacts_provider.dart';
import 'builder.dart';
import 'environment.dart';
import 'options.dart';
import 'target.dart';

final log = Logger('build_gradle');

class BuildGradle {
  BuildGradle({required this.userOptions});

  final CargokitUserOptions userOptions;

  Future<void> build() async {
    final targets = Environment.targetPlatforms.map((arch) {
      final target = Target.forFlutterName(arch);
      if (target == null) {
        throw Exception(
            "Unknown darwin target or platform: $arch, ${Environment.darwinPlatformName}");
      }
      return target;
    }).toList();

    final environment = BuildEnvironment.fromEnvironment(isAndroid: true);
    final provider =
        ArtifactProvider(environment: environment, userOptions: userOptions);
    final artifacts = await provider.getArtifacts(targets);

    for (final target in targets) {
      final libs = artifacts[target]!;
      final outputDir = path.join(Environment.outputDir, target.android!);
      Directory(outputDir).createSync(recursive: true);

      for (final lib in libs) {
        if (lib.type == AritifactType.dylib) {
          File(lib.path).copySync(path.join(outputDir, lib.finalFileName));
        }
      }
    }

    _copyAndroidCxxShared(targets);
  }

  void _copyAndroidCxxShared(List<Target> targets) {
    final hostArch = Platform.isWindows
        ? 'windows-x86_64'
        : (Platform.isLinux ? 'linux-x86_64' : 'darwin-x86_64');
    final ndkLibRoot = path.join(
      path.join(
        Environment.sdkPath,
        'ndk',
        Environment.ndkVersion,
        'toolchains',
        'llvm',
        'prebuilt',
        hostArch,
      ),
      'sysroot',
      'usr',
      'lib',
    );

    for (final target in targets) {
      final androidAbi = target.android;
      if (androidAbi == null) {
        continue;
      }
      final src = File(
        path.join(ndkLibRoot, target.rust, 'libc++_shared.so'),
      );
      if (!src.existsSync()) {
        log.warning('NDK libc++_shared.so not found at ${src.path}');
        continue;
      }
      final outputDir = path.join(Environment.outputDir, androidAbi);
      Directory(outputDir).createSync(recursive: true);
      src.copySync(path.join(outputDir, 'libc++_shared.so'));
    }
  }
}
