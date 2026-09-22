#!/bin/bash
# gnome-settings.sh -- pin the GNOME desktop settings this machine wants.
#
# Run by install.sh, and safe to run by hand. Prints one status line in the
# installer's register, so it reads as just another section there.
#
# idle-dim and idle-delay both go because the screen blanking mid-video is
# worse than the power it saves. idle-delay 0 means the idle timer never fires,
# so the screensaver lock never triggers either -- lock on Super+L and lock on
# resume from suspend still work.
set -euo pipefail

CHANGED=0
pin() {  # $1: schema. $2: key. $3: value, as `gsettings get` prints it back.
  # A schema can be absent even where gsettings exists -- it ships with glib, so
  # a non-GNOME box has the binary and none of these schemas. Report and carry
  # on rather than abandoning the keys that would have worked.
  local now
  now=$(gsettings get "$1" "$2" 2>/dev/null) || {
    echo "  skipped $1 $2 (no such schema)"
    return
  }
  [ "$now" = "$3" ] && return
  gsettings set "$1" "$2" "$3"
  CHANGED=1
}
pin org.gnome.desktop.input-sources          xkb-options "['caps:ctrl_modifier']"
pin org.gnome.settings-daemon.plugins.power  idle-dim    false
pin org.gnome.desktop.session                idle-delay  "uint32 0"

STATUS=ok
[ "$CHANGED" = 1 ] && STATUS=set
echo "  $STATUS: caps lock as control, no idle dim or blank"
