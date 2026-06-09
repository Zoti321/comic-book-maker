import 'package:comic_book_maker/ui/core/design_system/app_toast_controller.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 单条右下角操作 Toast（loading / success / error）。
class AppToast extends StatelessWidget {
  const AppToast({
    super.key,
    required this.item,
    required this.onDismiss,
  });

  final AppToastItem item;
  final VoidCallback onDismiss;

  static const maxWidth = 360.0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      elevation: 4,
      borderRadius: AppRadius.mdBorder,
      color: scheme.inverseSurface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.xs,
            AppSpacing.sm,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: _LeadingIcon(kind: item.kind, scheme: scheme),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.message,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onInverseSurface,
                      ),
                    ),
                    if (item.action case final action?)
                      Padding(
                        padding: const EdgeInsets.only(top: AppSpacing.xs),
                        child: TextButton(
                          onPressed: action.onPressed,
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            foregroundColor: scheme.inversePrimary,
                          ),
                          child: Text(action.label),
                        ),
                      ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onDismiss,
                icon: Icon(
                  LucideIcons.x,
                  size: 18,
                  color: scheme.onInverseSurface,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.kind, required this.scheme});

  final AppToastKind kind;
  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return switch (kind) {
      AppToastKind.loading => SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: scheme.onInverseSurface,
          ),
        ),
      AppToastKind.success => Icon(
          LucideIcons.circleCheck,
          size: 20,
          color: scheme.primary,
        ),
      AppToastKind.error => Icon(
          LucideIcons.circleAlert,
          size: 20,
          color: scheme.error,
        ),
    };
  }
}
