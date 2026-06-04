// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'core_gateway_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(coreGateway)
final coreGatewayProvider = CoreGatewayProvider._();

final class CoreGatewayProvider
    extends $FunctionalProvider<CoreGateway, CoreGateway, CoreGateway>
    with $Provider<CoreGateway> {
  CoreGatewayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coreGatewayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coreGatewayHash();

  @$internal
  @override
  $ProviderElement<CoreGateway> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CoreGateway create(Ref ref) {
    return coreGateway(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoreGateway value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoreGateway>(value),
    );
  }
}

String _$coreGatewayHash() => r'deb76800fd27fa5ddc04cc4abe5fbbf024c9518b';
