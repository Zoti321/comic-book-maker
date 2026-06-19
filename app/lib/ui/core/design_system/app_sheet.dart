import 'package:comic_book_maker/ui/core/theme/app_overlay_transitions.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 桌面端弹层内容最大宽度。
const appSheetMaxWidth = 480.0;

/// M3 底部 Sheet；桌面端内容居中并限制宽度。
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  final scheme = Theme.of(context).colorScheme;
  final localizations = MaterialLocalizations.of(context);

  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: isDismissible,
    barrierLabel: localizations.modalBarrierDismissLabel,
    barrierColor: Colors.black54,
    transitionDuration: AppOverlayTransitions.transitionDuration(context),
    transitionBuilder: AppOverlayTransitions.sheetTransitionBuilder,
    pageBuilder: (sheetContext, animation, secondaryAnimation) {
      return Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: scheme.surface,
          elevation: 1,
          shadowColor: Colors.black26,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          clipBehavior: Clip.antiAlias,
          child: AppSheetFrame(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const _AppSheetDragHandle(),
                builder(sheetContext),
              ],
            ),
          ),
        ),
      );
    },
  );
}

/// Sheet 内边距与宽度约束容器。
class AppSheetFrame extends StatelessWidget {
  const AppSheetFrame({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;

    return SafeArea(
      top: false,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: appSheetMaxWidth,
            maxHeight: MediaQuery.sizeOf(context).height * 0.85,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
              AppSpacing.lg + bottomInset,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Sheet 标题（与 M3 [titleLarge] 一致）。
class AppSheetTitle extends StatelessWidget {
  const AppSheetTitle(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
    );
  }
}

/// Sheet 说明文字。
class AppSheetDescription extends StatelessWidget {
  const AppSheetDescription(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
    );
  }
}

class _AppSheetDragHandle extends StatelessWidget {
  const _AppSheetDragHandle();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Center(
        child: Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: scheme.onSurfaceVariant.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
