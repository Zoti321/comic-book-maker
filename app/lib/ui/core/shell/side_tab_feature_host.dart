import 'package:comic_book_maker/ui/core/shell/side_tab_dialog_shell.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_feature_dialog.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_feature_page.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_feature_responsive.dart';
import 'package:flutter/material.dart';

/// 侧栏 Tab 功能的声明式定义：标题、Tab 与内容构建器。
class SideTabFeatureSpec {
  const SideTabFeatureSpec({
    required this.title,
    required this.tabs,
    required this.tabBodyBuilder,
    this.loading,
  });

  final String title;
  final List<SideTabDialogTab> tabs;
  final Widget Function(BuildContext context, int tabIndex) tabBodyBuilder;

  /// 非 null 时替代主内容（如加载中占位）。
  final Widget? loading;
}

/// 按 [SideTabMorphForm] 呈现对话框或全页，统一 Tab 与操作区接线。
class SideTabFeatureHost extends StatelessWidget {
  const SideTabFeatureHost({
    super.key,
    required this.spec,
    required this.form,
    required this.tabIndex,
    required this.onTabSelected,
    required this.dialogActions,
    this.pageBottomBar,
  });

  final SideTabFeatureSpec spec;
  final SideTabMorphForm form;
  final int tabIndex;
  final ValueChanged<int> onTabSelected;
  final List<Widget> dialogActions;
  final Widget? pageBottomBar;

  @override
  Widget build(BuildContext context) {
    if (spec.loading != null) {
      return spec.loading!;
    }

    return switch (form) {
      SideTabMorphForm.dialog => SideTabFeatureDialog(
          title: spec.title,
          tabs: spec.tabs,
          selectedIndex: tabIndex,
          onTabSelected: onTabSelected,
          body: spec.tabBodyBuilder(context, tabIndex),
          actions: dialogActions,
        ),
      SideTabMorphForm.page => SideTabFeaturePage(
          title: spec.title,
          tabs: spec.tabs,
          initialTabIndex: tabIndex,
          onTabSelected: onTabSelected,
          tabBodies: [
            for (var i = 0; i < spec.tabs.length; i++)
              sideTabFeaturePageTabBody(spec.tabBodyBuilder(context, i)),
          ],
          bottomNavigationBar: pageBottomBar,
        ),
    };
  }
}
