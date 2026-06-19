import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// [Navigator.pop] / [GoRouter.pop] 在 Dialog ↔ 全页变形时返回的哨兵，不表示用户取消。
class SideTabFeatureMorphMarker {
  const SideTabFeatureMorphMarker();
}

const sideTabFeatureMorphMarker = SideTabFeatureMorphMarker();

/// 变形目标（由 [SideTabFeatureCoordinator.scheduleMorph] 在 pop 前登记）。
enum SideTabMorphTarget { dialog, page }

/// 当前呈现形态（对话框 / 窄屏全页）。
enum SideTabMorphForm { dialog, page }

/// 变形引擎接缝；由 [SideTabMorphSession] 在 responsive 模块实现。
abstract class SideTabMorphSessionHandle {
  void watch(SideTabMorphForm form);
  void unwatch();
  void evaluate();
  void bindPagePop(VoidCallback pop);
  void bindDialogPop(Future<void> Function() pop);
}

/// 侧栏 Tab 功能（新建项目、项目属性）打开 / 变形会话的共享状态。
class SideTabFeatureCoordinator<T> {
  SideTabFeatureCoordinator({required this.compactPageLocation});

  final String compactPageLocation;

  final _completer = Completer<T?>();
  var tabIndex = 0;
  var _morphing = false;
  SideTabMorphTarget? _pendingMorph;
  final morphingListenable = ValueNotifier(false);

  /// 由 [openSideTabFeature] 注入；断点监听与变形策略的唯一实现。
  SideTabMorphSessionHandle? morphSession;

  Future<T?> get result => _completer.future;
  bool get isCompleted => _completer.isCompleted;
  bool get isMorphing => _morphing;

  void setMorphing(bool value) {
    _morphing = value;
    morphingListenable.value = value;
  }

  void scheduleMorph(SideTabMorphTarget target) => _pendingMorph = target;

  SideTabMorphTarget? takePendingMorph() {
    final target = _pendingMorph;
    _pendingMorph = null;
    return target;
  }

  void complete(T? value) {
    if (!_completer.isCompleted) {
      _completer.complete(value);
    }
  }

  static bool isMorphResult(Object? value) => value is SideTabFeatureMorphMarker;

  /// 从 [sideTabMorphCoordinatorProvider] 读取，不依赖 GoRouter extra。
  static SideTabFeatureCoordinator<T>? of<T>(BuildContext context) {
    final ProviderContainer container;
    try {
      container = ProviderScope.containerOf(context);
    } catch (_) {
      return null;
    }
    final coordinator = container.read(sideTabMorphCoordinatorProvider);
    if (coordinator == null) return null;
    return coordinator as SideTabFeatureCoordinator<T>;
  }
}

/// 当前 [openSideTabFeature] 会话内活跃的变形协调器。
class SideTabMorphScopeNotifier
    extends Notifier<SideTabFeatureCoordinator<dynamic>?> {
  @override
  SideTabFeatureCoordinator<dynamic>? build() => null;

  void bind(SideTabFeatureCoordinator<dynamic> coordinator) {
    state = coordinator;
  }

  void clear() {
    state = null;
  }
}

final sideTabMorphCoordinatorProvider = NotifierProvider<
    SideTabMorphScopeNotifier,
    SideTabFeatureCoordinator<dynamic>?>(
  SideTabMorphScopeNotifier.new,
);
