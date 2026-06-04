// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(libraryOperations)
final libraryOperationsProvider = LibraryOperationsProvider._();

final class LibraryOperationsProvider
    extends
        $FunctionalProvider<
          LibraryOperations,
          LibraryOperations,
          LibraryOperations
        >
    with $Provider<LibraryOperations> {
  LibraryOperationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryOperationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryOperationsHash();

  @$internal
  @override
  $ProviderElement<LibraryOperations> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  LibraryOperations create(Ref ref) {
    return libraryOperations(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(LibraryOperations value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<LibraryOperations>(value),
    );
  }
}

String _$libraryOperationsHash() => r'9cb3568c602802dbc2d1a489f3236167a2e95f26';

@ProviderFor(LibraryProjects)
final libraryProjectsProvider = LibraryProjectsProvider._();

final class LibraryProjectsProvider
    extends $NotifierProvider<LibraryProjects, List<ProjectSummary>> {
  LibraryProjectsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'libraryProjectsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$libraryProjectsHash();

  @$internal
  @override
  LibraryProjects create() => LibraryProjects();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<ProjectSummary> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<ProjectSummary>>(value),
    );
  }
}

String _$libraryProjectsHash() => r'7bb8d6e752398c052aa253c3bc2c076d54be0e7e';

abstract class _$LibraryProjects extends $Notifier<List<ProjectSummary>> {
  List<ProjectSummary> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<List<ProjectSummary>, List<ProjectSummary>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<ProjectSummary>, List<ProjectSummary>>,
              List<ProjectSummary>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
