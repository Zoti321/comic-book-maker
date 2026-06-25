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

final _whatsChangedHeaderPattern = RegExp(
  r"^##\s+what's changed\s*$",
  caseSensitive: false,
);

List<ReleaseNoteBlock> parseReleaseNoteBlocks(String releaseNotes) {
  final trimmed = releaseNotes.trim();
  if (trimmed.isEmpty) {
    return const [];
  }

  final sectionLines = _extractWhatsChangedSectionLines(trimmed);
  if (sectionLines == null) {
    return const [];
  }

  final blocks = <ReleaseNoteBlock>[];
  for (final line in sectionLines) {
    final bulletText = _parseBulletLine(line.trim());
    if (bulletText == null) {
      continue;
    }
    blocks.add(ReleaseNoteBullet(_cleanBulletText(bulletText)));
  }
  return blocks;
}

List<String>? _extractWhatsChangedSectionLines(String releaseNotes) {
  final lines = releaseNotes.split('\n');
  var inSection = false;
  final sectionLines = <String>[];

  for (final line in lines) {
    final trimmed = line.trim();
    if (_isWhatsChangedHeader(trimmed)) {
      inSection = true;
      continue;
    }
    if (inSection && _isSectionHeader(trimmed)) {
      break;
    }
    if (inSection) {
      sectionLines.add(line);
    }
  }

  if (!inSection) {
    return null;
  }
  return sectionLines;
}

bool _isWhatsChangedHeader(String line) {
  return _whatsChangedHeaderPattern.hasMatch(line);
}

bool _isSectionHeader(String line) {
  return line.startsWith('## ');
}

String? _parseBulletLine(String lineText) {
  if (lineText.startsWith('- ')) {
    return lineText.substring(2).trim();
  }
  if (lineText.startsWith('* ')) {
    return lineText.substring(2).trim();
  }
  return null;
}

String _cleanBulletText(String text) {
  return text.replaceFirst(RegExp(r'\s+in\s+https?://\S+\s*$'), '').trim();
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
