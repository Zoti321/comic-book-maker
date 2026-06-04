# Riverpod codegen 工作区

Provider 源文件分布在三处（含 `*.g.dart` 生成结果），本目录仅用于规避 `flutter_test` 与 `riverpod_generator` 的 analyzer 版本冲突。

| 联接名 | 应用内路径 | 内容 |
| --- | --- | --- |
| `global_providers` | `app/lib/providers/` | `coreGateway`、`exportPath`（跨 feature） |
| `library_feature_providers` | `app/lib/ui/features/library/providers/` | `libraryOperations`、`libraryProjects` |
| `project_editor_feature_providers` | `app/lib/ui/features/project_editor/providers/` | `projectWorkspace` family |

## 运行

```powershell
.\app\tool\riverpod_codegen\run_codegen.ps1
```

```bash
./app/tool/riverpod_codegen/run_codegen.sh
```

脚本在 `tool/riverpod_codegen/lib/` 下创建上述联接 / 符号链接，运行 `build_runner`，`*.g.dart` 直接写入对应应用目录。

## 修改 provider 时

只编辑上表中的应用内 `*.dart`（勿改 `part` 指向的 `*.g.dart`），然后运行上述脚本。勿在 `tool/riverpod_codegen/lib/*` 下手改（均为联接，且已 gitignore）。
