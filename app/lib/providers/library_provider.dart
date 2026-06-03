import 'package:comic_book_maker/src/rust/api/simple.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_provider.g.dart';

@Riverpod(keepAlive: true)
class LibraryProjects extends _$LibraryProjects {
  @override
  List<ProjectSummary> build() => listProjects();

  void reload() => ref.invalidateSelf();
}
