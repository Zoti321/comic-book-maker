import 'package:comic_book_maker/ui/core/design_system/app_dialog.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_dialog_shell.dart';
import 'package:flutter/material.dart';

/// 侧栏 Tab 功能对话框（新建项目、项目属性等）统一壳层。
class SideTabFeatureDialog extends StatelessWidget {
  const SideTabFeatureDialog({
    super.key,
    required this.title,
    required this.tabs,
    required this.selectedIndex,
    required this.onTabSelected,
    required this.body,
    this.actions,
  });

  final String title;
  final List<SideTabDialogTab> tabs;
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;
  final Widget body;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return AppDialog(
      title: title,
      contentPadding: EdgeInsets.zero,
      showDividers: false,
      scrollable: false,
      content: SideTabDialogShell(
        selectedIndex: selectedIndex,
        onTabSelected: onTabSelected,
        tabs: tabs,
        child: body,
      ),
      actions: actions,
    );
  }
}
