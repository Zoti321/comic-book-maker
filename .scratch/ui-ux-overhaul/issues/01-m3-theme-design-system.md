Category: enhancement
Status: done

# Phase 1.1 — M3 浅色主题与 design_system 基础

## What to build

- 新建 **design_system** 模块：首批原语（`AppButton`、`AppIconButton`、`AppTextField`、`AppCard`、`AppDialog` 骨架、`AppSnackBar`）。
- **AppTheme** 改为 M3 浅色 `ThemeData` + token（spacing、radius、typography）；专业工具风中性色 + 克制强调色。
- 根 widget：**`MaterialApp.router`** 替换 `ShadApp.router`（保留 `go_router`、locale）。
- 撰写 **ADR**：弃用 `shadcn_ui`，采用 M3 + design_system。

## Acceptance criteria

- [x] 应用可启动，路由仍可进入 Library
- [x] design_system 文档注释说明页面不得直接依赖 Shad
- [x] ADR 已合并
- [x] 本 issue 不要求移除 `shadcn_ui` 依赖（见 07）

## Blocked by

None
