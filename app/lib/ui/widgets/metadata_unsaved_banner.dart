import 'package:comic_book_maker/ui/design_system/app_button.dart';
import 'package:comic_book_maker/ui/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// 元数据表单有未保存修改时的提示条。
class MetadataUnsavedBanner extends StatelessWidget {
  const MetadataUnsavedBanner({
    super.key,
    required this.onSave,
    this.saving = false,
  });

  final VoidCallback onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: scheme.tertiaryContainer,
      borderRadius: AppRadius.mdBorder,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(
              Icons.edit_note_outlined,
              size: 20,
              color: scheme.onTertiaryContainer,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '有未保存的更改',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: scheme.onTertiaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            AppButton(
              variant: AppButtonVariant.ghost,
              onPressed: saving ? null : onSave,
              child: Text(saving ? '保存中…' : '立即保存'),
            ),
          ],
        ),
      ),
    );
  }
}
