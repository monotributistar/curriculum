#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CV_DIR="$ROOT_DIR/cv"
DIST_DIR="$ROOT_DIR/dist"
TEMPLATES_DIR="$ROOT_DIR/templates"
CSS_FILE="$TEMPLATES_DIR/style.css"
PDF_HEADER_FILE="$TEMPLATES_DIR/pdf-header.tex"
METADATA_COMMON_FILE="$TEMPLATES_DIR/metadata-common.yaml"
VALIDATE_SCRIPT="$ROOT_DIR/scripts/validate.sh"

PANDOC_IMAGE="${PANDOC_IMAGE:-pandoc/latex:3.1}"
PDF_ENGINE="${PDF_ENGINE:-pdflatex}"
CV_AUTHOR="${CV_AUTHOR:-Javier Rodriguez}"

log() {
  printf '[build] %s\n' "$*"
}

fail() {
  printf '[build] ERROR: %s\n' "$*" >&2
  exit 1
}

mkdir -p "$DIST_DIR"

if [[ ! -d "$CV_DIR" ]]; then
  fail "missing input directory: $CV_DIR"
fi

if [[ ! -f "$CSS_FILE" ]]; then
  fail "missing CSS template: $CSS_FILE"
fi

if [[ ! -f "$PDF_HEADER_FILE" ]]; then
  fail "missing PDF header template: $PDF_HEADER_FILE"
fi

cv_files=()
[[ -f "$CV_DIR/CV.md" ]] && cv_files+=("$CV_DIR/CV.md")
[[ -f "$CV_DIR/CV-ES.md" ]] && cv_files+=("$CV_DIR/CV-ES.md")
[[ -f "$CV_DIR/CV-EN.md" ]] && cv_files+=("$CV_DIR/CV-EN.md")

if [[ ${#cv_files[@]} -eq 0 ]]; then
  fail "no CV input found. Expected cv/CV.md and/or cv/CV-ES.md/cv/CV-EN.md"
fi

use_docker=0
if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
  use_docker=1
fi

if [[ $use_docker -eq 0 ]] && ! command -v pandoc >/dev/null 2>&1; then
  fail "docker is unavailable and pandoc is not installed locally"
fi

run_pandoc() {
  if [[ $use_docker -eq 1 ]]; then
    docker run --rm \
      -u "$(id -u):$(id -g)" \
      -v "$ROOT_DIR:/data" \
      -w /data \
      "$PANDOC_IMAGE" "$@"
  else
    pandoc "$@"
  fi
}

if [[ $use_docker -eq 1 ]]; then
  log "Using Docker image $PANDOC_IMAGE"
else
  log "Using local pandoc binary"
fi

for cv_file in "${cv_files[@]}"; do
  rel_input="${cv_file#"$ROOT_DIR/"}"
  base_name="$(basename "${cv_file%.md}")"
  html_out="dist/${base_name}.html"
  pdf_out="dist/${base_name}.pdf"
  txt_out="dist/${base_name}.txt"

  log "Validating $rel_input"
  "$VALIDATE_SCRIPT" "$cv_file"

  title="$(sed -n 's/^#\s\+//p' "$cv_file" | head -n1)"
  if [[ -z "$title" ]]; then
    title="$base_name"
  fi

  metadata_args=()
  if [[ -f "$METADATA_COMMON_FILE" ]]; then
    metadata_args+=(--metadata-file "templates/metadata-common.yaml")
  fi
  if [[ "$base_name" == *"-ES" ]] && [[ -f "$TEMPLATES_DIR/metadata-es.yaml" ]]; then
    metadata_args+=(--metadata-file "templates/metadata-es.yaml")
  fi
  if [[ "$base_name" == *"-EN" ]] && [[ -f "$TEMPLATES_DIR/metadata-en.yaml" ]]; then
    metadata_args+=(--metadata-file "templates/metadata-en.yaml")
  fi

  log "Generating $html_out"
  run_pandoc \
    "$rel_input" \
    --from markdown \
    --to html5 \
    --standalone \
    --css "templates/style.css" \
    "${metadata_args[@]}" \
    --metadata "title=$title" \
    -o "$html_out"

  log "Generating $pdf_out"
  run_pandoc \
    "$rel_input" \
    --from markdown \
    --pdf-engine="$PDF_ENGINE" \
    "${metadata_args[@]}" \
    --metadata "title=$title" \
    --metadata "author=$CV_AUTHOR" \
    --include-in-header "templates/pdf-header.tex" \
    -V geometry:margin=1in \
    -V colorlinks=true \
    -V linkcolor=blue \
    -o "$pdf_out"

  log "Generating $txt_out"
  run_pandoc \
    "$rel_input" \
    --from markdown \
    --to plain \
    "${metadata_args[@]}" \
    -o "$txt_out"
done

log "Build completed. Outputs:"
ls -1 "$DIST_DIR"
