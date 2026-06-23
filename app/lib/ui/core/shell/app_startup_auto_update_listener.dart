import 'package:flutter/material.dart';
import 'package:comic_book_maker/ui/features/settings/app_update_startup_check.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// 冷启动后在首帧之后触发一次自动更新检查（桌面端、且用户开启自动更新）。
class AppStartupAutoUpdateListener extends HookConsumerWidget {
  const AppStartupAutoUpdateListener({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useEffect(() {
      var cancelled = false;

      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (cancelled) {
          return;
        }
        await runStartupAppUpdateCheck(ref: ref);
      });

      return () {
        cancelled = true;
      };
    }, const []);

    return child;
  }
}
