#!/usr/bin/env bash
set -euo pipefail

MAX_LINES="${1:-500}"
ROOT_DIR="${2:-lib}"
EXCLUDE_REGEX="${3:-}"

if ! command -v find >/dev/null 2>&1; then
  echo "find command is required" >&2
  exit 1
fi

mapfile -d '' files < <(find "$ROOT_DIR" -type f -name '*.dart' -print0)

if [[ ${#files[@]} -eq 0 ]]; then
  echo "No Dart files found in ${ROOT_DIR}."
  exit 0
fi

filtered_files=()
for file in "${files[@]}"; do
  if [[ -n "$EXCLUDE_REGEX" ]] && [[ "$file" =~ $EXCLUDE_REGEX ]]; then
    continue
  fi
  filtered_files+=("$file")
done

if [[ ${#filtered_files[@]} -eq 0 ]]; then
  echo "No Dart files to check in ${ROOT_DIR} after excludes."
  exit 0
fi

violations="$(wc -l "${filtered_files[@]}" \
  | awk -v max="$MAX_LINES" '$2 ~ /\.dart$/ && $1 > max {print $1 " " $2}')"

if [[ -n "$violations" ]]; then
  echo "Found Dart files above ${MAX_LINES} LOC:" >&2
  echo "$violations" >&2
  exit 1
fi

echo "OK: no Dart files above ${MAX_LINES} LOC in ${ROOT_DIR}."
