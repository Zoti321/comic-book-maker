import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 侧栏 Tab 功能打开 / 关闭时的会话生命周期接缝。
///
/// 各功能通过 adapter（如草稿 session、Tab session）实现 [onOpen] / [onClose]，
/// 由 [openSideTabFeature] 统一调用。
class SideTabFeatureSession {
  const SideTabFeatureSession({
    required this.onOpen,
    required this.onClose,
  });

  final void Function(ProviderContainer container) onOpen;
  final void Function(ProviderContainer container) onClose;

  /// 打开时 [reset]，关闭时 [invalidate] 关联的 Riverpod 状态。
  factory SideTabFeatureSession.resettable({
    required void Function(ProviderContainer container) reset,
    required void Function(ProviderContainer container) invalidate,
  }) {
    return SideTabFeatureSession(
      onOpen: reset,
      onClose: invalidate,
    );
  }
}
