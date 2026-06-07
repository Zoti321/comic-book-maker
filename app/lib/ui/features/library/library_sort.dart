import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';

enum LibrarySortField {
  createdAt('创建时间'),
  lastOpenedAt('最近打开'),
  title('标题');

  const LibrarySortField(this.label);

  final String label;

  bool get defaultAscending => switch (this) {
        LibrarySortField.createdAt => true,
        LibrarySortField.lastOpenedAt => false,
        LibrarySortField.title => true,
      };
}

class LibrarySortState {
  const LibrarySortState({
    required this.field,
    required this.ascending,
  });

  final LibrarySortField field;
  final bool ascending;

  factory LibrarySortState.defaults() => const LibrarySortState(
        field: LibrarySortField.createdAt,
        ascending: true,
      );

  LibrarySortState copyWith({
    LibrarySortField? field,
    bool? ascending,
  }) {
    return LibrarySortState(
      field: field ?? this.field,
      ascending: ascending ?? this.ascending,
    );
  }
}

List<ProjectSummary> sortLibraryProjects(
  List<ProjectSummary> projects,
  LibrarySortState sort,
) {
  final sorted = List<ProjectSummary>.from(projects);
  sorted.sort((a, b) {
    final comparison = switch (sort.field) {
      LibrarySortField.createdAt =>
        a.createdAtMs.toInt().compareTo(b.createdAtMs.toInt()),
      LibrarySortField.lastOpenedAt => _compareLastOpened(
          a.lastOpenedAtMs,
          b.lastOpenedAtMs,
          ascending: sort.ascending,
        ),
      LibrarySortField.title =>
        a.title.toLowerCase().compareTo(b.title.toLowerCase()),
    };
    if (sort.field == LibrarySortField.lastOpenedAt) {
      return comparison;
    }
    return sort.ascending ? comparison : -comparison;
  });
  return sorted;
}

int _compareLastOpened(
  PlatformInt64? left,
  PlatformInt64? right, {
  required bool ascending,
}) {
  final leftMs = left?.toInt();
  final rightMs = right?.toInt();
  if (leftMs == null && rightMs == null) return 0;
  if (leftMs == null) return ascending ? -1 : 1;
  if (rightMs == null) return ascending ? 1 : -1;
  return ascending
      ? leftMs.compareTo(rightMs)
      : rightMs.compareTo(leftMs);
}
