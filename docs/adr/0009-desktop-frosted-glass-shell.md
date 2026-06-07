# 桌面整窗原生毛玻璃壳层（已废弃）

**Status:** superseded by [ADR-0010](0010-desktop-borderless-chrome-solid-shell.md)  
**Date:** 2026-06-06

桌面端曾计划采用「无边框窗口 + 自绘顶栏 + 系统级毛玻璃」方案：Windows 使用 DWM Mica/Acrylic，macOS 使用 NSVisualEffectView Vibrancy；Flutter 侧栏与窗口顶栏透明以透出系统模糊，主内容区保留实色 `surface` 以保证可读性。Runner 侧通过 Method Channel 探测并设置系统 backdrop 材质。

## 为何废弃

产品已取消整窗原生毛玻璃 / Vibrancy 需求。原因包括：

1. **可读性与一致性**：系统模糊随壁纸与主题变化，长时间编辑场景下对比度不可控；与 Material 3 `AppTheme` 实色 token 难以统一。
2. **实现与维护成本**：需维护 Windows DWM、macOS Vibrancy 双轨 native 代码、Method Channel 与透明壳层降级链，收益与 MVP 桌面体验目标不匹配。
3. **与首期目标解耦**：无边框窗口与自绘标题栏仍可独立交付；毛玻璃并非 chrome 的必要前提。

## 原决策摘要（仅供历史参考）

- 无边框 HWND / NSWindow + Flutter 透明视图
- Win11 Mica → Win10 Acrylic → 不支持则实色降级
- `DesktopWindowCaption` 负责窗口 chrome；业务 AppBar 不合并
- 侧栏与顶栏透明；主内容 Scaffold 实色

**勿再实现或引用本 ADR 中的毛玻璃路径。** 后续桌面 chrome 见 ADR-0010。
