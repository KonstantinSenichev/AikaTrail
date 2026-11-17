#!/bin/bash
# Makes the site's web-sized screenshots from the raw App Store captures in the app repository.
# The Lock Screen shots (reminder, Live Activity) are left out: they show Apple's wallpaper.
# Usage: tools/prepare-images.sh [path to the app repository] (from anywhere; the default is
# ../productivity-tracker next to this repository). Frames are drawn by CSS in index.html.
# Everything is built in a temporary folder first and replaces images/ only when every
# step succeeded, so a missing capture leaves the published images untouched.
set -euo pipefail
SITE="$(cd "$(dirname "$0")/.." && pwd)"
APP="$(cd "${1:-$SITE/../productivity-tracker}" && pwd)"
OUT="$SITE/images"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/full" "$TMP/thumbs"

shrink() { # device raw-file longest-edge
  local src="$APP/design/app-store/$1/raw/$2" name="$1-${2%.png}.jpg"
  # sips only warns about a missing file, so check it here.
  [[ -f "$src" ]] || { echo "Missing capture: $src" >&2; exit 1; }
  sips -s format jpeg -s formatOptions 78 -Z "$3" "$src" --out "$TMP/$name" >/dev/null
  # Full-resolution copy, loaded only in the zoomed view.
  sips -s format jpeg -s formatOptions 80 "$src" --out "$TMP/full/$name" >/dev/null
  # Thumbnail for the picker under the large screenshot.
  sips -Z 360 "$TMP/$name" --out "$TMP/thumbs/$name" >/dev/null
}
for f in 01-today 02-recent 03-week 04-tags 05-groups 06-day 07-dark 08-export; do
  shrink iphone-18-pro-max "$f.png" 1400
done
for f in 01-today 02-recent; do shrink iphone-duo "$f.png" 1400; done
for f in 03-week 04-tags 05-groups 06-day 07-dark 08-export; do shrink iphone-duo "$f.png" 1800; done
for f in 01-today 02-recent 03-week 04-tags 05-groups 06-day 07-dark 08-export; do
  shrink ipad-pro-13 "$f.png" 1800
done
cp "$APP/AikaTrailWidgets/Assets.xcassets/AppIconImage.imageset/AppIconImage@3x.png" "$TMP/app-icon.png"

# Swap in the new set; renamed or dropped captures don't linger and get published.
rm -rf "$OUT"
cp -R "$TMP" "$OUT"
chmod -R u=rwX,go=rX "$OUT"
