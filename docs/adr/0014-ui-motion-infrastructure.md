# UI 动效基础设施与克制工具风约定

**Status:** accepted  
**Date:** 2026-06-19  
**Parent PRD:** [GitHub #13](https://github.com/Zoti321/comic-book-maker/issues/13)  
**Related:** [ADR-0013](0013-material-you-migration.md)（Material You 与专业工具体验）

Comic Book Maker 是长时间创作工具，动效应服务**方向感与状态反馈**，避免装饰性动画干扰编辑流。本 ADR 记录 [PRD #13](https://github.com/Zoti321/comic-book-maker/issues/13) 的基础层决策与依赖选型。

## 决策

### 1. 第三方库

- **主库**：`flutter_animate`（^4.5.2）— 列表/浮层/组件级 fade、slide、stagger 等。
- **辅库**：`animated_text_kit`（^4.3.0）— **仅**用于少数空态/引导短标题（如漫画库空态），禁止用于表单与元数据编辑区。
- 路由级过渡仍用 Flutter `CustomTransitionPage` + `FadeTransition`（不依赖第三方 page transition 包）。

### 2. Token 与封装

- 时长：`AppDurations.motionFast` / `motionNormal` / `motionSlow` / `pageTransition`（`app/lib/ui/core/theme/app_tokens.dart`）。
- 曲线：`AppCurves.standard` / `enter` / `exit`（同文件）。
- 门禁：`AppMotion`（`app/lib/ui/core/theme/app_motion.dart`）统一读取 `MediaQuery.disableAnimations`；为 true 时 `Duration.zero` 或跳过动效。
- **禁止**在 feature 中散落 magic number 时长/曲线；新动效须走 token + `AppMotion`。

### 3. 路由

- 全屏路由（编辑页、新建向导、项目属性等）：**对称纯 fade**，时长 `AppDurations.pageTransition`（200ms），曲线 `AppCurves.standard`；经 `fadeTransitionPage` + `AppMotion`。
- 壳内 Tab（漫画库 ↔ 设置）：**无过渡**（`NoTransitionPage`），保持即时切换。

### 4. 调性（后续 slice 须遵守）

- 克制工具风：优先导航、列表入场、空态、Dialog/Sheet；避免 hover 装饰与编辑区文字动效。
- SnackBar 保持 M3 默认；内联 loading 首版不增强（见 PRD #13）。

## 备选

- **纯 Flutter 内置 Animation API，不引入第三方**：样板代码多，否决。
- **全 app 统一 slide 路由**：与桌面无边框壳层气质不符，否决（首版纯 fade）。

## 后果

- 正面：动效可测试、可无障碍关闭；与 Material You 并存；后续 slice（#15/#16）可复用同一层。
- 负面：新增依赖与 agent 需学习 `AppMotion` / `flutter_animate` 约定。
- 验收：`flutter pub get` 成功；`app_page_transitions_test` 通过；`docs/agents/flutter-ui.md` 与代码一致。

**实现追踪：** GitHub #14（基础层 + 路由 fade）；#15（漫画库）；#16（Dialog/Sheet scale+fade，`showAppOverlayDialog` / `showAppBottomSheet`）。
