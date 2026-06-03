Category: enhancement
Status: done

# Phase 1.5 — Project 编辑页与设置条 M3 迁移

## What to build

- **ProjectEditorPage** 壳层、**ShadTabs** 替换为 M3 等价 Tab（`TabBar` / 自封装 segmented control，保持图片/元数据两 Tab）。
- **ProjectEditorSettingsBar** M3 化。
- Phase 1 **仅视觉**；顶栏动作分组留 Phase 2 issue 08。

## Acceptance criteria

- [x] 可切换图片 / 元数据 Tab，无 layout 崩溃（保留 bounded height 策略或等价方案）
- [x] 设置条（export format 等）使用 design_system
- [x] 编辑页壳层无 Shad import

## Blocked by

`.scratch/ui-ux-overhaul/issues/04-library-page-m3.md`
