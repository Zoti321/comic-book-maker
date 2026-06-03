Category: enhancement
Status: done

# Phase 1.2 — AppShell、侧栏与全局 Dialog/Toast

## What to build

- **AppShell**、桌面侧栏、移动底栏改用 design_system + M3 皮肤。
- 迁移 **`app_dialogs` / `app_toast`** 及共享 alert 模式到 design_system。
- 移除本层文件中对 `shadcn_ui` 的直接引用。

## Acceptance criteria

- [x] 侧栏与底栏在桌面 1280×800 下布局正常
- [x] `showAppToast` / `showAppAlertDialog`（或等价 API）行为与迁移前一致
- [x] 壳层相关文件无 Shad import

## Blocked by

`.scratch/ui-ux-overhaul/issues/01-m3-theme-design-system.md`
