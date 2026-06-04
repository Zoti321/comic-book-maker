#!/usr/bin/env bash
# 在独立工作区运行 riverpod_generator；通过符号链接指向 app 内各 provider 源目录（单一源）。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
APP_LIB="$(cd "$ROOT/../../lib" && pwd)"
CODEGEN_LIB="$ROOT/lib"

declare -a LINKS=(
  "global_providers:$APP_LIB/providers"
  "library_feature_providers:$APP_LIB/ui/features/library/providers"
  "project_editor_feature_providers:$APP_LIB/ui/features/project_editor/providers"
)

mkdir -p "$CODEGEN_LIB"
for existing in "$CODEGEN_LIB"/*; do
  if [[ -e "$existing" || -L "$existing" ]]; then
    if [[ -L "$existing" ]]; then
      rm "$existing"
    else
      rm -rf "$existing"
    fi
  fi
done

for pair in "${LINKS[@]}"; do
  name="${pair%%:*}"
  target="${pair#*:}"
  ln -s "$target" "$CODEGEN_LIB/$name"
done

cd "$ROOT"
dart pub get
dart run build_runner build --delete-conflicting-outputs
echo "Generated *.g.dart written under app provider source dirs (via symlinks)"
