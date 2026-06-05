# 内置 UnRAR 解压库，全平台 Import CBR

v1 需在桌面与移动端 Import CBR（RAR 压缩的漫画档案）。选定在 Rust Core 内嵌 UnRAR 解压能力（[`unrar-ng`](https://crates.io/crates/unrar-ng)），全平台统一走同一 Import 路径：解压 → 自然排序 → 复制 Page Image 到 Project Storage 的 `assets/`。仅需解压；**RAR 创建（Export CBR）** 见 [ADR-0008](0008-cbr-export-rars.md)。备选方案是桌面内置、移动端不支持 CBR，或依赖系统 `unar`/`7z` CLI，但会导致平台能力不一致或用户环境强依赖。许可见 [`docs/third-party/unrar.md`](../third-party/unrar.md)；分发方须审阅 UnRAR 条款并确认静态链接与 App Store 分发合规。
