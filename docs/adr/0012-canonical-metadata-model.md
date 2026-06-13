# Canonical 元数据模型与 Archive Format 映射边界

早期 `projects` 表按 ComicInfo 字段扩列（`writer`、`issue_number`、`year`/`month`/`day`、多角色分列等），Flutter 元数据 Tab 亦按 Export 格式切换 ComicInfo / OPF 字段表；Import 还持久化 `import_metadata_snapshot` 原始 XML。该做法使应用内模型与档案格式耦合、迁移与测试成本高，且 UI 与 Core 字段命名不一致（`summary` vs 描述 Tab）。

本 ADR 与 ADR-0003（全局 `library.db`）、ADR-0007（Flutter 分层）兼容；Implementation 见 `core/src/db/migrate.rs`、`core/src/metadata_schema/`、各 `import/*` / `export_*` 模块。

## 决策

### 1. Canonical 字段（Library Database）

**可编辑、持久化**（`projects` 表）：

| 字段 | 说明 |
| --- | --- |
| `title` | 必填 |
| `series`, `number`, `series_count` | TEXT；期号可为非整数（如 `1A`） |
| `published_date` | TEXT NULL；分级 ISO：`YYYY` / `YYYY-MM` / `YYYY-MM-DD` |
| `language_iso` | 如 `zh-CN` |
| `author` | 单一字符串；多人以 `, ` 分隔（Import 拼接、Export 再拆分） |
| `tags`, `characters` | 逗号分隔；Core 归一化时去除逗号后多余空格 |
| `age_rating` | 预设 + 自定义 |
| `description` | 长文本摘要 / 简介 |

**系统字段**：

| 字段 | 持久化 | 编辑位置 |
| --- | --- | --- |
| `cover_page_index` | 是 | 图片 Tab（元数据 Tab 只读） |
| `page_count` | **否**（运行时由 Page 表计数） | 元数据 Tab 只读 |

应用内 **不对齐** ComicInfo / OPF 完整 schema；元数据 Tab 使用单一 canonical `MetadataEditorSchema`，与 Project Export 工作流偏好无关。

### 2. Migration（不可逆）

打开 `library.db` 时执行一次性表重建（`migrate_canonical_metadata`）。**无法回滚**；升级后旧列数据除下表映射外均丢弃。

| 旧列 / 来源 | 新列 / 动作 |
| --- | --- |
| `writer`（及过渡期 `author`） | → `author` |
| `summary` | → `description` |
| `issue_number` | → `number` |
| `year` / `month` / `day`（或 `publication_date` fallback） | → 合并为 `published_date`（仅年 → `"2024"`；年月 → `"2024-05"`；完整 → `"2024-05-31"`） |
| `series`, `series_count`, `language_iso`, `tags`, `characters`, `age_rating`, `cover_page_index` | 保留映射 |
| 其余 ComicInfo 对齐列 | **删除**（见下表） |

**Migration 丢弃的 legacy 列**（未进入 canonical，Import 再次遇到时仍可按 Export 映射写入档案，但不回写 DB）：

`volume`, `alternate_series`, `alternate_number`, `alternate_count`, `notes`, `penciller`, `inker`, `colorist`, `letterer`, `cover_artist`, `editor`, `translator`, `publisher`, `imprint`, `genre`, `web`, `format`, `black_and_white`, `manga`, `teams`, `locations`, `main_character_or_team`, `scan_information`, `story_arc`, `story_arc_number`, `series_group`, `community_rating`, `review`, `gtin`，以及早期 `series_name`, `volume_number`, `language`, `publication_date` 等中间列。

**Import 快照**：不再写入 Project Storage 的 `import_metadata_snapshot` / 原始 ComicInfo·OPF XML；相关 API 与 UI 已移除。

### 3. `author` 语义与 Import 拼接

- **Canonical**：一个 `author` 字段，UI 标签「作者」；**不**在 DB 内保留 ComicInfo 角色分列。
- **Comic Archive Import**：将 ComicInfo 中非空角色（`Writer`, `Penciller`, `CoverArtist`, `Inker`, `Colorist`, `Letterer`, `Editor`, `Translator` 等）按固定顺序 **逗号空格拼接** 为 `author`。
- **EPUB Import**：多个 `dc:creator` → 逗号拼接为 `author`。
- **Export 对称性**：
  - Comic Archive：`author` → ComicInfo **`Penciller` only**（不写 `Writer`）。
  - EPUB：`author` 按逗号 **拆分** 为多个 `dc:creator`。
  - PDF Document Info：`author` → `Author` 字符串（可含逗号，不拆分）。

维护者须知：ComicInfo 生态中「Penciller」常指画手；本应用 deliberately 将 canonical `author` 在 Export 时写入 `Penciller`，以与历史 Export 行为及 ACV 测试一致，**并非**断言用户输入的「作者」仅为画手。

### 4. `published_date` 分级 ISO

- **存储**：单字段 TEXT；合法值为 `YYYY`、`YYYY-MM`、`YYYY-MM-DD` 或 NULL。
- **Import**：ComicInfo `Year`/`Month`/`Day`、OPF `dc:date`、PDF `CreationDate`/`ModDate` 等归一化为上述精度（PDF 日期前缀 `D:` 剥离后按 digit 长度分级）。
- **Export**：ComicInfo 按精度 **仅写有值的** `Year`/`Month`/`Day` 元素；OPF 写 `dc:date` 字符串；PDF 本期 **不写** 日期到 Document Info。
- **UI**：年 / 月 / 日三栏；展示与 stored 精度一致（仅 `"2024"` 则月日为空）；合并时若设月则必须已有年，设日则必须已有月。

### 5. Import / Export 映射边界（概要）

详细验收与测试在各格式 Export/Import 模块；此处仅界定 **边界职责**：

| 格式 | Import 来源 → canonical | Export canonical → 档案 |
| --- | --- | --- |
| **CBZ / CBR / CB7** | ComicInfo.xml | ComicInfo.xml（`author`→`Penciller`；`PageCount`＝实际页数） |
| **EPUB** | OPF（ComicInfo 若存在则优先） | OPF Dublin Core + 约定 meta；固定版式 meta 由 Export 自动 append，**不属于** canonical |
| **PDF** | Document Info：`Title`/`Author`/`Subject`/`Keywords`；日期可选 → `published_date` | Document Info 同上 + 嵌入 **最小** ComicInfo（Title/Penciller/Summary/Tags/PageCount）；系列/期号/语言等 **本期 out of scope** |

`page_count`：Import 取实际导入页数；Export 写入档案时 **忽略** stale metadata 中的 `page_count`，以当前 Page 列表长度为准。

`cover_page_index`：Comic Archive Import 由 ComicInfo `Pages` 解析；EPUB Import 由 OPF cover item 解析；Export 按 canonical 值写 ComicInfo `Pages` / EPUB cover manifest。

### 6. 代码锚点

|  concern | 位置 |
| --- | --- |
| Canonical 类型与校验 | `core/src/db/metadata.rs` |
| Migration | `core/src/db/migrate.rs` |
| Editor schema | `core/src/metadata_schema/` |
| Comic Archive I/O | `core/src/import/metadata.rs`, `core/src/export_cbz.rs` |
| EPUB OPF | `core/src/epub_format.rs` |
| PDF 最小集 | `core/src/pdf_format.rs`, `core/src/export_pdf.rs` |

## 备选

- **继续 ComicInfo 列对齐 DB**：列爆炸、Migration 难维护；否决。
- **保留 import XML 快照**：占用存储、与 canonical 双轨；否决。
- **Export `author` → ComicInfo `Writer`**：与已定 Export 行为及往返测试不一致；否决。

## 后果

- **正面**：单一应用内模型；元数据 Tab 格式无关；Agent 与维护者可读 ADR + CONTEXT 即知边界。
- **负面**：ComicInfo 大量字段 Import 后不可在应用内编辑（除非未来扩展 canonical）；PDF 元数据能力 deliberately 受限。
- **术语审阅**（维护者）：`author` 统一称「作者」；Export 至 ComicInfo 时使用 `Penciller` 元素名为 **格式映射**，不改变 canonical 字段 id。`published_date` 禁止写入非分级 ISO 字符串。
