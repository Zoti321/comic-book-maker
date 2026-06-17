import 'package:comic_book_maker/providers/export_path_provider.dart';
import 'package:comic_book_maker/providers/theme_mode_provider.dart' hide ThemeMode;
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/theme/app_tokens.dart';
import 'package:comic_book_maker/ui/core/widgets/page_header.dart';
import 'package:comic_book_maker/ui/features/project_editor/project_editor_inline_error_banner.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SettingsPage extends HookConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exportPathAsync = ref.watch(exportPathProvider);
    final themeModeAsync = ref.watch(themeModeProvider);
    final savingExportPath = useState(false);
    final padding = contentPaddingOf(context);

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
      final confirmed = await showDialog<bool>(
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

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: PageHeader(title: '设置'),
        ),
        SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: AppLayout.contentMaxWidth,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _SettingsSectionCard(
                      title: '外观',
                      child: themeModeAsync.when(
                        loading: () => const _SettingsPageLoading(
                          message: '正在读取设置…',
                          compact: true,
                        ),
                        error: (error, _) => ProjectEditorInlineErrorBanner(
                          message: '无法读取设置：$error',
                          padding: EdgeInsets.zero,
                        ),
                        data: (mode) => _ThemeModeSelector(
                          selected: mode,
                          onSelected: (selected) {
                            ref
                                .read(themeModeProvider.notifier)
                                .setMode(selected);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _SettingsSectionCard(
                      title: '默认导出目录',
                      child: exportPathAsync.when(
                        loading: () => const _SettingsPageLoading(
                          message: '正在读取设置…',
                          compact: true,
                        ),
                        error: (error, _) => ProjectEditorInlineErrorBanner(
                          message: '无法读取设置：$error',
                          padding: EdgeInsets.zero,
                        ),
                        data: (exportDirectory) {
                          final hasDirectory = exportDirectory != null &&
                              exportDirectory.isNotEmpty;
                          final busy = savingExportPath.value;

                          return _DefaultExportDirectoryRow(
                            path: hasDirectory ? exportDirectory : null,
                            busy: busy,
                            onPick: busy ? null : pickExportDirectory,
                            onClear: hasDirectory && !busy
                                ? confirmClearExportDirectory
                                : null,
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    const _SettingsSectionCard(
                      title: '关于',
                      description: 'Comic Book Maker',
                      child: Text('漫画元数据编辑与 CBZ 导出工具'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  const _ThemeModeSelector({
    required this.selected,
    required this.onSelected,
  });

  final ThemeMode selected;
  final ValueChanged<ThemeMode> onSelected;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<ThemeMode>(
      segments: const [
        ButtonSegment(
          value: ThemeMode.system,
          label: Text('跟随系统'),
          icon: Icon(Icons.brightness_auto_outlined, size: 18),
        ),
        ButtonSegment(
          value: ThemeMode.light,
          label: Text('浅色'),
          icon: Icon(Icons.light_mode_outlined, size: 18),
        ),
        ButtonSegment(
          value: ThemeMode.dark,
          label: Text('深色'),
          icon: Icon(Icons.dark_mode_outlined, size: 18),
        ),
      ],
      selected: {selected},
      onSelectionChanged: (selection) => onSelected(selection.first),
    );
  }
}

void _showSettingsToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message)),
  );
}

class _SettingsPageLoading extends StatelessWidget {
  const _SettingsPageLoading({
    required this.message,
    this.compact = false,
  });

  final String message;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 16 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            if (message.isNotEmpty) ...[
              SizedBox(height: compact ? 12 : 16),
              Text(
                message,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DefaultExportDirectoryRow extends StatelessWidget {
  const _DefaultExportDirectoryRow({
    required this.path,
    required this.busy,
    required this.onPick,
    this.onClear,
  });

  final String? path;
  final bool busy;
  final VoidCallback? onPick;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasDirectory = path != null && path!.isNotEmpty;

    final pathField = DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadius.mdBorder,
        border: Border.all(color: scheme.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Text(
          hasDirectory ? path! : '未设置',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: hasDirectory ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPick,
              borderRadius: AppRadius.mdBorder,
              child: pathField,
            ),
          ),
        ),
        const SizedBox(width: 4),
        IconButton(
          tooltip: hasDirectory ? '更改目录' : '选择目录',
          onPressed: onPick,
          icon: busy
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: scheme.onSurfaceVariant,
                  ),
                )
              : Icon(LucideIcons.folder, size: 18),
        ),
        if (onClear != null)
          IconButton(
            tooltip: '清除目录',
            onPressed: onClear,
            icon: Icon(LucideIcons.trash2, size: 18, color: scheme.error),
          ),
      ],
    );
  }
}

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({
    required this.title,
    this.description,
    required this.child,
  });

  final String title;
  final String? description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
            if (description != null) ...[
              const SizedBox(height: 4),
              Text(
                description!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            SizedBox(height: description != null ? 12 : 8),
            child,
          ],
        ),
      ),
    );
  }
}
