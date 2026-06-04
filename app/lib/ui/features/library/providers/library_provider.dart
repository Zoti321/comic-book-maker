import 'package:comic_book_maker/domain/use_cases/library_operations.dart';
import 'package:comic_book_maker/providers/core_gateway_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_provider.g.dart';

@Riverpod(keepAlive: true)
LibraryOperations libraryOperations(Ref ref) {
  return LibraryOperations(
    gateway: ref.watch(coreGatewayProvider),
    onLibraryChanged: () {
      ref.invalidate(libraryProjectsProvider);
    },
  );
}

@Riverpod(keepAlive: true)
class LibraryProjects extends _$LibraryProjects {
  @override
  List<ProjectSummary> build() {
    return ref.read(libraryOperationsProvider).listProjects();
  }

  void reload() => ref.invalidateSelf();
}
