Category: enhancement
Status: done

# Phase 2.1 — Project 顶栏交互重组

## What to build

- 按 PRD Phase 2 批次 1：**Project 顶栏**动作分组（Export、追加导入、返回、设置相关）。
- 与 `export_format` / `inferred_import_kind` 联动禁用与说明文案。
- 使用 design_system；不引入 Shad。

## Acceptance criteria

- [x] 桌面宽屏下主操作 ≤3 个视觉焦点，次要收进 menu/overflow
- [x] PDF 占位 Export 仍不可执行且有说明
- [x] 无 regression：Export / Append 仍可触发原 Core 流程

## Blocked by

`.scratch/ui-ux-overhaul/issues/07-remove-shadcn-widget-tests.md`
