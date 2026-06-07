import 'package:comic_book_maker/providers/export_path_provider.dart';
import 'package:comic_book_maker/ui/core/design_system/design_system.dart';
import 'package:comic_book_maker/ui/core/layout/responsive.dart';
import 'package:comic_book_maker/ui/core/theme/app_theme.dart';
import 'package:comic_book_maker/ui/core/widgets/page_header.dart';
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
    final savingExportPath = useState(false);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
          showAppToast(context, '更新默认导出目录失败：$error');
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
          showAppToast(context, '清除默认导出目录失败：$error');
        }
      } finally {
        savingExportPath.value = false;
      }
    }

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: PageHeader(
            title: '设置',
            subtitle: '应用偏好与导出默认值',
          ),
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
                      title: '导出',
                      description: '配置全局默认导出目录（新建项目可沿用）',
                      child: exportPathAsync.when(
                        loading: () => const AppPageLoading(
                          message: '正在读取设置…',
                          compact: true,
                        ),
                        error: (error, _) => AppInlineErrorBanner(
                          message: '无法读取设置：$error',
                          padding: EdgeInsets.zero,
                        ),
                        data: (exportDirectory) {
                          final hasDirectory = exportDirectory != null &&
                              exportDirectory.isNotEmpty;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerLow,
                                  borderRadius: AppRadius.mdBorder,
                                  border: Border.all(color: scheme.outline),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Text(
                                    hasDirectory
                                        ? exportDirectory
                                        : '未设置默认导出目录（沿用全局的项目在 Export 前需在此配置）',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: hasDirectory
                                          ? scheme.onSurface
                                          : scheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  AppButton(
                                    variant: AppButtonVariant.secondary,
                                    onPressed: savingExportPath.value
                                        ? null
                                        : pickExportDirectory,
                                    icon: savingExportPath.value
                                        ? const SizedBox(
                                            width: 16,
                                            height: 16,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            LucideIcons.folder,
                                            size: 18,
                                          ),
                                    child: Text(
                                      hasDirectory ? '更改目录' : '选择目录',
                                    ),
                                  ),
                                  if (hasDirectory)
                                    AppButton(
                                      variant: AppButtonVariant.secondary,
                                      onPressed: savingExportPath.value
                                          ? null
                                          : clearExportDirectory,
                                      child: const Text('清除'),
                                    ),
                                ],
                              ),
                            ],
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

class _SettingsSectionCard extends StatelessWidget {
  const _SettingsSectionCard({
    required this.title,
    required this.description,
    required this.child,
  });

  final String title;
  final String description;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppCard(
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
          const SizedBox(height: 4),
          Text(
            description,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}
