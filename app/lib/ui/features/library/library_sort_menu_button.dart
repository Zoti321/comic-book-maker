import 'package:comic_book_maker/ui/core/design_system/design_system.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:comic_book_maker/ui/features/library/library_sort.dart';
import 'package:comic_book_maker/ui/features/library/providers/library_sort_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 漫画库排序菜单：选中项显示升/降序 icon。
class LibrarySortMenuButton extends HookConsumerWidget {
  const LibrarySortMenuButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useMemoized(AppPopupMenuController.new);
    final sort = ref.watch(librarySortProvider);

    return AppPopupMenu(
      controller: controller,
      menuBuilder: () => AppPopupMenuPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: AppSpacing.xs / 2,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final field in LibrarySortField.values)
              AppPopupMenuItem(
                label: field.label,
                selected: sort.field == field,
                leading: sort.field == field
                    ? Icon(
                        sort.ascending
                            ? LucideIcons.arrowUp
                            : LucideIcons.arrowDown,
                        size: 18,
                      )
                    : null,
                onTap: () {
                  ref.read(librarySortProvider.notifier).selectField(field);
                  controller.hideMenu();
                },
              ),
          ],
        ),
      ),
      child: AppIconButton(
        icon: const Icon(LucideIcons.arrowUpDown),
        onPressed: controller.toggleMenu,
      ),
    );
  }
}
