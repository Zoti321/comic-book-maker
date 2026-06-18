import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 漫画库页内联错误条（Material errorContainer，无 design_system 依赖）。
class LibraryInlineErrorBanner extends StatelessWidget {
  const LibraryInlineErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.padding,
  });

  final String message;
  final VoidCallback? onDismiss;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Material(
        color: scheme.errorContainer,
        borderRadius: AppRadius.mdBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.error_outline,
                size: 20,
                color: scheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onErrorContainer,
                      ),
                ),
              ),
              if (onDismiss != null) ...[
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                  color: scheme.onErrorContainer,
                  tooltip: '关闭',
                  visualDensity: VisualDensity.compact,
                  onPressed: onDismiss,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
