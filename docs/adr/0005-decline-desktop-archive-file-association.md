# 不做桌面 Archive 文件关联（.cbz / .cbr 双击打开）

**Status:** accepted（取消需求）  
**Date:** 2026-06-01

在 Windows / macOS 注册 `.cbz`、`.cbr` 文件类型，双击系统文件时启动应用并走 Import，已明确不做。用户通过 Library 内 Import 入口完成导入即可；不实现 OS 级文件关联、启动参数与「从外部文件唤起」的专用流程。

**相关：** Library 壳层、应用内 Import 入口与列表排序已实现；仅 OS 级文件关联按本 ADR 不做。
