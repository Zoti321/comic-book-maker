#!/usr/bin/env bash
# 在独立工作区为 FRB 生成的 @freezed 类型运行 freezed；通过符号链接指向 app/lib/src/rust。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_RUST="$(cd "$ROOT/../../lib/src/rust" && pwd)"
CODEGEN_LIB="$ROOT/lib"
LINK="$CODEGEN_LIB/rust"

mkdir -p "$CODEGEN_LIB"
if [[ -e "$LINK" || -L "$LINK" ]]; then
  rm -rf "$LINK"
fi
ln -s "$APP_RUST" "$LINK"

cd "$ROOT"
dart pub get
dart run build_runner build --delete-conflicting-outputs
rm -rf "$LINK"
echo "Generated *.freezed.dart under app/lib/src/rust (via symlink)"
