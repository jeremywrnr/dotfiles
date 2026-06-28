# Dotfiles

Personal configuration files for Ubuntu/Linux systems.

## Quick Start

On a new machine:

```bash
git clone <your-repo-url> ~/code/dotfiles
cd ~/code/dotfiles
./install.sh
```

The install script is idempotent and safe to run multiple times.

## What's Configured

### GNOME Settings
- **Caps Lock → Control**: Maps Caps Lock key to act as Control

## Manual Configuration

If you prefer to apply settings manually:

```bash
# GNOME settings
./gnome-settings.sh
```

## Reverting Changes

To revert GNOME keyboard settings to defaults:

```bash
gsettings reset org.gnome.desktop.input-sources xkb-options
```

## Adding More Configurations

1. Add your config files/scripts to this directory
2. Update `install.sh` to apply them
3. Document them in this README
