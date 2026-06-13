import 'package:flutter/material.dart';

/// 单行截断文本；仅当内容溢出时 hover 显示全文 tooltip。
class EllipsisTooltipText extends StatelessWidget {
  const EllipsisTooltipText({
    super.key,
    required this.text,
    required this.style,
    this.waitDuration = const Duration(milliseconds: 1500),
  });

  final String text;
  final TextStyle? style;
  final Duration waitDuration;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          text: TextSpan(text: text, style: style),
          maxLines: 1,
          textDirection: Directionality.of(context),
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = painter.didExceedMaxLines ||
            painter.width > constraints.maxWidth;

        final label = Text(
          text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: style,
        );

        if (!isOverflowing) return label;

        return Tooltip(
          message: text,
          waitDuration: waitDuration,
          child: label,
        );
      },
    );
  }
}
