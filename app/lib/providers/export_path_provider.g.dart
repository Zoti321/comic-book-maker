// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'export_path_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ExportPath)
final exportPathProvider = ExportPathProvider._();

final class ExportPathProvider
    extends $AsyncNotifierProvider<ExportPath, String?> {
  ExportPathProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportPathProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportPathHash();

  @$internal
  @override
  ExportPath create() => ExportPath();
}

String _$exportPathHash() => r'2b6f840ab9c08e1ed09dd6d955ec1640327a510c';

abstract class _$ExportPath extends $AsyncNotifier<String?> {
  FutureOr<String?> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String?>, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String?>, String?>,
              AsyncValue<String?>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
