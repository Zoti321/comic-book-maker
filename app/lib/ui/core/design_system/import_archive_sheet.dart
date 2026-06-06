import 'package:comic_book_maker/domain/models/import_archive_format.dart';
import 'package:comic_book_maker/ui/core/design_system/app_button.dart';
import 'package:comic_book_maker/ui/core/design_system/app_sheet.dart';
import 'package:flutter/material.dart';

/// 导入漫画格式选择（底部 Sheet）。
Future<ImportArchiveFormat?> showImportArchiveSheet(BuildContext context) {
  return showAppBottomSheet<ImportArchiveFormat>(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSheetTitle('导入漫画'),
        const SizedBox(height: 12),
        AppButton(
          variant: AppButtonVariant.outline,
          icon: const Icon(Icons.folder_zip_outlined),
          onPressed: () => Navigator.pop(context, ImportArchiveFormat.cbz),
          child: const Text('导入 CBZ'),
        ),
        const SizedBox(height: 8),
        AppButton(
          variant: AppButtonVariant.outline,
          icon: const Icon(Icons.archive_outlined),
          onPressed: () => Navigator.pop(context, ImportArchiveFormat.cbr),
          child: const Text('导入 CBR'),
        ),
        const SizedBox(height: 8),
        AppButton(
          variant: AppButtonVariant.outline,
          icon: const Icon(Icons.menu_book_outlined),
          onPressed: () => Navigator.pop(context, ImportArchiveFormat.epub),
          child: const Text('导入 EPUB'),
        ),
      ],
    ),
  );
}
