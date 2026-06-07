import 'package:comic_book_maker/domain/models/append_archive_format.dart';
import 'package:comic_book_maker/ui/core/design_system/app_button.dart';
import 'package:comic_book_maker/ui/core/design_system/app_sheet.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 编辑页追加导入：选择 CBZ 或 CBR。
Future<AppendArchiveFormat?> showAppendArchiveSheet(BuildContext context) {
  return showAppBottomSheet<AppendArchiveFormat>(
    context: context,
    builder: (context) => Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AppSheetTitle('从漫画压缩包导入'),
        const SizedBox(height: AppSpacing.sm),
        const AppSheetDescription('追加页面到当前项目'),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          variant: AppButtonVariant.secondary,
          icon: const Icon(LucideIcons.folderArchive),
          onPressed: () => Navigator.pop(context, AppendArchiveFormat.cbz),
          child: const Text('选择 CBZ'),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          variant: AppButtonVariant.secondary,
          icon: const Icon(LucideIcons.archive),
          onPressed: () => Navigator.pop(context, AppendArchiveFormat.cbr),
          child: const Text('选择 CBR'),
        ),
      ],
    ),
  );
}
