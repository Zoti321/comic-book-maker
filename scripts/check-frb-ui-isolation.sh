#!/usr/bin/env bash
# Fail if lib/ui or lib/providers import FRB directly (ADR-0007).
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
app_lib="$repo_root/app/lib"
pattern='src/rust'
hits=()

for dir in ui providers; do
  search_dir="$app_lib/$dir"
  if [[ ! -d "$search_dir" ]]; then
    continue
  fi
  while IFS= read -r file; do
    line_no=0
    while IFS= read -r line; do
      line_no=$((line_no + 1))
      if [[ "$line" == *"$pattern"* ]]; then
        rel="${file#"$app_lib"/}"
        hits+=("${rel}:${line_no}:${line#"${line%%[![:space:]]*}"}")
      fi
    done <"$file"
  done < <(find "$search_dir" -name '*.dart' -type f -print)
done

if ((${#hits[@]} > 0)); then
  printf '%s\n' \
    'FRB isolation violated: app/lib/ui and app/lib/providers must not import src/rust.' \
    'Use package:comic_book_maker/data/repositories/core_gateway.dart instead.' \
    '' \
    "${hits[@]}" >&2
  exit 1
fi

echo 'FRB UI/provider isolation OK'
