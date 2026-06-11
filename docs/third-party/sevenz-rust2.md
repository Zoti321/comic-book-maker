# sevenz-rust2（CB7 Import / Export）

CB7（7z 容器）Import 与 Export 使用 Rust 包 [sevenz-rust2](https://crates.io/crates/sevenz-rust2)（**0.20.x** 起），在 Core 内**解压与创建** 7z/CB7 归档。读写共用同一库，与 RAR 路径（[unrar.md](unrar.md) 读 + [rars.md](rars.md) 写）不同。

## 许可

`sevenz-rust2` 采用 **Apache-2.0**（见 [crates.io](https://crates.io/crates/sevenz-rust2) 与 [hasenbanck/sevenz-rust2](https://github.com/hasenbanck/sevenz-rust2)）。

分发本应用时，Export 与 Import 路径均经此库；合规审查由产品发布方负责。

## 代码位置（实现后）

- `core/src/import/cb7.rs` — CB7 导入入口（`import_cb7`、`append_cb7`）
- `core/src/export_cb7.rs` — CB7 导出入口（`export_cb7`）
- `core/Cargo.toml` — `sevenz-rust2 = "0.20"` 依赖（`features = ["compress"]`）

## 实现要点

- **Import**：`decompress_file` 解压到临时目录 → `scan_archive_tree` → stage；`Archive::open` 预检可读性。
- **Export**：`ArchiveWriter::push_archive_entry` 逐成员写入；默认 `EncoderMethod::LZMA2`，试压后 `compressed_size >= 原图` 则 `EncoderMethod::COPY`（Store）；`set_encrypt_header(false)`。
- **FRB**：`import_cb7`、`append_cb7`、`export_cb7` 经 `core/src/api/simple.rs` 暴露。

## 读写策略（ADR-0011）

- **Import**：解压到临时目录，再走与 CBR 相同的 `scan_archive_tree` → stage 流程；密码保护归档拒绝。
- **Export**：根目录 `ComicInfo.xml` + 按页序 Page Image；逐成员 LZMA2；压缩后体积 ≥ 原图则 Store 回退；非 solid 归档。
- **密码 / AES**：v1 不支持；不启用 `aes256` feature。

## 与 RAR 双库模式对比

| 操作 | 7Z / CB7 | RAR / CBR |
| --- | --- | --- |
| Import 解压 | `sevenz-rust2` | `unrar-ng`（[unrar.md](unrar.md)） |
| Export 创建 | `sevenz-rust2` | `rars`（[rars.md](rars.md)） |
| 读写是否同库 | 是 | 否（许可分工） |
