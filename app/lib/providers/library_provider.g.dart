// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

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

String _$libraryProjectsHash() => r'479f3fe33bbc1031f80fa6a86cdda469d1b29197';

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
