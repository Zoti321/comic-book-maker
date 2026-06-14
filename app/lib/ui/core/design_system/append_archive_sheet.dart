import 'package:comic_book_maker/data/repositories/core_gateway.dart';
import 'package:comic_book_maker/ui/core/design_system/app_button.dart';
import 'package:comic_book_maker/ui/core/design_system/app_sheet.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 编辑页追加导入：选择 CBZ、CBR 或 CB7。
Future<ArchiveFormatFrb?> showAppendArchiveSheet(BuildContext context) {
  return showAppBottomSheet<ArchiveFormatFrb>(
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
          onPressed: () => Navigator.pop(context, ArchiveFormatFrb.cbz),
          child: const Text('选择 CBZ'),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          variant: AppButtonVariant.secondary,
          icon: const Icon(LucideIcons.archive),
          onPressed: () => Navigator.pop(context, ArchiveFormatFrb.cbr),
          child: const Text('选择 CBR'),
        ),
        const SizedBox(height: AppSpacing.sm),
        AppButton(
          variant: AppButtonVariant.secondary,
          icon: const Icon(LucideIcons.archive),
          onPressed: () => Navigator.pop(context, ArchiveFormatFrb.cb7),
          child: const Text('选择 CB7'),
        ),
      ],
    ),
  );
}
