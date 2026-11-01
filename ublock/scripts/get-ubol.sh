#!/usr/bin/env bash
# usage: get-ubol.sh
# Downloads the latest uBO Lite Chromium build into $UBOL_DIR (default
# ~/.local/share/chrome-dev-filters/ubol, beside the filters browser's profile),
# replacing what is there. The path never changes: an unpacked extension's ID
# comes from its path, so a stable path keeps uBO Lite's settings and its
# "Allow user scripts" grant across upgrades, checkouts and worktrees.
set -euo pipefail

UBOL_DIR="${UBOL_DIR:-$HOME/.local/share/chrome-dev-filters/ubol}"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
gh release download -R uBlockOrigin/uBOL-home -p '*.chromium.zip' -D "$tmp"
unzip -q "$tmp"/*.chromium.zip -d "$tmp/ubol"
# Some builds nest everything in one top-level folder.
src="$tmp/ubol"
[[ -f "$src/manifest.json" ]] || src=$(dirname "$(ls "$tmp"/ubol/*/manifest.json | head -1)")
rm -rf "$UBOL_DIR"
mkdir -p "$(dirname "$UBOL_DIR")"
mv "$src" "$UBOL_DIR"
echo "uBO Lite $(node -p "require(process.argv[1]).version" "$UBOL_DIR/manifest.json") -> $UBOL_DIR"
