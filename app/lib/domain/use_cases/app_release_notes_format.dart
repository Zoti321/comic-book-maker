/// GitHub Release 说明解析与展示格式化。
sealed class ReleaseNoteBlock {
  const ReleaseNoteBlock(this.text);

  final String text;
}

final class ReleaseNoteBullet extends ReleaseNoteBlock {
  const ReleaseNoteBullet(super.text);
}

final class ReleaseNoteParagraph extends ReleaseNoteBlock {
  const ReleaseNoteParagraph(super.text);
}

List<ReleaseNoteBlock> parseReleaseNoteBlocks(String releaseNotes) {
  final trimmed = releaseNotes.trim();
  if (trimmed.isEmpty) {
    return const [];
  }

  final blocks = <ReleaseNoteBlock>[];
  for (final line in releaseNotes.split('\n')) {
    final lineText = line.trim();
    if (lineText.isEmpty) {
      continue;
    }
    if (lineText.startsWith('- ')) {
      blocks.add(ReleaseNoteBullet(lineText.substring(2).trim()));
    } else {
      blocks.add(ReleaseNoteParagraph(lineText));
    }
  }
  return blocks;
}

DateTime? parseReleasePublishedAt(Object? value) {
  if (value is! String || value.isEmpty) {
    return null;
  }
  return DateTime.tryParse(value);
}

String formatReleasePublishedAtLabel(DateTime publishedAt) {
  final local = publishedAt.toLocal();
  final year = local.year.toString().padLeft(4, '0');
  final month = local.month.toString().padLeft(2, '0');
  final day = local.day.toString().padLeft(2, '0');
  return '发布时间: $year-$month-$day';
}
