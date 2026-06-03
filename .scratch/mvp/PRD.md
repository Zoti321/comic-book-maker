# MVP：Comic Book Maker

## 概述

跨平台（桌面 + 移动端，无 Web）电子漫画制作与编辑工具。用户在 Library 中管理 Project，通过 Import 或 Create Project 建立工作区，编辑 Page 与 Metadata 后 Export 为 Archive Format。

## v1 范围

| 能力       | 范围                                             |
| ---------- | ------------------------------------------------ |
| Import     | CBZ、CBR                                         |
| Export     | CBZ                                              |
| Page Image | jpg/jpeg、png、webp、gif、avif、bmp，原格式进出  |
| 编辑       | Page Operation（增删、排序、替换），无像素编辑   |
| 持久化     | 全局 Library Database + 应用沙盒 Project Storage |
| 架构       | Flutter `app/` + Rust `core/`，FRB 通信          |

## 不在 v1

- EPUB、PDF Import/Export
- 像素级图像编辑
- Project Bundle（`.cbm`）
- 删除 Project（后续 slice）
- Web 端

## 领域文档

- 术语：`CONTEXT.md`
- 架构决策：`docs/adr/0001`–`0004`

## 实现切片

见 `.scratch/mvp/issues/`（01–10，按依赖顺序执行）。
