import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:textfield_tags/textfield_tags.dart';

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

class MetadataCommaTagController extends StringTagController {
  bool _containsIgnoreCase(String tag) {
    return getTags?.any((existing) => existing.toLowerCase() == tag.toLowerCase()) ??
        false;
  }

  @override
  bool? onTagSubmitted(String tag) {
    final trimmed = tag.trim().replaceAll(',', '');
    if (trimmed.isEmpty) {
      getTextEditingController?.clear();
      return false;
    }
    if (_containsIgnoreCase(trimmed)) {
      getTextEditingController?.clear();
      notifyListeners();
      return false;
    }
    return super.onTagSubmitted(trimmed);
  }

  void replaceTags(List<String> tags) {
    clearTags();
    for (final tag in tags) {
      if (tag.isEmpty) continue;
      if (_containsIgnoreCase(tag)) continue;
      super.onTagSubmitted(tag);
    }
  }
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
  late final MetadataCommaTagController _tagController;
  var _applyingExternalTags = false;

  @override
  void initState() {
    super.initState();
    _tagController = MetadataCommaTagController();
    widget.controller.addListener(_syncFromCommittedController);
    _tagController.addListener(_commitTagsToController);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncFromCommittedController();
    });
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
    _tagController.removeListener(_commitTagsToController);
    _tagController.dispose();
    super.dispose();
  }

  void _syncFromCommittedController() {
    if (widget.focusNode.hasFocus) return;

    final parsed = parseCommaSeparatedTags(widget.controller.text);
    final current = _tagController.getTags ?? const <String>[];
    if (_tagsEqual(parsed, current)) return;

    _applyingExternalTags = true;
    _tagController.replaceTags(parsed);
    _applyingExternalTags = false;
    setState(() {});
  }

  bool _tagsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _commitTagsToController() {
    if (_applyingExternalTags) return;

    final text = formatCommaSeparatedTags(_tagController.getTags ?? const []);
    if (widget.controller.text == text) return;
    widget.controller.text = text;
    widget.onChanged();
  }

  Widget _tagChip({
    required String tag,
    required ColorScheme scheme,
    required ThemeData theme,
    required VoidCallback onRemove,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: scheme.outline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            tag,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            borderRadius: AppRadius.smBorder,
            child: Icon(
              LucideIcons.x,
              size: 14,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final decorationTheme = theme.inputDecorationTheme;

    return TextFieldTags<String>(
          textfieldTagsController: _tagController,
          focusNode: widget.focusNode,
          initialTags: parseCommaSeparatedTags(widget.controller.text),
          textSeparators: const [','],
          letterCase: LetterCase.normal,
          inputFieldBuilder: (context, inputFieldValues) {
            final hasTags = inputFieldValues.tags.isNotEmpty;
            final hasPendingText =
                inputFieldValues.textEditingController.text.isNotEmpty;

            return InputDecorator(
              decoration: InputDecoration(
                labelText: widget.label,
                errorText: inputFieldValues.error,
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
                          for (final tag in inputFieldValues.tags)
                            _tagChip(
                              tag: tag,
                              scheme: scheme,
                              theme: theme,
                              onRemove: () =>
                                  inputFieldValues.onTagRemoved(tag),
                            ),
                        ],
                      ),
                    ),
                  TextField(
                    controller: inputFieldValues.textEditingController,
                    focusNode: inputFieldValues.focusNode,
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
                    onChanged: inputFieldValues.onTagChanged,
                    onSubmitted: (value) {
                      inputFieldValues.onTagSubmitted(value);
                      widget.onEditingComplete?.call();
                    },
                  ),
                ],
              ),
            );
          },
        );
  }
}
