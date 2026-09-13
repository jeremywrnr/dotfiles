#!/bin/bash
# screenshot-defaults.sh -- pin how macOS takes screenshots.
#
# Run by install.sh, and safe to run by hand. Prints one status line in the
# installer's register, so it reads as just another section there.
#
# The location is pinned because the clipboard agent watches that one directory,
# and the format because screenshot-clip.sh names a clipboard flavour when it
# reads the file back. The preview thumbnail goes because it holds the write
# back for the whole five seconds it sits in the corner -- five seconds of the
# clipboard still holding the previous capture.
set -euo pipefail

SHOTS="$HOME/Pictures/Screenshots"
mkdir -p "$SHOTS"

# The capture UI reads these once at launch, so a change only takes hold after
# it restarts -- and that redraws the menu bar, so only do it if something
# actually moved.
CHANGED=0
pin() {  # $1: key. $2: -string or -bool. $3: value, as `defaults read` prints it back.
  # Each value is authored once, in the spelling `read` gives back, and the one
  # place that has to care about the CLI's asymmetry is here: `read` prints a
  # boolean as 0 or 1, and `write -bool` takes neither.
  local write=$3
  if [ "$2" = -bool ]; then
    case $3 in 0) write=false ;; 1) write=true ;; esac
  fi
  [ "$(defaults read com.apple.screencapture "$1" 2>/dev/null)" = "$3" ] && return
  defaults write com.apple.screencapture "$1" "$2" "$write"
  CHANGED=1
}
pin location       -string "$SHOTS"
pin type           -string png
pin target         -string file
pin show-thumbnail -bool   0

STATUS=ok
if [ "$CHANGED" = 1 ]; then
  # SystemUIServer owns the keyboard shortcuts, screencaptureui the window that
  # draws the crosshair and the thumbnail. Both come back on their own.
  killall SystemUIServer screencaptureui 2>/dev/null || true
  STATUS=set
fi
echo "  $STATUS: png into $SHOTS, no preview thumbnail"
