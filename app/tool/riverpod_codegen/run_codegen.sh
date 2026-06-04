#!/usr/bin/env bash
# 在独立工作区运行 riverpod_generator；providers 通过符号链接指向 app/lib/providers（单一源）。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_PROVIDERS="$(cd "$ROOT/../../lib/providers" && pwd)"
CODEGEN_PROVIDERS="$ROOT/lib/providers"

if [[ -e "$CODEGEN_PROVIDERS" || -L "$CODEGEN_PROVIDERS" ]]; then
  if [[ -L "$CODEGEN_PROVIDERS" ]]; then
    rm "$CODEGEN_PROVIDERS"
  else
    rm -rf "$CODEGEN_PROVIDERS"
  fi
fi
ln -s "$APP_PROVIDERS" "$CODEGEN_PROVIDERS"

cd "$ROOT"
dart pub get
dart run build_runner build --delete-conflicting-outputs
echo "Generated *.g.dart written to $APP_PROVIDERS (via symlink)"
