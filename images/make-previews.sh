#!/usr/bin/env bash
# Regenerate preview.png (4 pages side by side) and preview-grid.png (2x2 grid)
# from the rendered template.pdf at the repo root.
# Requires poppler (pdftoppm) and ImageMagick 7 (magick). Montage is invoked as
# `magick montage`, not the bare legacy `montage` binary, which some ImageMagick
# installs leave out.
set -euo pipefail

for cmd in pdftoppm magick; do
  command -v "$cmd" >/dev/null || { echo "$0: $cmd not found on PATH" >&2; exit 1; }
done

dir="$(cd "$(dirname "$0")" && pwd)"
pdf="$dir/../template.pdf"
[ -f "$pdf" ] || { echo "$0: $pdf not found; render template.qmd first" >&2; exit 1; }
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# preview.png: pages 1-4 in a row at 150 dpi, downscaled to 3400px wide,
# quantized to a 256-color palette to keep the file small. Both previews
# show only the first four pages no matter how long the document gets.
pdftoppm -png -r 150 -f 1 -l 4 "$pdf" "$tmp/page"
magick montage "$tmp"/page-*.png -tile 4x1 -geometry +8+0 -background white "$tmp/row.png"
magick "$tmp/row.png" -resize 3400x -colors 256 PNG8:"$dir/preview.png"

# preview-grid.png: 2x2 grid (pages 1-2 top, 3-4 bottom) at 300 dpi, full size
pdftoppm -png -r 300 -f 1 -l 4 "$pdf" "$tmp/hi"
magick montage "$tmp"/hi-*.png -tile 2x2 -geometry +12+12 -background white "$tmp/grid.png"
magick "$tmp/grid.png" -colors 256 PNG8:"$dir/preview-grid.png"

magick identify "$dir/preview.png" "$dir/preview-grid.png"
