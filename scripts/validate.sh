#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "[validate] Usage: $0 <markdown-file>" >&2
  exit 2
fi

file="$1"
warnings=0
has_rg=0

if [[ ! -f "$file" ]]; then
  echo "[validate] ERROR: file not found: $file" >&2
  exit 2
fi

if command -v rg >/dev/null 2>&1; then
  has_rg=1
fi

search() {
  local regex="$1"
  local target="$2"

  if [[ "$has_rg" -eq 1 ]]; then
    rg -n "$regex" "$target"
    return
  fi

  grep -nE "$regex" "$target"
}

search_i() {
  local regex="$1"
  local target="$2"

  if [[ "$has_rg" -eq 1 ]]; then
    rg -n -i "$regex" "$target"
    return
  fi

  grep -niE "$regex" "$target"
}

# Markdown table detection:
# fail only when we find a table separator row and a neighbor line with pipes.
if awk '
  function is_separator(line) {
    return line ~ /^[[:space:]]*\|?[[:space:]]*:?-{3,}:?([[:space:]]*\|[[:space:]]*:?-{3,}:?)+[[:space:]]*\|?[[:space:]]*$/
  }
  function has_pipe(line) {
    return line ~ /\|/
  }
  {
    lines[NR] = $0
  }
  END {
    for (i = 1; i <= NR; i++) {
      if (is_separator(lines[i]) && (has_pipe(lines[i - 1]) || has_pipe(lines[i + 1]))) {
        exit 0
      }
    }
    exit 1
  }
' "$file"; then
  echo "[validate] ERROR: markdown table detected in $file. ATS guardrail blocks table layouts." >&2
  exit 1
fi

if search_i '<table([[:space:]>]|$)' "$file" >/dev/null 2>&1; then
  echo "[validate] ERROR: HTML <table> detected in $file. ATS guardrail blocks table layouts." >&2
  exit 1
fi

if ! search '^#[[:space:]]+.+' "$file" >/dev/null 2>&1; then
  echo "[validate] WARNING: missing top-level header (# ...) in $file" >&2
  warnings=1
fi

if ! search_i '^##[[:space:]]+(experience|experiencia)\b' "$file" >/dev/null 2>&1; then
  echo "[validate] WARNING: missing Experience/Experiencia section in $file" >&2
  warnings=1
fi

if search '^(Project|Stack|Team):.* - [A-Za-z]' "$file" >/dev/null 2>&1; then
  echo "[validate] WARNING: probable glued list content detected (e.g. \"Team: ... - Bullet\") in $file" >&2
  warnings=1
fi

if [[ $warnings -eq 0 ]]; then
  echo "[validate] OK: $file"
else
  echo "[validate] OK with warnings: $file"
fi
