Category: enhancement
Status: done

# Phase 1.7 — 移除 shadcn_ui、文档与 widget 回归

## What to build

- 从 **pubspec** 移除 `shadcn_ui`；全仓清理 Shad import。
- 更新 **`docs/agents/flutter-ui.md`**：M3 + design_system 约定、测试 fake 说明。
- 扩展 widget tests：Library 空态、编辑页 Tab（`FakeRustLibApi`）；`metadata_panel_test` 改用 `MaterialApp` 包裹若 ShadApp 已移除。
- 完成 PRD **Phase 1 验收检查表**。

## Acceptance criteria

- [x] `dart analyze` / `flutter test` 通过
- [x] `rg shadcn_ui app` 无结果
- [x] flutter-ui.md 已更新
- [x] PRD 检查表项可在 issue comment 勾选记录

## Blocked by

`.scratch/ui-ux-overhaul/issues/06-panels-metadata-pages-settings.md`
