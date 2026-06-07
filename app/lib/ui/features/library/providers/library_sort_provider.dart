import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/features/library/library_sort.dart';
import 'package:comic_book_maker/ui/features/library/providers/library_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _sortFieldKey = 'library_sort_field';
const _sortAscendingKey = 'library_sort_ascending';

final librarySortProvider =
    NotifierProvider<LibrarySortNotifier, LibrarySortState>(
  LibrarySortNotifier.new,
);

final sortedLibraryProjectsProvider = Provider<List<ProjectSummary>>((ref) {
  final projects = ref.watch(libraryProjectsProvider);
  final sort = ref.watch(librarySortProvider);
  return sortLibraryProjects(projects, sort);
});

class LibrarySortNotifier extends Notifier<LibrarySortState> {
  @override
  LibrarySortState build() {
    _restore();
    return LibrarySortState.defaults();
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final fieldName = prefs.getString(_sortFieldKey);
    final ascending = prefs.getBool(_sortAscendingKey);
    final field = LibrarySortField.values.firstWhere(
      (candidate) => candidate.name == fieldName,
      orElse: () => LibrarySortField.createdAt,
    );

    state = LibrarySortState(
      field: field,
      ascending: ascending ?? field.defaultAscending,
    );
  }

  Future<void> selectField(LibrarySortField field) async {
    if (state.field == field) {
      await setSort(state.copyWith(ascending: !state.ascending));
      return;
    }
    await setSort(
      LibrarySortState(
        field: field,
        ascending: field.defaultAscending,
      ),
    );
  }

  Future<void> setSort(LibrarySortState value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sortFieldKey, value.field.name);
    await prefs.setBool(_sortAscendingKey, value.ascending);
    state = value;
  }
}
