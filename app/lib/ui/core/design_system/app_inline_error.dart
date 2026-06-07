import 'package:comic_book_maker/ui/core/design_system/app_button.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 页面内可恢复错误（FRB / 表单校验等）；不用 Dialog / SnackBar。
///
/// 见 [docs/agents/flutter-ui.md]「反馈模式」。
class AppInlineErrorBanner extends StatelessWidget {
  const AppInlineErrorBanner({
    super.key,
    required this.message,
    this.onDismiss,
    this.onRetry,
    this.padding,
  });

  final String message;
  final VoidCallback? onDismiss;
  final VoidCallback? onRetry;

  /// 默认 `fromLTRB(16, 8, 16, 0)`；嵌入卡片时可传 `EdgeInsets.zero`。
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Material(
        color: scheme.errorContainer,
        borderRadius: AppRadius.mdBorder,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                LucideIcons.circleAlert,
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
              if (onRetry != null) ...[
                const SizedBox(width: 8),
                AppButton(
                  variant: AppButtonVariant.ghost,
                  onPressed: onRetry,
                  child: const Text('重试'),
                ),
              ],
              if (onDismiss != null) ...[
                const SizedBox(width: 8),
                AppButton(
                  variant: AppButtonVariant.ghost,
                  onPressed: onDismiss,
                  child: const Text('关闭'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 与历史 import 路径兼容。
typedef InlineErrorBanner = AppInlineErrorBanner;
