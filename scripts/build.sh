#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CV_DIR="$ROOT_DIR/cv"
DIST_DIR="$ROOT_DIR/dist"
TEMPLATES_DIR="$ROOT_DIR/templates"
DEFAULT_CSS_FILE="$TEMPLATES_DIR/style.css"
PDF_HEADER_FILE="$TEMPLATES_DIR/pdf-header.tex"
METADATA_COMMON_FILE="$TEMPLATES_DIR/metadata-common.yaml"
VALIDATE_SCRIPT="$ROOT_DIR/scripts/validate.sh"

PANDOC_IMAGE="${PANDOC_IMAGE:-pandoc/latex:3.1}"
CV_AUTHOR="${CV_AUTHOR:-Javier Rodriguez}"
PDF_ENGINE="${PDF_ENGINE:-}"

USE_DOCKER=0

log() {
  printf '[build] %s\n' "$*"
}

fail() {
  printf '[build] ERROR: %s\n' "$*" >&2
  exit 1
}

find_cv_files() {
  local files=()

  [[ -f "$CV_DIR/CV.md" ]] && files+=("$CV_DIR/CV.md")
  [[ -f "$CV_DIR/CV-DEV.md" ]] && files+=("$CV_DIR/CV-DEV.md")
  [[ -f "$CV_DIR/CV-XP.md" ]] && files+=("$CV_DIR/CV-XP.md")
  [[ -f "$CV_DIR/CV-HUMAN.md" ]] && files+=("$CV_DIR/CV-HUMAN.md")
  [[ -f "$CV_DIR/CV-HUMAN-EN.md" ]] && files+=("$CV_DIR/CV-HUMAN-EN.md")
  [[ -f "$CV_DIR/CV-ES.md" ]] && files+=("$CV_DIR/CV-ES.md")
  [[ -f "$CV_DIR/CV-EN.md" ]] && files+=("$CV_DIR/CV-EN.md")

  if [[ ${#files[@]} -eq 0 ]]; then
    fail "no CV input found. Expected cv/CV*.md variants"
  fi

  printf '%s\n' "${files[@]}"
}

ensure_requirements() {
  mkdir -p "$DIST_DIR"

  [[ -d "$CV_DIR" ]] || fail "missing input directory: $CV_DIR"
  [[ -f "$DEFAULT_CSS_FILE" ]] || fail "missing CSS template: $DEFAULT_CSS_FILE"
  [[ -f "$PDF_HEADER_FILE" ]] || fail "missing PDF header template: $PDF_HEADER_FILE"
}

detect_runtime() {
  if command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; then
    USE_DOCKER=1
    log "Using Docker image $PANDOC_IMAGE"
    return
  fi

  if ! command -v pandoc >/dev/null 2>&1; then
    fail "docker is unavailable and pandoc is not installed locally"
  fi

  log "Using local pandoc binary"
}

run_pandoc() {
  if [[ "$USE_DOCKER" -eq 1 ]]; then
    docker run --rm \
      -u "$(id -u):$(id -g)" \
      -v "$ROOT_DIR:/data" \
      -w /data \
      "$PANDOC_IMAGE" "$@"
    return
  fi

  pandoc "$@"
}

has_xelatex() {
  if [[ "$USE_DOCKER" -eq 1 ]]; then
    docker run --rm \
      --entrypoint sh \
      "$PANDOC_IMAGE" -lc 'command -v xelatex >/dev/null 2>&1'
    return
  fi

  command -v xelatex >/dev/null 2>&1
}

resolve_pdf_engine() {
  if [[ -n "$PDF_ENGINE" ]]; then
    printf '[build] %s\n' "Using PDF engine from env: $PDF_ENGINE" >&2
    printf '%s\n' "$PDF_ENGINE"
    return
  fi

  if has_xelatex; then
    printf '[build] %s\n' "Detected xelatex. Using it as PDF engine." >&2
    printf '%s\n' "xelatex"
    return
  fi

  printf '[build] %s\n' "xelatex not available. Falling back to pdflatex." >&2
  printf '%s\n' "pdflatex"
}

resolve_css_path() {
  local base_name="$1"

  if [[ "$base_name" == *"-XP" ]] && [[ -f "$TEMPLATES_DIR/style-xp.css" ]]; then
    printf '%s\n' "templates/style-xp.css"
    return
  fi

  if [[ "$base_name" == *"-HUMAN"* ]] && [[ -f "$TEMPLATES_DIR/style-human.css" ]]; then
    printf '%s\n' "templates/style-human.css"
    return
  fi

  if [[ "$base_name" == *"-DEV" ]] && [[ -f "$TEMPLATES_DIR/style-dev.css" ]]; then
    printf '%s\n' "templates/style-dev.css"
    return
  fi

  if [[ -f "$TEMPLATES_DIR/style-dev.css" ]]; then
    printf '%s\n' "templates/style-dev.css"
    return
  fi

  printf '%s\n' "templates/style.css"
}

generate_index_page() {
  local names=("$@")
  local index_file="$DIST_DIR/index.html"

  cat >"$index_file" <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>Javier Rodriguez - CV Outputs</title>
  <style>
    :root {
      --bg: #f7f9fc;
      --card: #ffffff;
      --text: #1f2933;
      --muted: #52606d;
      --border: #d9e2ec;
      --accent: #0b6efd;
    }
    body {
      margin: 0;
      font-family: "Avenir Next", "Segoe UI", Arial, sans-serif;
      color: var(--text);
      background: var(--bg);
    }
    main {
      max-width: 900px;
      margin: 32px auto;
      padding: 0 16px;
    }
    h1 {
      margin: 0 0 8px;
      font-size: 2rem;
    }
    p {
      margin: 0 0 18px;
      color: var(--muted);
    }
    .card {
      background: var(--card);
      border: 1px solid var(--border);
      border-radius: 12px;
      padding: 16px 18px;
      margin-bottom: 12px;
    }
    .title {
      margin: 0 0 8px;
      font-weight: 700;
    }
    .links a {
      color: var(--accent);
      text-decoration: none;
      margin-right: 14px;
    }
  </style>
</head>
<body>
  <main>
    <h1>CV Outputs</h1>
    <p>Generated from Markdown sources in this repository.</p>
HTML

  for base_name in "${names[@]}"; do
    {
      printf '    <section class="card">\n'
      printf '      <div class="title">%s</div>\n' "$base_name"
      printf '      <div class="links">\n'
      printf '        <a href="%s.html">HTML</a>\n' "$base_name"
      printf '        <a href="%s.pdf">PDF</a>\n' "$base_name"
      printf '        <a href="%s.txt">TXT</a>\n' "$base_name"
      printf '      </div>\n'
      printf '    </section>\n'
    } >>"$index_file"
  done

  cat >>"$index_file" <<'HTML'
  </main>
</body>
</html>
HTML

  log "Generated dist/index.html"
}

ensure_requirements
detect_runtime
cv_files=()
while IFS= read -r cv_entry; do
  cv_files+=("$cv_entry")
done < <(find_cv_files)
PDF_ENGINE="$(resolve_pdf_engine)"
generated_names=()

for cv_file in "${cv_files[@]}"; do
  rel_input="${cv_file#"$ROOT_DIR/"}"
  base_name="$(basename "${cv_file%.md}")"
  html_out="dist/${base_name}.html"
  pdf_out="dist/${base_name}.pdf"
  txt_out="dist/${base_name}.txt"
  css_path="$(resolve_css_path "$base_name")"

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
    --css "$css_path" \
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

  generated_names+=("$base_name")
done

generate_index_page "${generated_names[@]}"

# Keep HTML asset paths valid when opening files directly from dist/.
rm -rf "$DIST_DIR/templates"
cp -R "$TEMPLATES_DIR" "$DIST_DIR/templates"

log "Build completed. Outputs:"
ls -1 "$DIST_DIR"
