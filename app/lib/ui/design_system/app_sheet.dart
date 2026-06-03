import 'package:comic_book_maker/ui/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 桌面端弹层内容最大宽度。
const appSheetMaxWidth = 480.0;

/// M3 底部 Sheet；桌面端内容居中并限制宽度。
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    isDismissible: isDismissible,
    builder: (context) => AppSheetFrame(child: builder(context)),
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
    return Text(
      text,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
