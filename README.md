# CV Build Pipeline (Markdown -> HTML/PDF/TXT)

This repository stores ATS-friendly CVs in Markdown and generates versioned outputs in `dist/`:
- HTML (`dist/*.html`)
- PDF (`dist/*.pdf`)
- Plain text (`dist/*.txt`)

The layout is single-column and ATS-first:
- No table-based layout
- No two-column templates
- No icon-based visual blocks

## Repository structure

```text
cv/                  # CV sources (CV.md, CV-ES.md, CV-EN.md)
templates/           # shared rendering assets (CSS)
scripts/             # build, validate, clean scripts
dist/                # generated outputs (gitignored)
.github/workflows/   # GitHub Actions
.gitlab-ci.yml       # GitLab CI pipeline
```

## Input naming convention

- Single CV only: `cv/CV.md`
- Spanish + English:
  - `cv/CV-ES.md`
  - `cv/CV-EN.md`

`scripts/build.sh` auto-detects available files among:
- `cv/CV.md`
- `cv/CV-ES.md`
- `cv/CV-EN.md`

## Local build (Docker default, local fallback)

Prerequisite:
- Docker installed and daemon running (recommended path)

Run:

```bash
./scripts/build.sh
```

Cleanup:

```bash
./scripts/clean.sh
```

Make targets:

```bash
make build
make clean
```

Notes:
- Default mode uses `pandoc/latex:3.1` via Docker for reproducible HTML/PDF/TXT output.
- If Docker is unavailable and local `pandoc` exists, it falls back automatically to local pandoc.

## Validation guardrails

`scripts/validate.sh` runs automatically from `build.sh` and enforces:
- `ERROR` (fails build): Markdown/HTML tables detected (`| ... |`, `<table>`)
- `WARNING` (does not fail): missing top-level header (`# ...`)
- `WARNING` (does not fail): missing `## Experience` / `## Experiencia`

## CI/CD

### GitHub Actions

Workflow: `.github/workflows/cv-build.yml`

Triggers:
- `push` to `main`/`master`: build + artifact upload
- `pull_request`: build + artifact upload
- tags `v*`: build + artifact upload + release attachment

Tag behavior:
- For tags matching `v*`, generated files in `dist/*` are attached to a GitHub Release.
- If the release does not exist, it is created by the release action.

GitHub Pages (optional, enabled):
- On push to `main`/`master`, `dist/` is deployed to GitHub Pages.
- Published URLs depend on generated files, for example:
  - `CV-EN.html`
  - `CV-ES.html`
  - or `CV.html` for single-language repos.

### GitLab CI

Pipeline: `.gitlab-ci.yml`

- Stage: `build`
- Uses `pandoc/latex:3.1` image
- Runs `./scripts/build.sh`
- Uploads `dist/*` as artifacts
- Rules:
  - Merge requests
  - Default branch
  - Tags `v*`

## Versioning convention

Use semantic tags to version generated CV outputs:
- `vX.Y.Z` (example: `v1.2.0`)

Suggested release flow:
1. Update `cv/*.md`
2. Run `./scripts/build.sh`
3. Commit changes (without `dist/`)
4. Tag (`git tag vX.Y.Z`)
5. Push branch and tags (`git push && git push --tags`)

