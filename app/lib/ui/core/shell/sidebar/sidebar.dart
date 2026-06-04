import 'package:comic_book_maker/ui/core/shell/sidebar/sidebar_theme.dart';
import 'package:flutter/material.dart';

export 'sidebar_menu_button.dart';
export 'sidebar_theme.dart';

/// 侧栏根容器。
class Sidebar extends StatelessWidget {
  const Sidebar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppSidebarTheme.width,
      decoration: const BoxDecoration(
        color: AppSidebarTheme.background,
        border: Border(right: BorderSide(color: AppSidebarTheme.border)),
      ),
      child: SafeArea(child: child),
    );
  }
}

class SidebarHeader extends StatelessWidget {
  const SidebarHeader({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: child,
    );
  }
}

class SidebarContent extends StatelessWidget {
  const SidebarContent({super.key, required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: SingleChildScrollView(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 8),
        child: child,
      ),
    );
  }
}

class SidebarGroup extends StatelessWidget {
  const SidebarGroup({
    super.key,
    this.label,
    required this.child,
  });

  final String? label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: Text(label!, style: AppSidebarTheme.groupLabelStyle),
          ),
        child,
      ],
    );
  }
}

class SidebarMenu extends StatelessWidget {
  const SidebarMenu({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 2),
          children[i],
        ],
      ],
    );
  }
}

class SidebarMenuItem extends StatelessWidget {
  const SidebarMenuItem({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

class SidebarInset extends StatelessWidget {
  const SidebarInset({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppSidebarTheme.background,
      child: child,
    );
  }
}

class SidebarLayout extends StatelessWidget {
  const SidebarLayout({
    super.key,
    required this.sidebar,
    required this.child,
  });

  final Widget sidebar;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppSidebarTheme.background,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          sidebar,
          Expanded(child: SidebarInset(child: child)),
        ],
      ),
    );
  }
}
