// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'project_workspace_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// 单个项目编辑会话的 deep controller：经 [CoreGateway] 访问 Core。

@ProviderFor(ProjectWorkspace)
final projectWorkspaceProvider = ProjectWorkspaceFamily._();

/// 单个项目编辑会话的 deep controller：经 [CoreGateway] 访问 Core。
final class ProjectWorkspaceProvider
    extends $NotifierProvider<ProjectWorkspace, ProjectWorkspaceState> {
  /// 单个项目编辑会话的 deep controller：经 [CoreGateway] 访问 Core。
  ProjectWorkspaceProvider._({
    required ProjectWorkspaceFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'projectWorkspaceProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$projectWorkspaceHash();

  @override
  String toString() {
    return r'projectWorkspaceProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ProjectWorkspace create() => ProjectWorkspace();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ProjectWorkspaceState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ProjectWorkspaceState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProjectWorkspaceProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$projectWorkspaceHash() => r'f063343d685eb28b6930fdac3017a4b78bc3220c';

/// 单个项目编辑会话的 deep controller：经 [CoreGateway] 访问 Core。

final class ProjectWorkspaceFamily extends $Family
    with
        $ClassFamilyOverride<
          ProjectWorkspace,
          ProjectWorkspaceState,
          ProjectWorkspaceState,
          ProjectWorkspaceState,
          String
        > {
  ProjectWorkspaceFamily._()
    : super(
        retry: null,
        name: r'projectWorkspaceProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// 单个项目编辑会话的 deep controller：经 [CoreGateway] 访问 Core。

  ProjectWorkspaceProvider call(String projectId) =>
      ProjectWorkspaceProvider._(argument: projectId, from: this);

  @override
  String toString() => r'projectWorkspaceProvider';
}

/// 单个项目编辑会话的 deep controller：经 [CoreGateway] 访问 Core。

abstract class _$ProjectWorkspace extends $Notifier<ProjectWorkspaceState> {
  late final _$args = ref.$arg as String;
  String get projectId => _$args;

  ProjectWorkspaceState build(String projectId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<ProjectWorkspaceState, ProjectWorkspaceState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ProjectWorkspaceState, ProjectWorkspaceState>,
              ProjectWorkspaceState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
