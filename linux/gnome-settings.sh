#!/bin/bash
# GNOME settings configuration
# Run this script to apply GNOME desktop settings

set -e

echo "Applying GNOME settings..."

# Map Caps Lock to Control
echo "  - Mapping Caps Lock to Control"
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:ctrl_modifier']"

# Never dim or blank the screen on inactivity. idle-delay 0 means the idle
# timer never fires, so the screensaver lock never triggers either -- lock
# on manual Super+L and on resume from suspend still work.
echo "  - Disabling idle screen dimming and blanking"
gsettings set org.gnome.settings-daemon.plugins.power idle-dim false
gsettings set org.gnome.desktop.session idle-delay 0

echo "Done! GNOME settings applied."
