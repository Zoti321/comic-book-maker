# Core 内嵌 sevenz-rust2 支持 CB7/7Z（Import + Export）

ADR-0008 将 7Z / CB7 标为 Export out-of-scope，UI 中 7Z 容器仅占位禁用。产品需在项目设置中选择 **7Z** 容器，经现有 Export 流程生成 CB7（`.cb7` / `.7z`），且归档须能被本应用 CB7 Import 正确读回；Import 侧亦须支持从外部 `.cb7` / `.7z` 新建 Project 或追加 Page。本 ADR 接管 ADR-0008 第 4 节中 7Z 相关范围决策。

## 决策

### 1. 7Z 读写库

在 Rust Core 编入纯 Rust [`sevenz-rust2`](https://crates.io/crates/sevenz-rust2)（0.20.x 起），全平台统一读写 7z 归档，**不**依赖用户安装 7-Zip、`7z` CLI 或系统 `unar`。

- **解压（Import）与创建（Export）**：共用 `sevenz-rust2`，见 [`docs/third-party/sevenz-rust2.md`](../third-party/sevenz-rust2.md)。
- 与 RAR 路径对比：RAR 因 UnRAR 许可约束采用 `unrar-ng`（读）+ `rars`（写）双库；7Z 无同等分离必要，单库即可。

### 2. 归档内容与压缩策略

与现有 CBZ Export 对齐：

- 根目录 `ComicInfo.xml`（字段映射与 `export_cbz` 一致）。
- 按页序命名的 Page Image 条目（命名规则与 CBZ 相同）。
- 空 Project（零页）拒绝 Export，错误风格与 CBZ 一致。

7Z 写入参数：

- **压缩方法**：逐成员 **LZMA2**（非 solid 归档）。
- **Store 回退**：若单成员压缩后体积不小于原 Page Image，则对该成员 **Store**（不压缩），对齐 CBR Export 策略。
- **密码 / AES 加密**：不支持；Import 与 Export 均拒绝加密归档，错误风格对齐 CBR（「已加密，当前不支持密码保护的归档」类文案）。

Import 路径对齐 CBR：解压到临时目录 → `scan_archive_tree` → stage Page Image。

### 3. API 形态

采用**对称双 API**，不做 `export_comic_archive` 泛化重命名：

- Core 新增 `import_cb7` / `append_cb7` 与 `export_cb7`，与 `import_cbr` / `export_cbr`、`import_cbz` / `export_cbz` 并列。
- Flutter 经 `CoreGateway` 暴露对应 FRB 入口；Export 按 `comicArchiveContainer` 在 `exportCbz` / `exportCbr` / `exportCb7` 间分流；Import 按扩展名推断 CB7（`.cb7` / `.7z` 等价，类比 `.cbz` / `.zip`）。

### 4. 范围

- **在范围**：CB7 / 7Z Import（新建 Project、追加 Page）与 Export；项目设置中 7Z 容器可选（满足第 5 节门槛后）。
- **不在范围**：密码保护 7z 的 Import/Export；solid 7z 归档作为 Export 默认策略；外部 7z 阅读器兼容性作为自动化合并门槛。

### 5. UI 开放门槛

在设置中将 7Z 容器从「占位禁用」改为可选，须满足：

- **硬性门槛**：Core **Export CB7 → Import CB7** 往返自动化测试通过（页数、ComicInfo 关键字段、页图内容一致或等价哈希）。
- **非门槛**：第三方 7z 阅读器抽检——仅列入 PR 手动 Test plan，不阻塞合并。

往返通过前，`comicArchiveContainerSelectable` / `isComicArchiveContainerImplemented` 对 7Z 保持现有占位行为。

扩展名策略（沿用既有 Project 工作流设置）：

| 容器 | 勾选「使用漫画扩展名」 | 不勾选 |
| --- | --- | --- |
| 7Z | `.cb7` | `.7z` |

### 6. 许可立场

| 路径 | 库 | 许可 | 团队立场 |
| --- | --- | --- | --- |
| Import 解压 + Export 创建 | `sevenz-rust2`（纯 Rust） | **Apache-2.0** | 读写同一库；无 RARLab 类专用解压许可；分发方仍须自行完成商店合规审查 |

**分发方责任边界**：本仓库记录第三方许可来源与用途；App Store / 各商店最终合规审查由**产品发布方**负责。

## 备选方案（未采纳）

| 方案 | 原因 |
| --- | --- |
| 依赖系统 / 用户安装 `7z` CLI | 用户环境强依赖，移动端不可行；与 ADR-0008 拒绝 WinRAR CLI 一致 |
| `sevenz-rust` 0.6.x（原版，已停更） | 维护风险高；`sevenz-rust2` 为活跃 fork |
| Import / Export 分库 | 7Z 无 RAR 式许可分离必要；单库更简单 |
| 密码保护 7z（`aes256` feature） | v1 工作量大；与 CBR 不支持加密的行为不一致 |
| Solid LZMA2 归档 | v1 复杂度与兼容性风险高；逐成员已足够 |
| 单一 `export_comic_archive` + Core 内读 workflow | 与现有显式 `export_cbz` / `export_cbr` 风格不一致，迁移面大 |
| 仅 Import 或仅 Export | 与容器 UI、扩展名策略不一致，用户预期断裂 |

## 验收标准摘要（实现切片）

| 切片 | 交付 |
| --- | --- |
| Core + 往返测试 | `import_cb7`、`append_cb7`、`export_cb7`、`sevenz-rust2` 依赖、LZMA2 + Store 回退、`cargo test` Export→Import 往返 |
| 应用 Import 端到端 | FRB `import_cb7`、文件选择器 `.cb7`/`.7z`、新建 Project / 追加 Page |
| 应用 Export 端到端 | FRB `exportCb7`、`CoreGateway` 分流、UI 开放 7Z 可选 |

## 相关

- 修订：[ADR-0008](0008-cbr-export-rars.md)（7Z 范围由本 ADR 接管）
- 第三方：[`docs/third-party/sevenz-rust2.md`](../third-party/sevenz-rust2.md)
- 实现跟踪（本地）：`.scratch/cb7-sevenz-archive/issues/02-core-cb7-import-export-roundtrip.md`、`03-app-cb7-import-e2e.md`、`04-app-cb7-export-ui-unlock.md`
