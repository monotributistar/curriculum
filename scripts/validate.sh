#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "[validate] Usage: $0 <markdown-file>" >&2
  exit 2
fi

file="$1"
warnings=0

if [[ ! -f "$file" ]]; then
  echo "[validate] ERROR: file not found: $file" >&2
  exit 2
fi

if rg -n '^\s*\|?.*?\|\s*$' "$file" >/dev/null 2>&1 && rg -n '^\s*\|?\s*:?-{3,}:?\s*(\|\s*:?-{3,}:?\s*)+\|?\s*$' "$file" >/dev/null 2>&1; then
  echo "[validate] ERROR: markdown table detected in $file. ATS guardrail blocks table layouts." >&2
  exit 1
fi

if rg -n '<table\b' "$file" >/dev/null 2>&1; then
  echo "[validate] ERROR: HTML <table> detected in $file. ATS guardrail blocks table layouts." >&2
  exit 1
fi

if ! rg -n '^#\s+.+' "$file" >/dev/null 2>&1; then
  echo "[validate] WARNING: missing top-level header (# ...) in $file" >&2
  warnings=1
fi

if ! rg -ni '^##\s+(experience|experiencia)\b' "$file" >/dev/null 2>&1; then
  echo "[validate] WARNING: missing Experience/Experiencia section in $file" >&2
  warnings=1
fi

if [[ $warnings -eq 0 ]]; then
  echo "[validate] OK: $file"
else
  echo "[validate] OK with warnings: $file"
fi

