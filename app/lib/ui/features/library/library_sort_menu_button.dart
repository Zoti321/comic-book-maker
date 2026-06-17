import 'package:comic_book_maker/ui/features/library/library_sort.dart';
import 'package:comic_book_maker/ui/features/library/providers/library_sort_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 漫画库排序菜单（Material [MenuAnchor]）。
class LibrarySortMenuButton extends HookConsumerWidget {
  const LibrarySortMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sort = ref.watch(librarySortProvider);
    final menuController = useMemoized(MenuController.new);

    return MenuAnchor(
      controller: menuController,
      menuChildren: [
        for (final field in LibrarySortField.values)
          MenuItemButton(
            onPressed: () {
              ref.read(librarySortProvider.notifier).selectField(field);
              menuController.close();
            },
            child: _SortMenuRow(field: field, sort: sort),
          ),
      ],
      builder: (context, controller, child) {
        return IconButton(
          icon: const Icon(Icons.swap_vert),
          tooltip: '排序',
          style: IconButton.styleFrom(shape: const CircleBorder()),
          onPressed: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open();
            }
          },
        );
      },
    );
  }
}

class _SortMenuRow extends StatelessWidget {
  const _SortMenuRow({
    required this.field,
    required this.sort,
  });

  final LibrarySortField field;
  final LibrarySortState sort;

  @override
  Widget build(BuildContext context) {
    final selected = sort.field == field;
    final scheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 24,
          child: selected
              ? Icon(
                  sort.ascending
                      ? Icons.arrow_upward
                      : Icons.arrow_downward,
                  size: 18,
                  color: scheme.primary,
                )
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(field.label)),
        if (selected)
          Icon(Icons.check, size: 18, color: scheme.primary),
      ],
    );
  }
}
