import 'package:comic_book_maker/ui/core/design_system/app_toast.dart';
import 'package:comic_book_maker/ui/core/design_system/app_toast_controller.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 根级 Toast 宿主：在 [MaterialApp.builder] 中包裹全站内容。
class AppToastHost extends StatelessWidget {
  const AppToastHost({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        ListenableBuilder(
          listenable: AppToastController.instance,
          builder: (context, _) {
            final items = AppToastController.instance.items;
            if (items.isEmpty) return const SizedBox.shrink();

            return Positioned(
              right: AppSpacing.md,
              bottom: AppSpacing.md,
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final item in items)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.sm),
                        child: AppToast(
                          item: item,
                          onDismiss: () => AppToastController.instance
                              .onDismissPressed(item.id),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
