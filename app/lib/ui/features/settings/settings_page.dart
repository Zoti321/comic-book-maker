import 'package:card_settings_ui/card_settings_ui.dart';
import 'package:comic_book_maker/domain/use_cases/mobile_export_platform.dart';
import 'package:comic_book_maker/providers/export_path_provider.dart';
import 'package:comic_book_maker/providers/theme_mode_provider.dart' hide ThemeMode;
import 'package:comic_book_maker/ui/core/design_system/app_overlay.dart';
import 'package:comic_book_maker/ui/core/feedback/app_snack_bar.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:comic_book_maker/ui/core/widgets/page_header.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_inline_error_banner.dart';
import 'package:comic_book_maker/ui/features/settings/app_update_settings_section.dart';
import 'package:comic_book_maker/ui/features/settings/settings_tile_loading.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportPathAsync = ref.watch(exportPathProvider);
    final themeModeAsync = ref.watch(themeModeProvider);
    final savingExportPath = useState(false);
    final padding = AppSpacing.pagePadding(context);
    final showExportDirectorySettings = !usesMobileExportSaveFile();

    Future<void> pickExportDirectory() async {
      final selected = await FilePicker.platform.getDirectoryPath(
        dialogTitle: '选择默认导出目录',
      );
      if (selected == null || !context.mounted) return;

      savingExportPath.value = true;
      try {
        await ref.read(exportPathProvider.notifier).setDirectory(selected);
      } catch (error) {
        if (context.mounted) {
          _showSettingsToast(context, '更新默认导出目录失败：$error');
        }
      } finally {
        savingExportPath.value = false;
      }
    }

    Future<void> clearExportDirectory() async {
      savingExportPath.value = true;
      try {
        await ref.read(exportPathProvider.notifier).clear();
      } catch (error) {
        if (context.mounted) {
          _showSettingsToast(context, '清除默认导出目录失败：$error');
        }
      } finally {
        savingExportPath.value = false;
      }
    }

    Future<void> confirmClearExportDirectory() async {
      final confirmed = await showAppOverlayDialog<bool>(
        context: context,
        builder: (dialogContext) {
          final scheme = Theme.of(dialogContext).colorScheme;
          return AlertDialog(
            title: const Text('清除默认导出目录'),
            content: const Text(
              '清除后，沿用全局默认目录的项目在导出前需要重新配置目录。',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('取消'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                style: FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                ),
                child: const Text('清除'),
              ),
            ],
          );
        },
      );
      if (confirmed != true || !context.mounted) return;
      await clearExportDirectory();
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
        const SliverToBoxAdapter(
          child: PageHeader(title: '设置'),
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(
            padding.left,
            0,
            padding.right,
            padding.bottom,
          ),
          sliver: SliverToBoxAdapter(
            child: SettingsList(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              contentPadding: EdgeInsets.zero,
              sections: [
                SettingsSection(
                  margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
                  title: const Text('外观'),
                  tiles: [
                    themeModeAsync.when(
                      loading: () => SettingsTile(
                        title: const Text('主题模式'),
                        enabled: false,
                        trailing: const SettingsTileLoadingValue(),
                      ),
                      error: (error, _) => SettingsTile(
                        title: const Text('主题模式'),
                        description: ProjectEditorInlineErrorBanner(
                          message: '无法读取设置：$error',
                          padding: EdgeInsets.zero,
                        ),
                      ),
                      data: (mode) => _ThemeModeNavigationTile(
                        selected: mode,
                        onSelected: (selected) {
                          ref
                              .read(themeModeProvider.notifier)
                              .setMode(selected);
                        },
                      ),
                    ),
                  ],
                ),
                if (showExportDirectorySettings)
                  SettingsSection(
                    margin: const EdgeInsetsDirectional.only(bottom: AppSpacing.md),
                    title: const Text('默认导出目录'),
                    tiles: [
                      exportPathAsync.when(
                        loading: () => SettingsTile(
                          title: const Text('目录'),
                          description: const SettingsTileLoading(),
                        ),
                        error: (error, _) => SettingsTile(
                          title: const Text('目录'),
                          description: ProjectEditorInlineErrorBanner(
                            message: '无法读取设置：$error',
                            padding: EdgeInsets.zero,
                          ),
                        ),
                        data: (exportDirectory) {
                          final hasDirectory = exportDirectory != null &&
                              exportDirectory.isNotEmpty;
                          final busy = savingExportPath.value;

                          return SettingsTile.navigation(
                            title: Text(
                              hasDirectory ? exportDirectory : '未设置',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            enabled: !busy,
                            onPressed:
                                busy ? null : (_) => pickExportDirectory(),
                            trailing: _ExportDirectoryTrailing(
                              busy: busy,
                              showClear: hasDirectory && !busy,
                              onClear: confirmClearExportDirectory,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                const AppUpdateSettingsSection(),
                SettingsSection(
                  margin: EdgeInsetsDirectional.zero,
                  title: const Text('关于'),
                  tiles: [
                    SettingsTile(
                      title: const Text('Comic Book Maker'),
                      description: const Text('漫画元数据编辑与 CBZ 导出工具'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
      ),
    );
  }
}

class _ThemeModeOption {
  const _ThemeModeOption({
    required this.mode,
    required this.label,
  });

  final ThemeMode mode;
  final String label;

  static const values = <_ThemeModeOption>[
    _ThemeModeOption(
      mode: ThemeMode.system,
      label: '跟随系统',
    ),
    _ThemeModeOption(
      mode: ThemeMode.light,
      label: '浅色',
    ),
    _ThemeModeOption(
      mode: ThemeMode.dark,
      label: '深色',
    ),
  ];

  static _ThemeModeOption forMode(ThemeMode mode) {
    return values.firstWhere((option) => option.mode == mode);
  }
}

class _ThemeModeNavigationTile extends AbstractSettingsTile {
  const _ThemeModeNavigationTile({
    required this.selected,
    required this.onSelected,
  });

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onSelected;

  static const _menuMinWidth = 200.0;

  static final _menuStyle = MenuStyle(
    minimumSize: WidgetStatePropertyAll(Size(_menuMinWidth, 0)),
    alignment: AlignmentDirectional.topEnd,
  );

  @override
  Widget build(BuildContext context) {
    return _ThemeModeNavigationTileBody(
      selected: selected,
      onSelected: onSelected,
      menuStyle: _menuStyle,
    );
  }
}

class _ThemeModeNavigationTileBody extends HookWidget {
  const _ThemeModeNavigationTileBody({
    required this.selected,
    required this.onSelected,
    required this.menuStyle,
  });

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onSelected;
  final MenuStyle menuStyle;

  @override
  Widget build(BuildContext context) {
    final menuController = useMemoized(MenuController.new);
    final current = _ThemeModeOption.forMode(selected);

    return MenuAnchor(
      controller: menuController,
      style: menuStyle,
      menuChildren: [
        for (final option in _ThemeModeOption.values)
          MenuItemButton(
            style: MenuItemButton.styleFrom(
              minimumSize: const Size(
                _ThemeModeNavigationTile._menuMinWidth,
                48,
              ),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            onPressed: () {
              onSelected(option.mode);
              menuController.close();
            },
            child: _ThemeModeMenuRow(
              option: option,
              selected: option.mode == selected,
            ),
          ),
      ],
      child: SettingsTile.navigation(
        title: const Text('主题模式'),
        value: Text(current.label),
        onPressed: (_) {
          if (menuController.isOpen) {
            menuController.close();
          } else {
            menuController.open();
          }
        },
      ),
    );
  }
}

class _ThemeModeMenuRow extends StatelessWidget {
  const _ThemeModeMenuRow({
    required this.option,
    required this.selected,
  });

  final _ThemeModeOption option;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Text(
      option.label,
      style: selected
          ? TextStyle(
              fontWeight: FontWeight.w600,
              color: scheme.primary,
            )
          : null,
    );
  }
}

class _ExportDirectoryTrailing extends StatelessWidget {
  const _ExportDirectoryTrailing({
    required this.busy,
    required this.showClear,
    required this.onClear,
  });

  final bool busy;
  final bool showClear;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (busy) {
      return SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: scheme.onSurfaceVariant,
        ),
      );
    }

    if (!showClear) return const SizedBox.shrink();

    return IconButton(
      tooltip: '清除目录',
      visualDensity: VisualDensity.compact,
      onPressed: onClear,
      icon: Icon(Icons.delete_outline, size: 20, color: scheme.error),
    );
  }
}

void _showSettingsToast(BuildContext context, String message) {
  showAppSnackBar(context, message);
}
