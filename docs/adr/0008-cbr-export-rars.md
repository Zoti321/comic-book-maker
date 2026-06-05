# Core 内嵌 rars 创建 CBR（rar50 / 压缩回退 Store）

ADR-0002 为规避 RAR 压缩侧的许可与专利顾虑，将 Export v1 限定为仅生成 CBZ。产品需在项目设置中选择 **RAR** 容器，经现有 Export 流程生成 CBR（`.cbr` / `.rar`），且归档须能被本应用 CBR Import 正确读回。本 ADR 仅推翻 ADR-0002 中 **Export 写入 RAR** 的限制；CBR Import 仍沿用 ADR-0002 的内置 UnRAR 解压路径。

## 决策

### 1. RAR 创建库

在 Rust Core 编入纯 Rust [`rars`](https://crates.io/crates/rars)（0.2.x），全平台统一创建 RAR 归档，**不**依赖用户安装 WinRAR、`rar` CLI 或系统 `7z`/`unar`。

- **解压（Import）**：继续 [`unrar-ng`](https://crates.io/crates/unrar-ng)，见 ADR-0002 与 [`docs/third-party/unrar.md`](../third-party/unrar.md)。
- **创建（Export）**：`rars`，见 [`docs/third-party/rars.md`](../third-party/rars.md)（实现切片 02 补充）。

两套库职责分离：Import 读、Export 写，不混用 RARLab UnRAR 源码做压缩。

### 2. 归档内容与压缩策略

与现有 CBZ Export 对齐：

- 根目录 `ComicInfo.xml`（字段映射与 `export_cbz` 一致）。
- 按页序命名的 Page Image 条目（命名规则与 CBZ 相同）。
- 空 Project（零页）拒绝 Export，错误风格与 CBZ 一致。

RAR 写入参数：

- **格式版本**：默认 **RAR 5.0**（`rar50`）。
- **压缩**：默认压缩；若单成员压缩后体积不小于原图，则对该成员回退 **Store**（不压缩）。

### 3. API 形态

采用**对称双 API**，不做 `export_comic_archive` 泛化重命名：

- Core 新增 `export_cbr(library, project_id, destination_path)`，与 `export_cbz` 并列。
- Flutter 经 `CoreGateway` 暴露 `exportCbr`；`ArchiveExportRunner` 按 `comicArchiveContainer` 在 `exportCbz` / `exportCbr` 间分流。

### 4. 范围

- **在范围**：RAR / CBR Export。
- **不在范围**：7Z / CB7 Export（UI 继续占位禁用）；外部阅读器兼容性作为自动化合并门槛。

### 5. UI 开放门槛

在设置中将 RAR 容器从「占位禁用」改为可选，须满足：

- **硬性门槛**：Core **Export CBR → Import CBR** 往返自动化测试通过（页数、ComicInfo 关键字段、页图内容一致或等价哈希）。
- **非门槛**：第三方 CBR 阅读器抽检——仅列入 PR 手动 Test plan，不阻塞合并。

往返通过前，`comicArchiveContainerSelectable` / `isComicArchiveContainerImplemented` 对 RAR 保持现有占位行为。

### 6. 许可与专利立场

| 路径 | 库 | 许可 | 团队立场 |
| --- | --- | --- | --- |
| Import 解压 | `unrar-ng` + RARLab UnRAR 源码 | UnRAR 专用许可（见 [unrar.md](../third-party/unrar.md)） | 仅解压、不创建 RAR；分发方须遵守 RARLab 条款 |
| Export 创建 | `rars`（纯 Rust） | **MIT OR Apache-2.0** | 创建侧不静态链接 RARLab UnRAR；`rars` 为独立实现，降低「不得开发 RAR 压缩工具」类条款对 Export 的约束 |

**分发方责任边界**：本仓库记录第三方许可来源与用途分工；App Store / 各商店最终合规审查由**产品发布方**负责。若监管或商店政策变化，可回退为仅 CBZ Export 而不影响 Import 路径。

## 备选方案（未采纳）

| 方案 | 原因 |
| --- | --- |
| 依赖 WinRAR / `rar` CLI | 用户环境强依赖，移动端不可行 |
| 继续 Export 仅 CBZ | 无法满足 RAR 容器设置与 CBR 发布需求 |
| 单一 `export_comic_archive` + Core 内读 workflow | 与现有显式 `export_cbz` / `export_epub` 风格不一致，迁移面大 |
| 桌面内置压缩、移动端不支持 | 平台能力不一致 |

## 验收标准摘要（实现切片）

| 切片 | 交付 |
| --- | --- |
| Core + 往返测试 | `export_cbr`、`rars` 依赖、rar50 + Store 回退、`cargo test` Export→Import 往返 |
| 应用端到端 | FRB `exportCbr`、`ArchiveExportRunner` 分流、UI 开放 RAR 可选 |

## 相关

- 修订：[ADR-0002](0002-cbr-import-unrar.md)（Import 不变；移除 Export 仅 CBZ 限制）
- 第三方：[`docs/third-party/unrar.md`](../third-party/unrar.md)、[`docs/third-party/rars.md`](../third-party/rars.md)
- 实现跟踪（本地）：`.scratch/rar-cbr-export/issues/02-core-export-cbr-roundtrip.md`、`03-app-cbr-export-e2e.md`
