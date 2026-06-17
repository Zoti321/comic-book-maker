import 'package:flutter/material.dart';

/// ComicInfo 存储格式：逗号分隔，逗号后无空格。
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

/// 元数据创作 Tab：逗号分隔多标签输入（作者 / 标签 / 登场人物）。
class MetadataCommaTagsField extends StatefulWidget {
  const MetadataCommaTagsField({
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
  State<MetadataCommaTagsField> createState() => _MetadataCommaTagsFieldState();
}

class _MetadataCommaTagsFieldState extends State<MetadataCommaTagsField> {
  late final TextEditingController _inputController;
  List<String> _tags = [];
  var _applyingExternalTags = false;

  @override
  void initState() {
    super.initState();
    _inputController = TextEditingController();
    _tags = parseCommaSeparatedTags(widget.controller.text);
    widget.controller.addListener(_syncFromCommittedController);
  }

  @override
  void didUpdateWidget(covariant MetadataCommaTagsField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_syncFromCommittedController);
      widget.controller.addListener(_syncFromCommittedController);
      _syncFromCommittedController();
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_syncFromCommittedController);
    _inputController.dispose();
    super.dispose();
  }

  void _syncFromCommittedController() {
    if (widget.focusNode.hasFocus) return;

    final parsed = parseCommaSeparatedTags(widget.controller.text);
    if (_tagsEqual(parsed, _tags)) return;

    setState(() => _tags = List<String>.of(parsed));
  }

  bool _tagsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  bool _containsIgnoreCase(String tag) {
    return _tags.any((existing) => existing.toLowerCase() == tag.toLowerCase());
  }

  void _tryAddTag(String raw) {
    final trimmed = raw.trim().replaceAll(',', '');
    if (trimmed.isEmpty) {
      _inputController.clear();
      return;
    }
    if (_containsIgnoreCase(trimmed)) {
      _inputController.clear();
      setState(() {});
      return;
    }
    setState(() {
      _tags.add(trimmed);
      _inputController.clear();
    });
    _commitTagsToController();
  }

  void _onInputChanged(String value) {
    final commaIndex = value.indexOf(',');
    if (commaIndex < 0) return;

    final before = value.substring(0, commaIndex);
    _tryAddTag(before);

    final after = value.substring(commaIndex + 1);
    if (after.isEmpty) return;

    _inputController.value = TextEditingValue(
      text: after,
      selection: TextSelection.collapsed(offset: after.length),
    );
    _onInputChanged(after);
  }

  void _removeTag(String tag) {
    setState(() => _tags.remove(tag));
    _commitTagsToController();
  }

  void _commitTagsToController() {
    if (_applyingExternalTags) return;

    final text = formatCommaSeparatedTags(_tags);
    if (widget.controller.text == text) return;
    widget.controller.text = text;
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final decorationTheme = theme.inputDecorationTheme;
    final hasTags = _tags.isNotEmpty;
    final hasPendingText = _inputController.text.isNotEmpty;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: widget.label,
      ).applyDefaults(decorationTheme),
      isEmpty: !hasTags && !hasPendingText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasTags)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final tag in _tags)
                    InputChip(
                      label: Text(tag),
                      onDeleted: () => _removeTag(tag),
                      deleteIcon: Icon(
                        Icons.close,
                        size: 16,
                        color: scheme.onSurfaceVariant,
                      ),
                      side: BorderSide(color: scheme.outline),
                      backgroundColor: scheme.surfaceContainer,
                      visualDensity: VisualDensity.compact,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                ],
              ),
            ),
          TextField(
            controller: _inputController,
            focusNode: widget.focusNode,
            style: theme.textTheme.bodyLarge,
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: '输入后按逗号或回车添加',
            ),
            onChanged: _onInputChanged,
            onSubmitted: (value) {
              _tryAddTag(value);
              widget.onEditingComplete?.call();
            },
          ),
        ],
      ),
    );
  }
}
