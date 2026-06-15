import 'package:comic_book_maker/ui/features/library/library_sort.dart';
import 'package:comic_book_maker/ui/features/library/providers/library_sort_provider.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 漫画库排序菜单（Material [PopupMenuButton]）。
class LibrarySortMenuButton extends ConsumerWidget {
  const LibrarySortMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(librarySortProvider);
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<LibrarySortField>(
      icon: Icon(LucideIcons.arrowUpDown, color: scheme.onSurface),
      onSelected: (field) {
        ref.read(librarySortProvider.notifier).selectField(field);
      },
      itemBuilder: (context) {
        return [
          for (final field in LibrarySortField.values)
            PopupMenuItem<LibrarySortField>(
              value: field,
              child: Row(
                children: [
                  if (sort.field == field)
                    Icon(
                      sort.ascending
                          ? LucideIcons.arrowUp
                          : LucideIcons.arrowDown,
                      size: 18,
                    )
                  else
                    const SizedBox(width: 18, height: 18),
                  const SizedBox(width: 8),
                  Text(field.label),
                ],
              ),
            ),
        ];
      },
    );
  }
}
