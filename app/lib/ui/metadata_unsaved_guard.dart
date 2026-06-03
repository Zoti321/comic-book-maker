import 'package:comic_book_maker/ui/design_system/design_system.dart';
import 'package:flutter/material.dart';

/// 离开元数据 Tab 或编辑页时，确认是否放弃未保存修改。
Future<bool> confirmDiscardMetadataEdits(BuildContext context) async {
  final result = await showAppConfirmDialog(
    context: context,
    title: '放弃未保存的更改？',
    description: const Text('元数据有未保存的修改，离开后将丢失。'),
    confirmLabel: '放弃更改',
    cancelLabel: '继续编辑',
    destructive: true,
  );
  return result == true;
}
