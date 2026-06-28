#!/bin/bash
# GNOME settings configuration
# Run this script to apply GNOME desktop settings

set -e

echo "Applying GNOME settings..."

# Map Caps Lock to Control
echo "  - Mapping Caps Lock to Control"
gsettings set org.gnome.desktop.input-sources xkb-options "['caps:ctrl_modifier']"

echo "Done! GNOME settings applied."
