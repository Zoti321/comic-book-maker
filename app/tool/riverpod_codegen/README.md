# Riverpod codegen 工作区

`app/lib/providers/` 是 **唯一** 的 provider 源目录（含 `*.g.dart` 生成结果）。

本目录仅用于规避 `flutter_test` 与 `riverpod_generator` 的 analyzer 版本冲突：在独立 package 中运行 `build_runner`，通过目录联接 / 符号链接读取同一份源文件，**不再** 维护 `lib/providers/` 下的拷贝。

## 运行

```powershell
.\app\tool\riverpod_codegen\run_codegen.ps1
```

```bash
./app/tool/riverpod_codegen/run_codegen.sh
```

脚本会创建 `lib/providers` → `../../lib/providers` 的联接，生成文件直接写入 `app/lib/providers/`。

## 修改 provider 时

只编辑 `app/lib/providers/*.dart`，然后运行上述脚本。勿在 `tool/riverpod_codegen/lib/providers/` 下手改（该路径为联接，且已 gitignore）。
