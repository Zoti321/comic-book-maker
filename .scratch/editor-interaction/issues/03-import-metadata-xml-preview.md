Category: enhancement
Status: done

# 导入元数据 XML 快照与预览

## What to build

在 Project Storage 保留**导入资源元数据快照**，供元数据 Tab **只读预览**，避免仅用 Library Database 字段无法覆盖源档案中的扩展项。

**存储**

- 单文件快照（建议 `import-metadata.xml` 或等价路径）+ 种类标记：`comicinfo` | `opf` | `none`

**写入时机**

- Library Import：CBZ/CBR 含 ComicInfo → 存源 XML 原文，`kind = comicinfo`；无 ComicInfo → `kind = none`。EPUB 优先 ComicInfo；否则提取 OPF `<metadata>` 节（完整节或文档化子集）存为 `kind = opf`
- 编辑页追加档案导入（见 04）：若新档案带元数据则**更新快照**（以最新一次为准）；仅追加 Page Image、无新 XML 时保留旧快照

**API**

- Core + FRB：`getImportMetadataSnapshot` 返回种类与 XML 文本，或空

**UI（元数据 Tab 上半区）**

- 等宽、可滚动、可选择的 XML 文本展示
- `kind = none`，或推断为纯图片导入且无 XML：文案「导入资源中没有元数据」

本切片可不依赖导出格式设置 UI，但与 01 联调时预览区文案可与只读 `inferred_import_kind` 一致。

## Acceptance criteria

- [x] CBZ 含 ComicInfo 的 Library Import 后，元数据 Tab 可见与源一致的 XML
- [x] EPUB Import 后可见 OPF metadata XML（种类为 `opf`）
- [x] 纯图片建项或无元数据档案显示明确空状态文案
- [x] Core 测试覆盖快照写入、读取与 `kind` 分支

## Blocked by

None - can start immediately
