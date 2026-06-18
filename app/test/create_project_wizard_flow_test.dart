import 'package:comic_book_maker/main.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/router/app_routes.dart';
import 'package:comic_book_maker/ui/core/router/app_router.dart';
import 'package:comic_book_maker/ui/core/shell/app_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/frb/rust_fake.dart';
import 'support/provider/core_gateway_scope.dart';
import 'support/ui/shell/side_tab_morph_test_harness.dart';

void main() {
  rustTestSetUpAll();

  setUpAll(() {
    SharedPreferences.setMockInitialValues({});
  });

  setUp(() {
    resetDesktopWindowConfigForTesting();
    desktopWindowConfig = DesktopWindowConfig.disabled;
    appRouter.go(AppRoutes.projects);
  });

  Future<void> pumpLibrary(
    WidgetTester tester, {
    required Size surfaceSize,
  }) async {
    tester.view.physicalSize = surfaceSize;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      coreGatewayScope(
        gateway: InMemoryCoreGateway.emptyLibrary(),
        child: const ComicBookMakerApp(),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> dismissOpenWizardIfPresent(WidgetTester tester) async {
    await SideTabMorphTestHarness.withoutChrome(tester).dismissIfOpen();
  }

  group('runCreateProjectWizard routing', () {
    testWidgets('compact viewport opens full page instead of dialog', (
      tester,
    ) async {
      await pumpLibrary(tester, surfaceSize: const Size(400, 800));

      expect(find.byType(AppNavigationBar), findsOneWidget);

      await tester.tap(find.byTooltip('新建项目'));
      await tester.pumpAndSettle();

      SideTabMorphTestHarness.withoutChrome(tester)
          .expectPresentation(SideTabMorphPresentationMode.page);
      expect(find.text('新建项目'), findsWidgets);
      expect(find.text('取消'), findsOneWidget);
      expect(find.text('创建'), findsOneWidget);
    });

    testWidgets('wide viewport opens dialog instead of full page route', (
      tester,
    ) async {
      await pumpLibrary(tester, surfaceSize: const Size(1280, 900));

      expect(find.byType(AppNavigationBar), findsNothing);

      await tester.tap(find.byTooltip('新建项目'));
      await tester.pumpAndSettle();

      SideTabMorphTestHarness.withoutChrome(tester)
          .expectPresentation(SideTabMorphPresentationMode.dialog);
      expect(find.widgetWithText(FilledButton, '创建'), findsOneWidget);

      await dismissOpenWizardIfPresent(tester);
    });

    testWidgets('wide dialog morphs to compact page when viewport shrinks', (
      tester,
    ) async {
      final harness = SideTabMorphTestHarness.withoutChrome(tester);
      await harness.pumpFeatureAt(SideTabMorphTestHarness.wideWidth);
      harness.expectPresentation(SideTabMorphPresentationMode.dialog);

      await harness.morphTo(SideTabMorphTestHarness.compactWidth);
      harness.expectPresentation(SideTabMorphPresentationMode.page);
    });

    testWidgets('compact page morphs to wide dialog when viewport grows', (
      tester,
    ) async {
      final harness = SideTabMorphTestHarness.withoutChrome(tester);
      await harness.pumpFeatureAt(SideTabMorphTestHarness.compactWidth);
      harness.expectPresentation(SideTabMorphPresentationMode.page);

      await harness.morphTo(SideTabMorphTestHarness.wideWidth);
      harness.expectPresentation(SideTabMorphPresentationMode.dialog);
    });

    testWidgets('wide dialog morphs to page then back to dialog on round trip', (
      tester,
    ) async {
      final harness = SideTabMorphTestHarness.withoutChrome(tester);
      await harness.pumpFeatureAt(SideTabMorphTestHarness.wideWidth);
      harness.expectPresentation(SideTabMorphPresentationMode.dialog);

      await harness.morphTo(SideTabMorphTestHarness.compactWidth);
      harness.expectPresentation(SideTabMorphPresentationMode.page);

      await harness.morphTo(SideTabMorphTestHarness.wideWidth);
      harness.expectPresentation(SideTabMorphPresentationMode.dialog);
      expect(find.text('尚未选择'), findsOneWidget);
    });
  });

  group('runCreateProjectWizard routing with desktop chrome', () {
    testWidgets('compact page morphs to dialog when viewport grows', (
      tester,
    ) async {
      final harness = SideTabMorphTestHarness.withDesktopChrome(tester);
      await harness.pumpFeatureAt(SideTabMorphTestHarness.compactWidth);
      harness.expectPresentation(SideTabMorphPresentationMode.page);

      await harness.morphTo(SideTabMorphTestHarness.wideWidth);
      harness.expectPresentation(SideTabMorphPresentationMode.dialog);
    });
  });
}
