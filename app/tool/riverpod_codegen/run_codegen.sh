#!/usr/bin/env bash
# 将 app/lib/providers 同步到 codegen 工作区并运行 build_runner，再把 .g.dart 拷回。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_PROVIDERS="$ROOT/../../lib/providers"
CODEGEN_PROVIDERS="$ROOT/lib/providers"
CODEGEN_LIB="$ROOT/lib"

mkdir -p "$CODEGEN_PROVIDERS"
cp "$APP_PROVIDERS/library_provider.dart" "$CODEGEN_PROVIDERS/"
cp "$APP_PROVIDERS/export_path_provider.dart" "$CODEGEN_PROVIDERS/"
cp "$APP_PROVIDERS/project_workspace_provider.dart" "$CODEGEN_PROVIDERS/"
cp "$APP_PROVIDERS/project_workspace_state.dart" "$CODEGEN_PROVIDERS/"

cd "$ROOT"
dart pub get
dart run build_runner build --delete-conflicting-outputs

cp "$CODEGEN_PROVIDERS/"*.g.dart "$APP_PROVIDERS/"
echo "Generated files copied to $APP_PROVIDERS"
