# 弃用 shadcn_ui，采用 Material 3 + design_system

UI/UX 全面优化 Phase 1 需要统一视觉与组件入口。当前全应用混用 `shadcn_ui` 与 Material 控件，橙色消费向配色与「专业创作工具」目标不符，且 `ShadApp.router` 下无法使用 `ScaffoldMessenger`，反馈路径分裂。

## 决策

1. **根应用**改为 `MaterialApp.router`，保留 `go_router` 与 `ProviderScope`。
2. **主题**由 `AppTheme.light()` 提供 M3 浅色 `ThemeData` + token（`AppSpacing`、`AppRadius`、`AppTypography`）。
3. **新建 `app/lib/ui/design_system/`** 作为对外 UI 原语层（`AppButton`、`AppIconButton`、`AppTextField`、`AppCard`、`AppDialog`、`AppSnackBar` 等）；页面与 feature **禁止** 直接 import `shadcn_ui`。
4. **迁移策略**：壳层递进替换；在 `pubspec` 移除 `shadcn_ui` 之前，`main.dart` 通过 `ShadTheme` 桥接遗留控件。
5. **Phase 1 仅浅色主题**；深色主题另开 ADR/issue。

## 备选

- **继续 ShadApp + enhanceMaterial**：维持双轨组件与 toast 限制，否决。
- **Fluent UI / 自绘全套**：桌面一致性好但迁移成本高，否决。
- **一次性删除 shadcn_ui**：风险过高；分 issue 按模块迁移后移除依赖。

## 后果

- 正面：单一 M3 主题源、可用 `ScaffoldMessenger`、Agent/人类只需学 `design_system` API。
- 负面：迁移完成前仍保留 `shadcn_ui` 依赖与 `legacyShadBridge()`；需更新 `docs/agents/flutter-ui.md`（issue 07）。
- 验收：应用可启动、Library 路由可达；`design_system` 库文档注释约束 Shad 依赖；本 ADR 归档。
