import 'package:comic_book_maker/ui/features/library/library_sort.dart';
import 'package:comic_book_maker/ui/features/library/providers/library_sort_provider.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 漫画库排序菜单：选中项显示升/降序 icon。
class LibrarySortMenuButton extends ConsumerWidget {
  const LibrarySortMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(librarySortProvider);

    return PopupMenuButton<LibrarySortField>(
      tooltip: '排序',
      position: PopupMenuPosition.under,
      icon: const Icon(LucideIcons.arrowUpDown),
      onSelected: (field) {
        ref.read(librarySortProvider.notifier).selectField(field);
      },
      itemBuilder: (context) => [
        for (final field in LibrarySortField.values)
          PopupMenuItem<LibrarySortField>(
            value: field,
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  child: sort.field == field
                      ? Icon(
                          sort.ascending
                              ? LucideIcons.arrowUp
                              : LucideIcons.arrowDown,
                          size: 18,
                        )
                      : null,
                ),
                const SizedBox(width: 8),
                Text(field.label),
              ],
            ),
          ),
      ],
    );
  }
}
