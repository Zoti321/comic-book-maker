import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/features/library/library_sort.dart';
import 'package:flutter_test/flutter_test.dart';

ProjectSummary _project({
  required String id,
  required String title,
  required int createdAtMs,
  int? lastOpenedAtMs,
}) {
  return ProjectSummary(
    id: id,
    title: title,
    updatedAtMs: createdAtMs,
    createdAtMs: createdAtMs,
    lastOpenedAtMs: lastOpenedAtMs,
    coverThumbnailPath: null,
  );
}

void main() {
  final projects = [
    _project(id: 'a', title: 'Alpha', createdAtMs: 100),
    _project(id: 'b', title: 'Beta', createdAtMs: 200, lastOpenedAtMs: 500),
    _project(id: 'c', title: 'Gamma', createdAtMs: 300, lastOpenedAtMs: 400),
  ];

  test('default sort orders by created time ascending', () {
    final sorted = sortLibraryProjects(projects, LibrarySortState.defaults());
    expect(sorted.map((project) => project.id).toList(), ['a', 'b', 'c']);
  });

  test('last opened descending puts newest open first', () {
    final sorted = sortLibraryProjects(
      projects,
      const LibrarySortState(
        field: LibrarySortField.lastOpenedAt,
        ascending: false,
      ),
    );
    expect(sorted.map((project) => project.id).toList(), ['b', 'c', 'a']);
  });

  test('title ascending sorts alphabetically', () {
    final sorted = sortLibraryProjects(
      projects,
      const LibrarySortState(
        field: LibrarySortField.title,
        ascending: true,
      ),
    );
    expect(sorted.map((project) => project.title).toList(),
        ['Alpha', 'Beta', 'Gamma']);
  });
}
