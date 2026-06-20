# Comic Book Maker

跨平台漫画制作与编辑工具（Flutter UI + Rust Core，经 FRB 通信）。

## 仓库结构

```
comic_book_maker/
├── app/          # Flutter 应用（desktop + mobile，无 web）
├── core/         # Rust 核心库（comic_book_maker_core）
├── docs/         # ADR 与 agent 配置
└── CONTEXT.md    # 领域术语
```

## 前置依赖

- [Flutter](https://docs.flutter.dev/get-started/install)（stable，已启用 desktop 目标）
- [Rust](https://rustup.rs/)（stable）
- `flutter_rust_bridge_codegen`（见下方安装）

Windows 首次克隆后，创建 `rust_builder/rust` 目录联接（cargokit 构建需要）：

```powershell
.\scripts\setup-rust-junction.ps1
```

## FRB 代码生成

安装 codegen（一次性）：

```powershell
cargo install flutter_rust_bridge_codegen
```

修改 `core/src/api/` 后，在 `app/` 目录执行：

```powershell
# Windows
..\scripts\generate-frb.ps1

# 或手动
flutter_rust_bridge_codegen generate
```

## 运行应用

```powershell
cd app
flutter pub get
flutter run -d windows   # 或其他已连接设备
```

## 开发说明

- FRB 配置：`app/flutter_rust_bridge.yaml`（`rust_root: ../core/`）
- Rust crate 名：`comic_book_maker_core`（`core/Cargo.toml`）
- Flutter 通过 `app/rust_builder/`（cargokit）在构建时编译 Rust；Windows/Linux 经 `rust_builder/rust` 联接访问 `core/`
- Riverpod codegen：在 `app/` 根目录直接跑 `build_runner` 可能因 `analyzer` 冲突失败，请用 `app/tool/riverpod_codegen/run_codegen.ps1`（见该目录 `README.md`）
- 领域术语：`CONTEXT.md`；架构决策：`docs/adr/`；Agent 约定：`docs/agents/`

## 测试

```powershell
cd app
flutter test
flutter test integration_test/ -d flutter-tester
```

集成测试使用真 Rust Core 与 `integration_test/fixtures/two_pages.cbz`。首次克隆若缺少 fixture：

```powershell
cd app
dart run tool/generate_integration_fixture.dart
```

### Library Profile 基准

漫画库 Profile 性能优化（[#19](https://github.com/Zoti321/comic-book-maker/issues/19)）的可复现 seed 与验收流程见 [`docs/agents/library-profile-benchmark.md`](docs/agents/library-profile-benchmark.md)。快速开始：

```powershell
.\scripts\seed-library-benchmark.ps1 -Clean
cd app
flutter run --profile -d windows --dart-define=CBM_APP_DATA_DIR=$env:TEMP\cbm-library-profile-bench
```
