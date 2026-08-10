#!/bin/bash
# theme-sync.sh — point alacritty's imported theme at light.toml or dark.toml,
# following the macOS appearance. With System Settings → Appearance set to Auto,
# macOS flips at sunrise/sunset, so this tracks the sun for free.
#
# Run on a 60s interval by com.jeremy.alacritty-theme; safe to run by hand.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$HOME/.config/alacritty/theme.toml"

# The key is absent entirely in light mode, so a read failure means light.
if [ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" = "Dark" ]; then
  src="$DOTFILES/alacritty/dark.toml"
else
  src="$DOTFILES/alacritty/light.toml"
fi

# Already correct — bail before touching the file, or every tick would
# trigger a pointless live-reload in every open window.
if cmp -s "$src" "$DEST"; then
  exit 0
fi

mkdir -p "$(dirname "$DEST")"

# Rename into place rather than writing over it: alacritty's watcher fires on
# the write, and a partial file would blow up its config parse.
tmp="$(mktemp "$DEST.XXXXXX")"
cat "$src" >"$tmp"
mv -f "$tmp" "$DEST"
