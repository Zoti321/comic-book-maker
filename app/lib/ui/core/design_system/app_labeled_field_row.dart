import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 设置表单行：宽屏左 label（128px）右 field，窄屏低于 [stackBreakpoint] 时上下堆叠。
class AppLabeledFieldRow extends StatelessWidget {
  const AppLabeledFieldRow({
    super.key,
    this.label,
    required this.child,
    this.reserveLeadingSpace = false,
    this.labelWidth = 128,
    this.stackBreakpoint = 480,
    this.gap = AppSpacing.md,
  });

  final String? label;
  final Widget child;

  /// 无 [label] 时仍保留左列占位（复选框行对齐用）。
  final bool reserveLeadingSpace;
  final double labelWidth;
  final double stackBreakpoint;
  final double gap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurface,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final useHorizontal =
            constraints.maxWidth >= stackBreakpoint &&
                (label != null || reserveLeadingSpace);

        if (useHorizontal) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: labelWidth,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: label == null
                      ? const SizedBox.shrink()
                      : Text(label!, style: labelStyle),
                ),
              ),
              SizedBox(width: gap),
              Expanded(child: child),
            ],
          );
        }

        if (label == null) {
          return child;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(label!, style: labelStyle),
            SizedBox(height: gap / 2),
            child,
          ],
        );
      },
    );
  }
}
