import 'package:comic_book_maker/ui/core/layout/desktop_window.dart';
import 'package:comic_book_maker/ui/core/layout/desktop_window_config.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window_manager/window_manager.dart';

void main() {
  setUp(resetDesktopWindowConfigForTesting);

  test('isDesktopTargetPlatform is true for desktop OS targets', () {
    expect(isDesktopTargetPlatform(TargetPlatform.windows), isTrue);
    expect(isDesktopTargetPlatform(TargetPlatform.macOS), isTrue);
    expect(isDesktopTargetPlatform(TargetPlatform.linux), isTrue);
    expect(isDesktopTargetPlatform(TargetPlatform.android), isFalse);
    expect(isDesktopTargetPlatform(TargetPlatform.iOS), isFalse);
  });

  test('configureDesktopWindow enables chrome when all steps succeed', () async {
    final manager = _RecordingDesktopWindowManager();

    await configureDesktopWindow(
      managerOverride: manager,
      platformOverride: TargetPlatform.windows,
    );

    expect(desktopWindowConfig.chromeEnabled, isTrue);
    expect(manager.calls, [
      _DesktopWindowCall.ensureInitialized,
      _DesktopWindowCall.setMinimumSize,
      _DesktopWindowCall.setTitleBarStyleHidden,
    ]);
    expect(manager.lastMinimumSize, appDesktopMinWindowSize);
  });

  test('configureDesktopWindow disables chrome when ensureInitialized fails',
      () async {
    final manager = _RecordingDesktopWindowManager(
      failOn: _DesktopWindowCall.ensureInitialized,
    );

    await configureDesktopWindow(
      managerOverride: manager,
      platformOverride: TargetPlatform.macOS,
    );

    expect(desktopWindowConfig.chromeEnabled, isFalse);
    expect(manager.calls, [_DesktopWindowCall.ensureInitialized]);
  });

  test('configureDesktopWindow disables chrome when setTitleBarStyle fails',
      () async {
    final manager = _RecordingDesktopWindowManager(
      failOn: _DesktopWindowCall.setTitleBarStyleHidden,
    );

    await configureDesktopWindow(
      managerOverride: manager,
      platformOverride: TargetPlatform.linux,
    );

    expect(desktopWindowConfig.chromeEnabled, isFalse);
    expect(manager.calls, [
      _DesktopWindowCall.ensureInitialized,
      _DesktopWindowCall.setMinimumSize,
      _DesktopWindowCall.setTitleBarStyleHidden,
    ]);
  });

  test('configureDesktopWindow skips window_manager on mobile platforms',
      () async {
    final manager = _RecordingDesktopWindowManager();

    await configureDesktopWindow(
      managerOverride: manager,
      platformOverride: TargetPlatform.android,
    );

    expect(desktopWindowConfig.chromeEnabled, isFalse);
    expect(manager.calls, isEmpty);
  });
}

enum _DesktopWindowCall {
  ensureInitialized,
  setMinimumSize,
  setTitleBarStyleHidden,
}

class _RecordingDesktopWindowManager implements DesktopWindowManagerClient {
  _RecordingDesktopWindowManager({this.failOn});

  final _DesktopWindowCall? failOn;
  final calls = <_DesktopWindowCall>[];
  Size? lastMinimumSize;

  void _maybeFail(_DesktopWindowCall step) {
    if (failOn == step) {
      throw StateError('simulated failure at $step');
    }
  }

  @override
  Future<void> ensureInitialized() async {
    calls.add(_DesktopWindowCall.ensureInitialized);
    _maybeFail(_DesktopWindowCall.ensureInitialized);
  }

  @override
  Future<void> setMinimumSize(Size size) async {
    calls.add(_DesktopWindowCall.setMinimumSize);
    lastMinimumSize = size;
    _maybeFail(_DesktopWindowCall.setMinimumSize);
  }

  @override
  Future<void> setTitleBarStyle(TitleBarStyle style) async {
    calls.add(_DesktopWindowCall.setTitleBarStyleHidden);
    expect(style, TitleBarStyle.hidden);
    _maybeFail(_DesktopWindowCall.setTitleBarStyleHidden);
  }
}
