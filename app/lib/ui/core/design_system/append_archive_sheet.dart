import 'package:comic_book_maker/domain/models/append_archive_format.dart';
import 'package:comic_book_maker/ui/core/design_system/app_button.dart';
import 'package:comic_book_maker/ui/core/design_system/app_sheet.dart';
import 'package:flutter/material.dart';

/// 编辑页追加导入：选择 CBZ 或 CBR。
Future<AppendArchiveFormat?> showAppendArchiveSheet(BuildContext context) {
  return showAppBottomSheet<AppendArchiveFormat>(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSheetTitle('从漫画压缩包导入'),
        const SizedBox(height: 12),
        AppButton(
          variant: AppButtonVariant.outline,
          icon: const Icon(Icons.folder_zip_outlined),
          onPressed: () => Navigator.pop(context, AppendArchiveFormat.cbz),
          child: const Text('选择 CBZ'),
        ),
        const SizedBox(height: 8),
        AppButton(
          variant: AppButtonVariant.outline,
          icon: const Icon(Icons.archive_outlined),
          onPressed: () => Navigator.pop(context, AppendArchiveFormat.cbr),
          child: const Text('选择 CBR'),
        ),
      ],
    ),
  );
}
