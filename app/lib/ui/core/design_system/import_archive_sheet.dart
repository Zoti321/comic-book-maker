import 'package:comic_book_maker/domain/models/import_archive_format.dart';
import 'package:comic_book_maker/ui/core/design_system/app_button.dart';
import 'package:comic_book_maker/ui/core/design_system/app_sheet.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 导入漫画格式选择（底部 Sheet）。
Future<ImportArchiveFormat?> showImportArchiveSheet(BuildContext context) {
  return showAppBottomSheet<ImportArchiveFormat>(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSheetTitle('导入漫画'),
        const SizedBox(height: AppSpacing.sm),
        const AppSheetDescription('选择要导入的 Archive Format'),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          variant: AppButtonVariant.outline,
          icon: const Icon(LucideIcons.folderArchive),
          onPressed: () => Navigator.pop(context, ImportArchiveFormat.cbz),
          child: const Text('导入 CBZ'),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          variant: AppButtonVariant.outline,
          icon: const Icon(LucideIcons.archive),
          onPressed: () => Navigator.pop(context, ImportArchiveFormat.cbr),
          child: const Text('导入 CBR'),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          variant: AppButtonVariant.outline,
          icon: const Icon(LucideIcons.bookOpen),
          onPressed: () => Navigator.pop(context, ImportArchiveFormat.epub),
          child: const Text('导入 EPUB'),
        ),
      ],
    ),
  );
}
