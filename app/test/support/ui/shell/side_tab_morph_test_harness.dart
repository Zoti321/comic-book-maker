import 'package:comic_book_maker/domain/models/create_project_draft.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_shell.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/router/app_navigator.dart';
import 'package:comic_book_maker/ui/core/router/app_page_transitions.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:comic_book_maker/ui/core/shell/side_tab_feature_responsive.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:comic_book_maker/ui/features/create_project/create_project_wizard_feature.dart';
import 'package:comic_book_maker/ui/features/create_project/providers/create_project_wizard_session_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// 桌面 chrome 是否参与变形断点（对应 [DesktopWindowConfig.chromeEnabled]）。
enum SideTabMorphChromeMode { off, on }

/// 侧栏 Tab 功能当前呈现形态。
enum SideTabMorphPresentationMode { dialog, page }

/// 驱动 [openSideTabFeature] 与 viewport 变形的测试适配器。
///
/// 直接打开功能并切换宽度，避免整应用 pump 与全局 [appRouter] 栈污染。
class SideTabMorphTestHarness {
  SideTabMorphTestHarness(
    this.tester, {
    this.chrome = SideTabMorphChromeMode.off,
    this.height = defaultHeight,
  });

  final WidgetTester tester;
  final SideTabMorphChromeMode chrome;
  final double height;

  static const compactWidth = 400.0;
  static const wideWidth = 1280.0;
  static const defaultHeight = 800.0;

  static SideTabMorphTestHarness withoutChrome(WidgetTester tester) =>
      SideTabMorphTestHarness(tester);

  static SideTabMorphTestHarness withDesktopChrome(WidgetTester tester) =>
      SideTabMorphTestHarness(tester, chrome: SideTabMorphChromeMode.on);

  var _started = false;

  /// 配置 chrome、设置 viewport、pump 最小路由树并打开功能。
  Future<void> pumpFeatureAt(double width) async {
    _configureChrome();
    _setViewport(width);
    addTearDown(_resetViewport);

    await tester.pumpWidget(_buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(_SideTabMorphOpenHost.openButtonKey));
    await tester.pumpAndSettle();
    _started = true;
  }

  /// 变更 viewport 并等待变形淡出完成。
  Future<void> morphTo(double width) async {
    assert(_started, 'Call pumpFeatureAt before morphTo');
    _setViewport(width);
    await tester.pump();
    await tester.pump(AppDurations.motionNormal);
    await tester.pumpAndSettle();
  }

  void expectPresentation(SideTabMorphPresentationMode mode) {
    switch (mode) {
      case SideTabMorphPresentationMode.dialog:
        expect(find.byType(Dialog), findsOneWidget);
        expect(find.byType(TabBar), findsNothing);
      case SideTabMorphPresentationMode.page:
        expect(find.byType(Dialog), findsNothing);
        expect(find.byType(TabBar), findsOneWidget);
    }
  }

  /// 若向导仍打开则点「取消」，避免用例间残留对话框。
  Future<void> dismissIfOpen() async {
    final cancel = find.text('取消');
    if (cancel.evaluate().isNotEmpty) {
      await tester.tap(cancel);
      await tester.pumpAndSettle();
    }
  }

  void _configureChrome() {
    resetDesktopWindowConfigForTesting();
    desktopWindowConfig = switch (chrome) {
      SideTabMorphChromeMode.off => DesktopWindowConfig.disabled,
      SideTabMorphChromeMode.on =>
        const DesktopWindowConfig(chromeEnabled: true),
    };
  }

  void _setViewport(double width) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
  }

  void _resetViewport() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }

  Widget _buildApp() {
    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const _SideTabMorphOpenHost(),
        ),
        GoRoute(
          path: AppRoutes.projectCreate,
          parentNavigatorKey: rootNavigatorKey,
          pageBuilder: (context, state) => fadeTransitionPage(
            context: context,
            key: state.pageKey,
            child: const CreateProjectWizardFeature(),
          ),
        ),
      ],
    );

    return ProviderScope(
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: router,
        builder: (context, child) {
          final content = child ?? const SizedBox.shrink();
          if (chrome == SideTabMorphChromeMode.on) {
            return DesktopShell(child: content);
          }
          return content;
        },
      ),
    );
  }
}

class _SideTabMorphOpenHost extends StatelessWidget {
  const _SideTabMorphOpenHost();

  static const openButtonKey = Key('side_tab_morph_open');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: FilledButton(
          key: openButtonKey,
          onPressed: () => openSideTabFeature<CreateProjectDraft>(
            context: context,
            compactPageLocation: AppRoutes.projectCreate,
            session: createProjectWizardSideTabSession,
            dialogBuilder: (dialogContext, coordinator) =>
                CreateProjectWizardFeature(
              coordinator: coordinator,
              closeContext: dialogContext,
              form: SideTabMorphForm.dialog,
            ),
          ),
          child: const Text('打开功能'),
        ),
      ),
    );
  }
}
