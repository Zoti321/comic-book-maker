import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:comic_book_maker/ui/core/theme/app_motion.dart';
import 'package:flutter/material.dart';

/// 漫画库空状态（Material 排版 + FilledButton 主操作）。
class LibraryEmptyState extends StatelessWidget {
  const LibraryEmptyState({
    super.key,
    required this.onCreateProject,
    this.showAction = true,
  });

  final VoidCallback onCreateProject;
  final bool showAction;

  static const _title = '还没有项目';
  static const _subtitle = '通过新建项目向导导入图片或漫画包开始制作';
  static const _subtitleEntranceDelay = Duration(milliseconds: 400);
  static const _actionEntranceDelay = Duration(milliseconds: 550);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final motionEnabled = AppMotion.enabled(context);

    final titleStyle = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
    );
    final subtitleStyle = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
    );

    final icon = Icon(
      Icons.folder_open_outlined,
      size: 64,
      color: scheme.onSurfaceVariant.withValues(alpha: 0.6),
    );

    final title = motionEnabled
        ? DefaultTextStyle(
            style: titleStyle ?? const TextStyle(),
            textAlign: TextAlign.center,
            child: AnimatedTextKit(
              isRepeatingAnimation: false,
              totalRepeatCount: 1,
              animatedTexts: [
                FadeAnimatedText(
                  _title,
                  textStyle: titleStyle,
                  duration: const Duration(milliseconds: 600),
                ),
              ],
            ),
          )
        : Text(
            _title,
            textAlign: TextAlign.center,
            style: titleStyle,
          );

    final subtitle = Text(
      _subtitle,
      textAlign: TextAlign.center,
      style: subtitleStyle,
    );

    final action = showAction
        ? FilledButton.icon(
            onPressed: onCreateProject,
            icon: const Icon(Icons.add),
            label: const Text('新建项目'),
          )
        : null;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              motionEnabled ? icon.fadeEntrance(context) : icon,
              const SizedBox(height: 20),
              title,
              const SizedBox(height: 8),
              motionEnabled
                  ? subtitle.fadeEntrance(
                      context,
                      delay: AppMotion.duration(context, _subtitleEntranceDelay),
                    )
                  : subtitle,
              if (action != null) ...[
                const SizedBox(height: 24),
                motionEnabled
                    ? action.fadeEntrance(
                        context,
                        delay: AppMotion.duration(context, _actionEntranceDelay),
                      )
                    : action,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
