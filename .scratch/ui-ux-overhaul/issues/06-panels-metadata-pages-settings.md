Category: enhancement
Status: done

# Phase 1.6 — 图片 Tab、元数据 Tab、设置页 M3 迁移

## What to build

- **PageThumbnailGrid** / **PagesPanel**：统一 M3 按钮与菜单；封面标识样式与 theme 一致。
- **MetadataPanel**：表单控件、Section chip、保存按钮 design_system 化；逻辑不变。
- **SettingsPage** M3 化。

## Acceptance criteria

- [x] 元数据 widget tests 仍通过（可更新 pump 包裹为 `MaterialApp` 若需要）
- [x] 图片 Tab 空态与有页状态正常
- [x] 设置页可打开且无 Shad

## Blocked by

`.scratch/ui-ux-overhaul/issues/05-project-editor-m3.md`
