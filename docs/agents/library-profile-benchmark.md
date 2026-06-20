# Library Profile 基准

漫画库 Profile 性能优化的可复现基准数据与验收流程（GitHub [#20](https://github.com/Zoti321/comic-book-maker/issues/20) / PRD [#19](https://github.com/Zoti321/comic-book-maker/issues/19)）。

## 前置

- Windows 桌面目标已启用（`flutter config --enable-windows-desktop`）
- 在 `app/` 目录已执行 `flutter pub get`
- 集成 fixture 存在：

```powershell
cd app
dart run tool/generate_integration_fixture.dart
```

## Seed 基准库

Core 经 FRB 调用，需 **Flutter 引擎**；请用仓库脚本（等价于 `tool/seed_library_benchmark.dart` 所描述的行为）：

```powershell
# 仓库根目录
.\scripts\seed-library-benchmark.ps1
```

常用参数：

| 参数 | 默认 | 说明 |
|------|------|------|
| `-Count` | 50 | Project 数量 |
| `-AppDataDir` | `%TEMP%\cbm-library-profile-bench` | 独立应用数据目录 |
| `-Clean` | — | 若目录已有 `library.db` 则先删除 |
| `-TitlePrefix` | `Profile 基准` | 标题前缀（后缀为序号） |

示例：

```powershell
.\scripts\seed-library-benchmark.ps1 -Count 50 -AppDataDir C:\temp\cbm-bench -Clean
```

脚本会经 Core Import `integration_test/fixtures/two_pages.cbz`，为每个 Project 生成 Cover Thumbnail（`.cache/cover.webp`），并校验 50/50 封面就绪。

### 底层等价命令

```powershell
cd app
flutter test test/tool/seed_library_benchmark_cli_test.dart `
  --dart-define=SEED_COUNT=50 `
  --dart-define=SEED_APP_DATA_DIR=C:\temp\cbm-bench `
  --dart-define=SEED_CLEAN=true
```

## Profile 验收

1. **启动 Profile 模式**（使用 seed 时的 `--AppDataDir`）：

```powershell
cd app
flutter run --profile -d windows --dart-define=CBM_APP_DATA_DIR=C:\temp\cbm-bench
```

未指定 `-AppDataDir` 时，默认目录为 `%TEMP%\cbm-library-profile-bench`。

2. **窗口**：1280×800（与集成测试视口一致；可在运行后调整窗口至该尺寸）。

3. **DevTools**：运行后在终端打开 DevTools 链接，进入 **Performance** / **Timeline**。

4. **操作**：在漫画库网格上 **快速 fling 上下滚动 3 次**。

5. **通过标准**：UI 线程无明显连续 **>16ms** 红帧；封面由占位符快速替换为缩略图。

## 清理

```powershell
Remove-Item -Recurse -Force C:\temp\cbm-bench   # 或你的 -AppDataDir
```

重新 seed 时加 `-Clean` 亦可。

## 相关代码

- `app/tool/seed_library_benchmark.dart` — seed 逻辑与 CLI 帮助文本
- `scripts/seed-library-benchmark.ps1` — Windows 入口脚本
- `app/test/tool/seed_library_benchmark_test.dart` — 自动化 smoke（2 项目）
