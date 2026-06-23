import 'package:comic_book_maker/domain/models/app_update_release.dart';
import 'package:comic_book_maker/domain/use_cases/app_release_notes_format.dart';
import 'package:flutter/material.dart';

class AppUpdateReleaseNotesContent extends StatelessWidget {
  const AppUpdateReleaseNotesContent({
    super.key,
    required this.release,
  });

  final AppUpdateRelease release;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium;
    final blocks = parseReleaseNoteBlocks(release.releaseNotes);
    final publishedLabel = release.publishedAt == null
        ? null
        : formatReleasePublishedAtLabel(release.publishedAt!);

    return SelectionArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (blocks.isEmpty)
            Text('暂无更新说明', style: textStyle)
          else
            for (final block in blocks)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: switch (block) {
                  ReleaseNoteBullet(:final text) => Text(
                      '- $text',
                      style: textStyle,
                    ),
                  ReleaseNoteParagraph(:final text) => Text(
                      text,
                      style: textStyle,
                    ),
                },
              ),
          if (publishedLabel != null) ...[
            const SizedBox(height: 12),
            Text(
              publishedLabel,
              style: textStyle?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
