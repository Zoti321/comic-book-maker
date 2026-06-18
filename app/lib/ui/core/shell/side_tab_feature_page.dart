import 'package:comic_book_maker/ui/core/shell/side_tab_dialog_shell.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// 窄屏全页：AppBar + 可滚动 TabBar + TabBarView。
class SideTabFeaturePage extends HookWidget {
  const SideTabFeaturePage({
    super.key,
    required this.title,
    required this.tabs,
    required this.tabBodies,
    this.bottomNavigationBar,
  });

  final String title;
  final List<SideTabDialogTab> tabs;
  final List<Widget> tabBodies;
  final Widget? bottomNavigationBar;

  @override
  Widget build(BuildContext context) {
    final tabController = useTabController(initialLength: tabs.length);

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        bottom: TabBar(
          controller: tabController,
          isScrollable: true,
          tabs: [
            for (final tab in tabs)
              Tab(icon: Icon(tab.icon), text: tab.label),
          ],
        ),
      ),
      body: TabBarView(
        controller: tabController,
        children: tabBodies,
      ),
      bottomNavigationBar: bottomNavigationBar,
    );
  }
}

/// 全页 Tab 内容区标准内边距 + 滚动。
Widget sideTabFeaturePageTabBody(Widget child) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(AppSpacing.md),
    child: child,
  );
}

/// 新建向导等场景：底栏取消 / 主操作。
Widget sideTabFeaturePageActionBar({
  required VoidCallback onCancel,
  required String primaryLabel,
  required VoidCallback? onPrimary,
}) {
  return SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.md,
      ),
      child: Row(
        children: [
          TextButton(
            onPressed: onCancel,
            child: const Text('取消'),
          ),
          const Spacer(),
          FilledButton(
            onPressed: onPrimary,
            child: Text(primaryLabel),
          ),
        ],
      ),
    ),
  );
}
