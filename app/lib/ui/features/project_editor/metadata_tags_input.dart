import 'package:flutter/material.dart';

/// ComicInfo Tags 存储格式：逗号分隔，逗号后无空格。
String formatCommaSeparatedTags(List<String> tags) => tags.join(',');

/// 解析逗号分隔标签；忽略空段并按不区分大小写去重（保留首次出现顺序）。
List<String> parseCommaSeparatedTags(String raw) {
  final seen = <String>{};
  final result = <String>[];
  for (final part in raw.split(',')) {
    final tag = part.trim();
    if (tag.isEmpty) continue;
    final key = tag.toLowerCase();
    if (seen.add(key)) result.add(tag);
  }
  return result;
}

/// 元数据「标签（逗号分隔）」输入：已选标签以 Chip 展示，避免重复添加。
class MetadataTagsInput extends StatefulWidget {
  const MetadataTagsInput({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.onChanged,
    this.onEditingComplete,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final VoidCallback onChanged;
  final VoidCallback? onEditingComplete;

  @override
  State<MetadataTagsInput> createState() => _MetadataTagsInputState();
}

class _MetadataTagsInputState extends State<MetadataTagsInput> {
  late final TextEditingController _pendingController;

  @override
  void initState() {
    super.initState();
    _pendingController = TextEditingController();
    widget.controller.addListener(_onCommittedTagsChanged);
  }

  @override
  void didUpdateWidget(covariant MetadataTagsInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onCommittedTagsChanged);
      widget.controller.addListener(_onCommittedTagsChanged);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onCommittedTagsChanged);
    _pendingController.dispose();
    super.dispose();
  }

  void _onCommittedTagsChanged() {
    if (widget.focusNode.hasFocus) return;
    setState(() {});
  }

  List<String> get _committedTags => parseCommaSeparatedTags(widget.controller.text);

  void _setCommittedTags(List<String> tags) {
    final text = formatCommaSeparatedTags(tags);
    if (widget.controller.text == text) return;
    widget.controller.text = text;
    widget.onChanged();
    setState(() {});
  }

  void _commitPending({String? raw}) {
    final tag = (raw ?? _pendingController.text).trim().replaceAll(',', '');
    if (tag.isEmpty) {
      _pendingController.clear();
      return;
    }

    final tags = List<String>.from(_committedTags);
    if (tags.any((existing) => existing.toLowerCase() == tag.toLowerCase())) {
      _pendingController.clear();
      return;
    }

    tags.add(tag);
    _pendingController.clear();
    _setCommittedTags(tags);
  }

  void _onPendingChanged(String value) {
    if (!value.contains(',')) return;

    final parts = value.split(',');
    for (var i = 0; i < parts.length - 1; i++) {
      _commitPending(raw: parts[i]);
    }
    _pendingController.value = TextEditingValue(
      text: parts.last,
      selection: TextSelection.collapsed(offset: parts.last.length),
    );
  }

  void _removeTag(String tag) {
    final tags = List<String>.from(_committedTags)..remove(tag);
    _setCommittedTags(tags);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_committedTags.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in _committedTags)
                  InputChip(
                    label: Text(tag),
                    onDeleted: () => _removeTag(tag),
                  ),
              ],
            ),
          ),
        TextField(
          controller: _pendingController,
          focusNode: widget.focusNode,
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: '输入后按逗号或回车添加',
          ),
          onChanged: _onPendingChanged,
          onSubmitted: (_) {
            _commitPending();
            widget.onEditingComplete?.call();
          },
        ),
        const SizedBox(height: 4),
        Text(
          '已保存为逗号分隔文本，重复标签会自动忽略。',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
