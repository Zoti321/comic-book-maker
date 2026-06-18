import 'package:comic_book_maker/ui/core/shell/side_tab_dialog_shell.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final shellHeight = constraints.maxHeight.isFinite
            ? constraints.maxHeight.clamp(280.0, 440.0)
            : 440.0;

        return _MaterialSideTabDialog(
          title: title,
          contentPadding: EdgeInsets.zero,
          content: SizedBox(
            height: shellHeight,
            child: SideTabDialogShell(
              height: shellHeight,
              selectedIndex: selectedIndex,
              onTabSelected: onTabSelected,
              tabs: tabs,
              child: body,
            ),
          ),
          actions: actions,
        );
      },
    );
  }
}

class _MaterialSideTabDialog extends StatelessWidget {
  const _MaterialSideTabDialog({
    required this.title,
    required this.content,
    this.actions,
    this.contentPadding = const EdgeInsets.fromLTRB(24, 16, 24, 16),
  });

  final String title;
  final Widget content;
  final List<Widget>? actions;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final actionWidgets = actions;
    final hasActions = actionWidgets != null && actionWidgets.isNotEmpty;
    final maxHeight = MediaQuery.sizeOf(context).height - 48;

    return Dialog(
      backgroundColor: scheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.lgBorder,
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(minWidth: 280, maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ),
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                padding: hasActions
                    ? contentPadding
                    : contentPadding.add(const EdgeInsets.only(bottom: 8)),
                child: SizedBox(width: double.maxFinite, child: content),
              ),
            ),
            if (hasActions) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    for (var i = 0; i < actionWidgets.length; i++) ...[
                      if (i > 0) const SizedBox(width: AppSpacing.sm),
                      actionWidgets[i],
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
