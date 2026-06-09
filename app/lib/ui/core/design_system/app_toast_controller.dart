import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum AppToastKind { loading, success, error }

/// Toast 上的文字操作（如「打开项目」「查看详情」）。
class AppToastAction {
  const AppToastAction({
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;
}

/// 单条进行中的 Toast；用于在后台任务完成后更新状态。
class AppToastHandle {
  AppToastHandle._(this._controller, this.id);

  final AppToastController _controller;
  final String id;

  void success(String message, {AppToastAction? action}) {
    _controller._completeSuccess(id, message, action);
  }

  void error(String message, {AppToastAction? action}) {
    _controller._completeError(id, message, action);
  }

  void dismiss() => _controller._dismiss(id);
}

@immutable
class AppToastItem {
  const AppToastItem({
    required this.id,
    required this.kind,
    required this.message,
    this.action,
  });

  final String id;
  final AppToastKind kind;
  final String message;
  final AppToastAction? action;
}

/// 全站右下角 Toast 队列（由 [AppToastHost] 渲染）。
class AppToastController extends ChangeNotifier {
  AppToastController._();

  static AppToastController? _instance;

  static AppToastController get instance =>
      _instance ??= AppToastController._();

  @visibleForTesting
  static AppToastController debugInstance(AppToastController controller) {
    _instance = controller;
    return controller;
  }

  @visibleForTesting
  static void debugReset() {
    _instance?.dispose();
    _instance = null;
  }

  final Map<String, _AppToastState> _states = {};
  final List<String> _order = [];
  final Map<String, Timer> _autoDismissTimers = {};
  var _idCounter = 0;

  List<AppToastItem> get items => [
        for (final id in _order)
          if (_states[id] case final state?)
            AppToastItem(
              id: id,
              kind: state.kind,
              message: state.message,
              action: state.action,
            ),
      ];

  AppToastHandle showLoading({required String message}) {
    final id = _nextId();
    _states[id] = _AppToastState(
      id: id,
      kind: AppToastKind.loading,
      message: message,
    );
    _order.add(id);
    notifyListeners();
    return AppToastHandle._(this, id);
  }

  void _completeSuccess(
    String id,
    String message,
    AppToastAction? action,
  ) {
    _complete(id, AppToastKind.success, message, action, autoDismiss: true);
  }

  void _completeError(
    String id,
    String message,
    AppToastAction? action,
  ) {
    _complete(id, AppToastKind.error, message, action, autoDismiss: false);
  }

  void _complete(
    String id,
    AppToastKind kind,
    String message,
    AppToastAction? action, {
    required bool autoDismiss,
  }) {
    final state = _states[id];
    if (state == null) return;

    _cancelAutoDismiss(id);

    if (state.userDismissed) {
      _states.remove(id);
      final newId = _nextId();
      _states[newId] = _AppToastState(
        id: newId,
        kind: kind,
        message: message,
        action: action,
      );
      _order.add(newId);
      if (autoDismiss) {
        _scheduleAutoDismiss(newId, const Duration(seconds: 6));
      }
    } else {
      state.kind = kind;
      state.message = message;
      state.action = action;
      if (autoDismiss) {
        _scheduleAutoDismiss(id, const Duration(seconds: 6));
      }
    }
    notifyListeners();
  }

  void _dismiss(String id) {
    final state = _states[id];
    if (state == null) return;

    _cancelAutoDismiss(id);
    _order.remove(id);

    if (state.kind == AppToastKind.loading) {
      state.userDismissed = true;
    } else {
      _states.remove(id);
    }
    notifyListeners();
  }

  void onDismissPressed(String id) => _dismiss(id);

  String _nextId() => 'toast_${_idCounter++}';

  void _scheduleAutoDismiss(String id, Duration delay) {
    _cancelAutoDismiss(id);
    _autoDismissTimers[id] = Timer(delay, () {
      _autoDismissTimers.remove(id);
      if (_states.containsKey(id)) {
        _dismiss(id);
        _states.remove(id);
        notifyListeners();
      }
    });
  }

  void _cancelAutoDismiss(String id) {
    _autoDismissTimers.remove(id)?.cancel();
  }

  @override
  void dispose() {
    for (final timer in _autoDismissTimers.values) {
      timer.cancel();
    }
    _autoDismissTimers.clear();
    super.dispose();
  }
}

class _AppToastState {
  _AppToastState({
    required this.id,
    required this.kind,
    required this.message,
    this.action,
  });

  final String id;
  AppToastKind kind;
  String message;
  AppToastAction? action;
  bool userDismissed = false;
}
