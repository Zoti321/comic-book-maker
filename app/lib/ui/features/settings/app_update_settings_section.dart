import 'package:card_settings_ui/card_settings_ui.dart';
import 'package:comic_book_maker/providers/app_version_provider.dart';
import 'package:comic_book_maker/providers/auto_update_provider.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_inline_error_banner.dart';
import 'package:comic_book_maker/ui/features/settings/app_update_check_flow.dart';
import 'package:comic_book_maker/ui/features/settings/app_update_platform.dart';
import 'package:comic_book_maker/ui/features/settings/settings_tile_loading.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class AppUpdateSettingsSection extends AbstractSettingsSection {
  const AppUpdateSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return const _AppUpdateSettingsSectionBody();
  }
}

class _AppUpdateSettingsSectionBody extends HookConsumerWidget {
  const _AppUpdateSettingsSectionBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final autoUpdateAsync = ref.watch(autoUpdateProvider);
    final appVersionAsync = ref.watch(appVersionProvider);
    final checkingUpdate = useState(false);
    final isSupported = isAppUpdateSupportedPlatform();

    return SettingsSection(
      margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
      title: const Text('应用更新'),
      tiles: [
        autoUpdateAsync.when(
          loading: () => SettingsTile(
            title: const Text('自动更新'),
            enabled: false,
            trailing: const SettingsTileLoadingValue(),
          ),
          error: (error, _) => SettingsTile(
            title: const Text('自动更新'),
            description: ProjectEditorInlineErrorBanner(
              message: '无法读取设置：$error',
              padding: EdgeInsets.zero,
            ),
          ),
          data: (enabled) => SettingsTile.switchTile(
            title: const Text('自动更新'),
            initialValue: isSupported ? enabled : false,
            enabled: isSupported,
            onToggle: isSupported
                ? (value) {
                    if (value == null) return;
                    ref.read(autoUpdateProvider.notifier).setEnabled(value);
                  }
                : (_) {},
          ),
        ),
        appVersionAsync.when(
          loading: () => SettingsTile(
            title: const Text('检查更新'),
            enabled: false,
            trailing: const SettingsTileLoadingValue(),
          ),
          error: (error, _) => SettingsTile(
            title: const Text('检查更新'),
            description: ProjectEditorInlineErrorBanner(
              message: '无法读取版本：$error',
              padding: EdgeInsets.zero,
            ),
          ),
          data: (version) => _CheckUpdateSettingsTile(
            version: version,
            checking: checkingUpdate.value,
            enabled: isSupported && !checkingUpdate.value,
            onPressed: isSupported
                ? () async {
                    checkingUpdate.value = true;
                    try {
                      await runManualAppUpdateCheck(
                        context: context,
                        ref: ref,
                        currentVersion: version,
                      );
                    } finally {
                      checkingUpdate.value = false;
                    }
                  }
                : null,
          ),
        ),
      ],
    );
  }
}

class _CheckUpdateSettingsTile extends AbstractSettingsTile {
  const _CheckUpdateSettingsTile({
    required this.version,
    required this.checking,
    required this.enabled,
    required this.onPressed,
  });

  final String version;
  final bool checking;
  final bool enabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return SettingsTile(
      title: const Text('检查更新'),
      enabled: enabled,
      onPressed: onPressed == null ? null : (_) => onPressed!(),
      trailing: checking
          ? const SettingsTileLoadingValue()
          : Text(
              '当前版本 $version',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
    );
  }
}
