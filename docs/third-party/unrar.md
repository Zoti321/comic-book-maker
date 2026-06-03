# UnRAR（CBR 导入）

CBR 导入使用 Rust 包 [unrar-ng](https://crates.io/crates/unrar-ng)（0.7.x），在编译时静态链接 [RARLab UnRAR](https://www.rarlab.com/rar_add.htm) 源码，仅用于**解压** RAR/CBR 归档，不创建 RAR 文件。

## 许可

UnRAR 库版权归 Alexander Roshal / RARLab 所有。解压组件许可条款见：

https://www.rarlab.com/license.htm

分发本应用时须遵守上述条款（包括但不限于：不得用于开发 RAR 压缩工具、须保留版权声明等）。具体合规审查由产品发布方负责。

## 代码位置

- `core/src/import_cbr.rs` — CBR 导入入口
- `core/Cargo.toml` — `unrar-ng` 依赖
