# rars（CBR 导出）

CBR Export 使用 Rust 包 [rars](https://crates.io/crates/rars)（**0.2.0**），在 Core 内**创建** RAR/CBR 归档。解压仍由 [unrar-ng](unrar.md) 负责，二者职责分离。

## 许可

`rars` 及其贡献者代码采用 **MIT OR Apache-2.0** 双许可（见 [crates.io](https://crates.io/crates/rars) 与 [bitplane/rars](https://github.com/bitplane/rars)）。

`rars` 为纯 Rust RAR 实现，**不**静态链接 RARLab UnRAR 源码。分发本应用时，Export 创建路径的合规审查由产品发布方负责；Import 解压路径另见 [unrar.md](unrar.md)。

## 代码位置

- `core/src/export_cbr.rs` — CBR 导出入口（`export_cbr`）
- `core/Cargo.toml` — `rars = "0.2.0"` 依赖

## 写入策略（ADR-0008）

- 默认 **RAR 5.0**（`rar50`）
- 单成员默认尝试压缩；若试压后 `packed_size >= 原图字节数`，则对该成员计划为 **Store**
- `rars` 0.2.0 的 RAR5 writer **不支持**同一归档内混合 stored/compressed 成员；当成员计划不一致时，整包回退为 **compressed**（优先满足「默认压缩」）

## 与 unrar-ng 的分工

| 操作 | 库 | 文档 |
| --- | --- | --- |
| Export 创建 RAR | `rars` | 本文 |
| Import 解压 RAR | `unrar-ng` | [unrar.md](unrar.md) |
