#!/usr/bin/env bash
set -euo pipefail

dist_dir="dist"

if [[ -d "$dist_dir" ]]; then
  rm -rf "$dist_dir"
fi

mkdir -p "$dist_dir"
echo "[clean] Reset $dist_dir/"

