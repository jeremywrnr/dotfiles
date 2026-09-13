#!/bin/bash
# screenshot-clip.sh -- mirror the newest screenshot onto the clipboard.
#
# macOS makes this either/or: Cmd-Shift-4 writes a file, adding Ctrl puts the
# capture on the clipboard instead, and there is no modifier for both. So the
# file stays the source of truth and the clipboard follows it -- launchd watches
# the screenshot directory (com.jeremy.screenshot-clip.plist) and runs this on
# every change there.
set -euo pipefail

# Ask macOS where captures go rather than keeping a second copy of the answer;
# screenshot-defaults.sh pins it and this reads it back. SCREENSHOT_DIR
# overrides, which is how the edge cases get exercised by hand.
DIR=${SCREENSHOT_DIR:-}
if [ -z "$DIR" ]; then
  # An unset location means screenshot-defaults.sh has never run here, so there
  # is no directory anyone agreed on and nothing to mirror. Note the `|| exit 0`
  # rather than letting the assignment carry the failure: under `set -e` a
  # command substitution that fails takes the whole script with it, status and
  # all, which is a confusing way for launchd to hear "nothing to do".
  DIR=$(defaults read com.apple.screencapture location 2>/dev/null) || exit 0
fi
DIR=${DIR/#\~/$HOME}
[ -d "$DIR" ] || exit 0

STATE="$HOME/Library/Caches/com.jeremy.screenshot-clip"

# png only. screenshot-defaults.sh pins `com.apple.screencapture type` to png,
# and the read below has to name a clipboard flavour, so one format keeps the
# two honest. Screen recordings land here as .mov and are skipped for free.
shopt -s nullglob
shots=("$DIR"/*.png)
(( ${#shots[@]} )) || exit 0

# `-nt` is a shell builtin, so picking the newest of a decade of screenshots
# costs no processes at all -- and unlike `ls -t | head -1`, nothing here breaks
# once the listing outgrows a pipe buffer and `head` starts closing it early.
newest=
for shot in "${shots[@]}"; do
  if [ -z "$newest" ] || [ "$shot" -nt "$newest" ]; then
    newest=$shot
  fi
done
read -r newest_t size <<<"$(/usr/bin/stat -f '%m %z' "$newest")"

# A WatchPaths job also runs once when launchd loads it, and again for any
# change in the directory -- a rename, a delete, an old shot dragged out. Each
# of those would otherwise slam a long-dead screenshot onto the clipboard, so
# ignore anything that is not seconds old, and never copy the same file twice.
(( $(date +%s) - newest_t < 60 )) || exit 0
prev=
if [ -f "$STATE" ]; then read -r prev <"$STATE" || true; fi
[ "$prev" = "$newest_t $newest" ] && exit 0

# The watch fires on the first write to the file, which can be ahead of the
# last one, and half a png on the clipboard is worse than a slow one. The stat
# above is the first sample, so a capture that finished before launchd got to
# us -- almost all of them -- confirms itself here and pays nothing.
for ((i = 0; i < 100; i++)); do
  now=$(/usr/bin/stat -f %z "$newest")
  [ "$now" = "$size" ] && [ "$now" != 0 ] && break
  size=$now
  sleep 0.02
done

# `set the clipboard to` is Standard Additions, handled inside osascript itself:
# no Apple event leaves the process, so this needs no automation permission and
# works with the empty environment launchd hands an agent.
/usr/bin/osascript \
  -e 'on run argv' \
  -e 'set the clipboard to (read (POSIX file (item 1 of argv)) as «class PNGf»)' \
  -e 'end run' \
  "$newest"

printf '%s %s\n' "$newest_t" "$newest" >"$STATE"
