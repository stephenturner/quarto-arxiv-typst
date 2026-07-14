#!/usr/bin/env bash
# Regenerate preview.png (4 pages side by side) and preview-grid.png (2x2 grid)
# from the rendered template.pdf at the repo root.
# Requires poppler (pdftoppm) and ImageMagick (montage, magick).
set -euo pipefail

dir="$(cd "$(dirname "$0")" && pwd)"
pdf="$dir/../template.pdf"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# preview.png: pages 1-4 in a row at 150 dpi, downscaled to 3400px wide,
# quantized to a 256-color palette to keep the file small
pdftoppm -png -r 150 "$pdf" "$tmp/page"
montage "$tmp"/page-*.png -tile 4x1 -geometry +8+0 -background white "$tmp/row.png"
magick "$tmp/row.png" -resize 3400x -colors 256 PNG8:"$dir/preview.png"

# preview-grid.png: 2x2 grid (pages 1-2 top, 3-4 bottom) at 300 dpi, full size
pdftoppm -png -r 300 "$pdf" "$tmp/hi"
montage "$tmp"/hi-*.png -tile 2x2 -geometry +12+12 -background white "$tmp/grid.png"
magick "$tmp/grid.png" -colors 256 PNG8:"$dir/preview-grid.png"

magick identify "$dir/preview.png" "$dir/preview-grid.png"
