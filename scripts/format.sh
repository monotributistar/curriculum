#!/usr/bin/env bash
set -euo pipefail

# Optional lightweight formatter:
# - normalizes CRLF to LF
# - keeps content untouched (no markdown reflow)
# - ensures files end with a trailing newline

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

files=("$@")
if [[ ${#files[@]} -eq 0 ]]; then
  files=(
    "$ROOT_DIR/cv/CV.md"
    "$ROOT_DIR/cv/CV-DEV.md"
    "$ROOT_DIR/cv/CV-XP.md"
    "$ROOT_DIR/cv/CV-HUMAN.md"
    "$ROOT_DIR/cv/CV-ES.md"
    "$ROOT_DIR/cv/CV-EN.md"
  )
fi

for file in "${files[@]}"; do
  [[ -f "$file" ]] || continue

  tmp_file="$(mktemp)"
  tr -d '\r' <"$file" >"$tmp_file"

  if [[ -s "$tmp_file" ]] && [[ "$(tail -c 1 "$tmp_file" || true)" != "" ]]; then
    printf '\n' >>"$tmp_file"
  fi

  mv "$tmp_file" "$file"
  echo "[format] normalized line endings: $file"
done
