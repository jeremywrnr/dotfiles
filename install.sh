#!/bin/bash
# install.sh — symlink dotfiles into place
set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Not `sudo ./install.sh`. Under sudo every link lands in root's home, or lands
# in yours owned by root so the next ordinary run cannot replace it; brew
# refuses to run as root outright; and the launchd agent would be bootstrapped
# into gui/0 instead of your session. The only step that needs privilege is the
# apt-get in the VLC block, and it asks for its own.
if [ "$EUID" -eq 0 ] && [ -z "$DOTFILES_ALLOW_ROOT" ]; then
  echo "install.sh: run this as yourself, not with sudo." >&2
  echo "  the one step that needs root (apt-get install vlc) will prompt for it" >&2
  echo "  set DOTFILES_ALLOW_ROOT=1 to override (root-only containers)" >&2
  exit 1
fi

link() {
  local src="$DOTFILES/$1"
  local dst="$HOME/$2"

  mkdir -p "$(dirname "$dst")"

  # already points to the right place — skip
  if [ "$(readlink "$dst")" = "$src" ]; then
    echo "  ok: $dst"
    return
  fi

  # real file exists — back up once, then replace
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    if [ ! -e "$dst.bak" ]; then
      echo "  backup: $dst → $dst.bak"
      mv "$dst" "$dst.bak"
    else
      echo "  removing: $dst (backup already exists)"
      rm "$dst"
    fi
  fi

  ln -sf "$src" "$dst"
  echo "  linked: $dst"
}

# Render a launchd plist into ~/Library/LaunchAgents and (re)start it. Agents
# are addressed as gui/$UID so they run in the login session, not gui/0.
# $1: plist in the repo. $2: what it does, for the log line.
load_agent() {
  local agent plist
  agent=$(basename "$1" .plist)
  plist="$HOME/Library/LaunchAgents/$agent.plist"
  sed "s|__DOTFILES__|$DOTFILES|g" "$1" >"$plist"
  launchctl bootout "gui/$UID/$agent" 2>/dev/null || true
  launchctl bootstrap "gui/$UID" "$plist"
  echo "  loaded: $agent ($2)"
}

echo "Installing dotfiles from $DOTFILES"
echo ""

HAVE_BREW=""
command -v brew &>/dev/null && HAVE_BREW=1

echo "Shell:"
link zshrc        .zshrc
link bashrc       .bashrc

echo ""
echo "Git:"
link gitconfig    .gitconfig
link gitignore    .gitignore_global

# gitconfig includes ~/.gitconfig.local for anything that cannot be shared
# between machines. git has conditional includes for gitdir and branch but not
# for OS, so the credential helper has to be seeded here.
if [ ! -f "$HOME/.gitconfig.local" ]; then
  if [ -n "$HAVE_BREW" ]; then GIT_CRED=osxkeychain; else GIT_CRED="cache --timeout=86400"; fi
  printf '[credential]\n\thelper = %s\n' "$GIT_CRED" > "$HOME/.gitconfig.local"
  echo "  seeded: ~/.gitconfig.local (credential.helper = $GIT_CRED)"
else
  echo "  ok: ~/.gitconfig.local"
fi

echo ""
echo "Vim:"
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
  echo "  installing vim-plug..."
  curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi
link vimrc              .vimrc
link gvimrc             .gvimrc
link vim/plugins.vim    .vim/plugins.vim
link vim/settings.vim   .vim/settings.vim
link vim/mappings.vim   .vim/mappings.vim
link vim/functions.vim  .vim/functions.vim

echo ""
echo "Scripts:"
# bin/ is on PATH via zsh/00-path.zsh, so a pull that adds a script just
# works -- but git only tracks the executable bit for files it created as
# executable, so restore it for any that lost it.
if [ -d "$DOTFILES/bin" ]; then
  find "$DOTFILES/bin" -maxdepth 1 -type f ! -name '*.md' ! -perm -u+x \
    -exec chmod +x {} + 2>/dev/null || true
  echo "  ok: $(find "$DOTFILES/bin" -maxdepth 1 -type f ! -name '*.md' | wc -l | tr -d ' ') scripts on PATH"
fi

echo ""
echo "Tmux:"
link tmux.conf    .tmux.conf

echo ""
echo "Alacritty:"
link alacritty/alacritty.toml .config/alacritty/alacritty.toml

# theme.toml is a copy, not a symlink — theme-sync.sh rewrites it in place and
# alacritty's file watcher would miss a symlink swap.
#
# launchd and ~/Library exist only on macOS, and this script runs under `set -e`,
# so the plist write would abort the rest of the install on Linux. theme-sync.sh
# is macOS-only too (it reads AppleInterfaceStyle via `defaults`), so seed
# theme.toml once on Linux instead -- alacritty.toml imports it unconditionally
# and errors out on a missing import.
if [ -n "$HAVE_BREW" ]; then
  load_agent "$DOTFILES/alacritty/com.jeremy.alacritty-theme.plist" \
    "light/dark follows macOS appearance"
else
  THEME="$HOME/.config/alacritty/theme.toml"
  if [ -e "$THEME" ]; then
    echo "  ok: theme.toml"
  else
    mkdir -p "$(dirname "$THEME")"
    cp "$DOTFILES/alacritty/dark.toml" "$THEME"
    echo "  seeded: theme.toml from dark.toml (no auto light/dark on Linux yet)"
  fi
fi

echo ""
echo "Herdr:"
# herdr writes logs, sockets, and session.json into this same directory, so only
# config.toml is linked -- never the directory itself.
link herdr.toml   .config/herdr/config.toml
if command -v herdr &>/dev/null && herdr status server &>/dev/null; then
  herdr server reload-config >/dev/null && echo "  reloaded running server"
fi

echo ""
echo "Zed:"
link zed/settings.json .config/zed/settings.json

echo ""
echo "Claude Code:"
link claude/settings.json .claude/settings.json
link claude/statusline.sh .claude/statusline.sh
link claude/tab-title.sh  .claude/tab-title.sh

echo ""
echo "Misc:"
link gemrc        .gemrc
link pytest.ini   .pytest.ini
link Brewfile     .Brewfile

echo ""
echo "Oh My Zsh theme:"
if [ -d "$HOME/.oh-my-zsh/custom/themes" ]; then
  link oh-my-zsh/themes/jwrnr.zsh-theme .oh-my-zsh/custom/themes/jwrnr.zsh-theme
else
  echo "  skipped (oh-my-zsh not installed)"
fi

# Everything below installs software. It is the slow half, and it runs last so
# the config above is already in place if you bail out. Ordering inside this
# half still matters: rbenv, duti and VLC itself come from the Brewfile on
# macOS, so brew bundle has to go first or those sections would fetch their
# own copies -- or find nothing to configure.

echo ""
if [ -n "$HAVE_BREW" ] && [ -f "$DOTFILES/Brewfile" ]; then
  echo "Brew:"
  brew bundle install --file="$DOTFILES/Brewfile" --quiet
  echo ""
fi

echo "VLC:"
# VLC is a baseline install on every machine, not an optional extra: macOS gets
# it from the Brewfile cask, Ubuntu from apt. Deliberately not the snap, which
# is sandboxed and cannot read external drives or ~/ without extra plumbing.
#
# Making it the default video player then needs a different tool per platform --
# duti writes LaunchServices on macOS, xdg-mime writes mimeapps.list on Linux --
# so the two branches share nothing but the intent.
if [ -n "$HAVE_BREW" ]; then
  # Extensions cover what LaunchServices already knows about; the UTIs catch
  # the rest, including anything that declares conformance to them. duti exits
  # nonzero for a type the system has never seen, which `set -e` would treat as
  # fatal, so every call is tolerated.
  VLC_EXT="mp4 m4v mkv avi mov qt wmv flv webm mpg mpeg m2ts mts ts ogv ogm 3gp divx vob asf rm rmvb f4v"
  VLC_UTI="public.movie public.video public.avi public.mpeg public.mpeg-4 com.apple.quicktime-movie org.matroska.mkv"
  if [ ! -d "/Applications/VLC.app" ]; then
    echo "  WARNING: /Applications/VLC.app missing (brew bundle should have installed the cask)"
  elif ! command -v duti &>/dev/null; then
    echo "  WARNING: duti not on PATH, leaving video associations alone"
  else
    # macOS 26 raises a confirmation dialog for every association that really
    # changes, and duti has no flag to suppress it -- the prompt belongs to
    # LaunchServices, not duti. So only call duti for types not already
    # pointing at VLC: the first run still asks, every run after is silent.
    # `duti -x` prints three lines (name, path, bundle id) and `duti -d` one.
    # Both probes print the bundle id on a line of its own -- `duti -x` as the
    # third of three (name, path, id), `duti -d` as the only one -- so one
    # exact-line match covers extensions and UTIs alike.
    VLC_ID=org.videolan.vlc
    VLC_SET=0
    vlc_assoc() {  # $1: -x for an extension, -d for a UTI. $2: the type.
      duti "$1" "$2" 2>/dev/null | grep -qx "$VLC_ID" && return
      duti -s "$VLC_ID" "$2" all 2>/dev/null || true
      VLC_SET=$((VLC_SET + 1))
    }
    for e in $VLC_EXT; do vlc_assoc -x "$e"; done
    for u in $VLC_UTI; do vlc_assoc -d "$u"; done
    VLC_N=$(echo $VLC_EXT $VLC_UTI | wc -w | tr -d ' ')
    if [ "$VLC_SET" -eq 0 ]; then
      echo "  ok: already default for $VLC_N video types"
    else
      echo "  ok: set $VLC_SET of $VLC_N video types"
    fi
  fi
else
  if command -v vlc &>/dev/null; then
    echo "  ok: $(vlc --version 2>/dev/null | head -1)"
  elif command -v apt-get &>/dev/null; then
    echo "  installing vlc (apt may ask for your password)"
    if sudo apt-get install -y -qq vlc >/dev/null; then
      echo "  installed"
    else
      echo "  WARNING: apt-get install vlc failed"
    fi
  else
    echo "  WARNING: no apt-get here, install vlc by hand"
  fi
  # Read the mime list off vlc.desktop rather than hardcoding one, so the set
  # tracks whatever this VLC build actually claims to handle. Only video/* --
  # audio and playlists are left to whatever already owns them.
  VLC_DESKTOP=$(find /usr/share/applications "$HOME/.local/share/applications" \
    -maxdepth 1 -name vlc.desktop 2>/dev/null | head -1)
  if [ -z "$VLC_DESKTOP" ] || ! command -v xdg-mime &>/dev/null; then
    echo "  skipped associations (no vlc.desktop or no xdg-mime)"
  else
    VLC_MIME=$(grep -m1 '^MimeType=' "$VLC_DESKTOP" | cut -d= -f2- | tr ';' '\n' \
      | grep '^video/' || true)
    for m in $VLC_MIME; do xdg-mime default vlc.desktop "$m" 2>/dev/null || true; done
    echo "  ok: default for $(echo $VLC_MIME | wc -w | tr -d ' ') video mime types"
  fi
fi

echo ""
echo "Ruby:"
# apt ships rbenv 1.1.2 and a ruby-build from 2022, which cannot install any
# current ruby -- so on Linux rbenv comes from git. macOS gets it from the
# Brewfile. Both then use RBENV_ROOT=~/.rbenv, which is what zsh/15-ruby.zsh
# puts on PATH.
if [ -z "$HAVE_BREW" ]; then
  if [ -d "$HOME/.rbenv" ]; then
    echo "  ok: ~/.rbenv"
    git -C "$HOME/.rbenv" pull --quiet --ff-only 2>/dev/null || true
  else
    echo "  cloning rbenv..."
    git clone --quiet https://github.com/rbenv/rbenv.git "$HOME/.rbenv"
  fi
  RB_PLUGIN="$HOME/.rbenv/plugins/ruby-build"
  if [ -d "$RB_PLUGIN" ]; then
    echo "  ok: ruby-build"
    git -C "$RB_PLUGIN" pull --quiet --ff-only 2>/dev/null || true
  else
    echo "  cloning ruby-build..."
    git clone --quiet https://github.com/rbenv/ruby-build.git "$RB_PLUGIN"
  fi
fi

export PATH="$HOME/.rbenv/bin:$HOME/.rbenv/shims:$PATH"
if command -v rbenv &>/dev/null; then
  # Deliberately not pinned: ruby-build's list is authoritative about the
  # newest buildable stable release, and a hardcoded version goes stale.
  if [ -z "$(rbenv global 2>/dev/null | grep -v '^system$')" ]; then
    RB_LATEST=$(rbenv install -l 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -1)
    if [ -n "$RB_LATEST" ]; then
      echo "  installing ruby $RB_LATEST (compiles from source, takes a few minutes)"
      rbenv install -s "$RB_LATEST" && rbenv global "$RB_LATEST" && rbenv rehash
    else
      echo "  WARNING: could not determine a ruby version to install"
    fi
  else
    echo "  ok: ruby $(rbenv global)"
  fi
else
  echo "  WARNING: rbenv not on PATH after install"
fi

echo ""
echo "Gems:"
# Gems install into the active rbenv version's prefix, so this needs no sudo.
if command -v gem &>/dev/null; then
  for g in open-remote; do
    if gem list -i "^${g}$" &>/dev/null; then
      echo "  ok: $g"
    else
      echo "  installing: $g"
      gem install --no-document "$g" || echo "  WARNING: gem install $g failed"
    fi
  done
else
  echo "  skipped (no ruby on PATH)"
fi

echo ""
echo "uv:"
# Astral's installer on every platform, including macOS -- see the Brewfile for
# why brew's uv is unusable here. Same prebuilt binary in ~/.local/bin either way.
if ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  echo "  installed"
else
  echo "  ok: $(uv --version)"
fi

echo ""
echo "zoxide:"
# zshrc only inits zoxide when it exists, so a missing binary is silent now --
# install it so `z` actually works rather than quietly doing nothing.
if command -v zoxide &>/dev/null; then
  echo "  ok: $(zoxide --version)"
else
  # apt's zoxide lags well behind upstream, and cargo would compile from source
  # for no gain; the official installer drops a prebuilt binary on PATH.
  curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
    | sh -s -- --bin-dir "$HOME/.local/bin"
  echo "  installed to ~/.local/bin"
fi

echo ""
echo "speedtest:"
# Linux only -- the Brewfile covers macOS via the teamookla tap, and the
# tarball fetched below is a linux build.
# Ookla's static binary rather than their apt repo: packagecloud publishes no
# noble suite (dists/noble is a 404), so the repo route means pinning a 24.04
# box to jammy and quietly rotting. Same shape as uv and zoxide above -- a
# prebuilt binary in ~/.local/bin, which zshrc already puts on PATH.
# Not apt's speedtest-cli, which is the unofficial 2021 python client and
# undercounts past a few hundred Mbit.
if [ "$(uname -s)" != "Linux" ]; then
  echo "  skipped (Brewfile)"
elif command -v speedtest &>/dev/null; then
  echo "  ok: $(speedtest --version 2>/dev/null | head -1)"
else
  case "$(uname -m)" in
    x86_64)  ST_ARCH=x86_64 ;;
    aarch64) ST_ARCH=aarch64 ;;
    *)       ST_ARCH="" ;;
  esac
  if [ -z "$ST_ARCH" ]; then
    echo "  skipped (no Ookla build for $(uname -m))"
  else
    ST_VER=1.2.0
    ST_TMP="$(mktemp -d)"
    if curl -fsSL -o "$ST_TMP/speedtest.tgz" \
        "https://install.speedtest.net/app/cli/ookla-speedtest-$ST_VER-linux-$ST_ARCH.tgz"; then
      mkdir -p "$HOME/.local/bin"
      # The tarball also carries speedtest.5 and speedtest.md; only the binary
      # is wanted.
      tar -xzf "$ST_TMP/speedtest.tgz" -C "$HOME/.local/bin" speedtest
      chmod +x "$HOME/.local/bin/speedtest"
      echo "  installed to ~/.local/bin (run once to accept the license)"
    else
      echo "  WARNING: speedtest download failed"
    fi
    rm -rf "$ST_TMP"
  fi
fi

echo ""
echo "Time Machine:"

# `tm check` is macOS-only (tmutil, launchd, osascript all are), and this script
# runs under `set -e`, so guard the whole block rather than let it abort the
# rest of the install on Linux.
if [ -n "$HAVE_BREW" ]; then
  load_agent "$DOTFILES/launchd/com.jeremy.tm-check.plist" \
    "notifies when backups fall behind"

  # The default hourly cadence is what makes a silent failure survivable: a
  # backup that fails at 24h intervals gets one attempt a day to recover.
  INTERVAL=$(defaults read /Library/Preferences/com.apple.TimeMachine.plist \
    AutoBackupInterval 2>/dev/null || echo 3600)
  if [ "$INTERVAL" -gt 7200 ] 2>/dev/null; then
    echo "  WARNING: backups are only attempted every $((INTERVAL / 3600))h"
    echo "    sudo defaults write /Library/Preferences/com.apple.TimeMachine.plist AutoBackupInterval -int 3600"
  fi
else
  echo "  skipped (macOS only)"
fi

echo ""
echo "Done. Restart your shell or run: source ~/.zshrc"
