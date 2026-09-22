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
# __HOME__ is stamped in too, for the WatchPaths and friends that take a literal
# path and get no ~ expansion from launchd.
# $1: plist in the repo. $2: what it does, for the log line.
load_agent() {
  local agent plist
  agent=$(basename "$1" .plist)
  plist="$HOME/Library/LaunchAgents/$agent.plist"
  sed -e "s|__DOTFILES__|$DOTFILES|g" -e "s|__HOME__|$HOME|g" "$1" >"$plist"
  launchctl bootout "gui/$UID/$agent" 2>/dev/null || true
  launchctl bootstrap "gui/$UID" "$plist"
  echo "  loaded: $agent ($2)"
}

echo "Installing dotfiles from $DOTFILES"
echo ""

HAVE_BREW=""
command -v brew &>/dev/null && HAVE_BREW=1

# Two different questions that used to share one answer. HAVE_BREW is about the
# brew binary, which the Brewfile, VLC and rbenv blocks genuinely need; IS_MACOS
# is about launchd, ~/Library, `defaults` and osxkeychain, all of which a Mac has
# whether or not brew is installed.
IS_MACOS=""
[ "$(uname -s)" = Darwin ] && IS_MACOS=1

if command -v apt-get &>/dev/null; then
  echo "APT keys:"
  KEYRING=/etc/apt/keyrings/yarn-archive-keyring.gpg
  if [ ! -f "$KEYRING" ]; then
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee "$KEYRING" > /dev/null
    echo "  installed: yarn keyring"
  else
    echo "  ok: yarn keyring"
  fi
  echo ""

  # Packages the Brewfile covers on macOS. Without this block they were simply
  # absent on Linux -- the media backends behind bin/conv, bin/to-mp4 and
  # bin/set-media-date were commands that could never run, and `tree` was an
  # alias in zshrc pointing at a binary that was never installed.
  echo "APT packages:"
  # heif-convert (libheif-examples) matters because apt's ImageMagick is built
  # without a HEIC delegate, so `conv jpg *.heic` has no backend without it.
  APT_WANT="ffmpeg imagemagick librsvg2-bin libimage-exiftool-perl rdfind libheif-examples tree iperf3"
  # rbenv compiles ruby from source, so these are its build dependencies.
  APT_WANT="$APT_WANT autoconf patch libssl-dev libyaml-dev libreadline-dev libffi-dev libgmp-dev libncurses-dev libdb-dev uuid-dev"
  # Stand-ins for macOS `mo status`: btop covers CPU, memory, disk and
  # network. apt ships btop 1.3.0, which predates btop's own GPU support
  # (added in 1.4.0), so the iGPU needs a second tool. nvtop is NOT it --
  # Noble only has 3.0.2, which on i915 reports utilization and warns that
  # memory, power, fan and temperature are unsupported. intel_gpu_top reads
  # the i915 perf counters directly: per-engine busy, frequency, RC6 and
  # IMC bandwidth. It needs perf access, hence the setcap below.
  APT_WANT="$APT_WANT btop intel-gpu-tools"
  APT_MISSING=""
  for p in $APT_WANT; do
    dpkg -s "$p" &>/dev/null || APT_MISSING="$APT_MISSING $p"
  done
  if [ -n "$APT_MISSING" ]; then
    echo "  installing:$APT_MISSING"
    # This script runs under `set -e`; a failed install must not abort the
    # symlinking that follows.
    sudo apt-get install -y $APT_MISSING || echo "  WARNING: apt install failed"
  else
    echo "  ok: $APT_WANT"
  fi
  echo ""
fi

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
  if [ -n "$IS_MACOS" ]; then GIT_CRED=osxkeychain; else GIT_CRED="cache --timeout=86400"; fi
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
if [ -n "$IS_MACOS" ]; then
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
echo "Screenshots:"
# Two captures in one: the file on disk stays the record, and the agent puts a
# copy of it on the clipboard as it lands, which no combination of modifier keys
# will do on its own. screenshot-defaults.sh pins the capture location the agent
# watches, the format it reads back, and the preview thumbnail that would
# otherwise delay both.
if [ -n "$IS_MACOS" ]; then
  "$DOTFILES/screenshot/screenshot-defaults.sh"
  load_agent "$DOTFILES/screenshot/com.jeremy.screenshot-clip.plist" \
    "new screenshots also land on the clipboard"
else
  echo "  skipped (macOS only)"
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
echo "Fonts:"
# Alacritty's configured family must actually exist. If it doesn't, fontconfig
# silently falls back to a proportional face (Noto Sans), which Alacritty then
# draws on a fixed cell grid — every narrow glyph gets padded and words come out
# looking like "i n s t a l l".
if [ -n "$HAVE_BREW" ]; then
  echo "  skipped (font-jetbrains-mono-nerd-font cask in Brewfile)"
elif fc-list :family 2>/dev/null | grep -qi "JetBrainsMono Nerd Font Mono"; then
  echo "  ok: JetBrainsMono Nerd Font Mono"
else
  FONTDIR="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
  FONTTMP="$(mktemp -d)"
  trap 'rm -rf "$FONTTMP"' EXIT
  echo "  downloading JetBrainsMono Nerd Font..."
  # .tar.xz, not the .zip: same 32 faces, 7MB instead of 134MB
  curl -fsSL -o "$FONTTMP/JetBrainsMono.tar.xz" \
    https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz
  mkdir -p "$FONTDIR"
  # Only the Mono + default faces. The NL (no-ligature) and Propo (proportional)
  # variants ship in the same archive; Propo would reintroduce the very bug this
  # block exists to prevent.
  tar -xJf "$FONTTMP/JetBrainsMono.tar.xz" -C "$FONTDIR" --wildcards \
    'JetBrainsMonoNerdFont-*.ttf' 'JetBrainsMonoNerdFontMono-*.ttf'
  fc-cache -f "$HOME/.local/share/fonts" >/dev/null
  echo "  installed: $FONTDIR"
fi

echo ""
echo "Zed:"
link zed/settings.json .config/zed/settings.json

echo ""
echo "MIME associations:"
# XDG associations and .desktop launchers. macOS resolves file types through
# LaunchServices and reads none of this, so linking it there would only leave
# dead files in ~/.config and ~/.local/share.
if [ -z "$IS_MACOS" ]; then
  link linux/mimeapps.list             .config/mimeapps.list
  link linux/desktop-entry-launcher.desktop .local/share/applications/desktop-entry-launcher.desktop

  # AppImages live in ~/Applications behind an unversioned symlink, so upgrading
  # only means repointing the symlink — the .desktop entry keeps working.
  if [ -e "$HOME/Applications/Slippi-Launcher.AppImage" ]; then
    link linux/slippi-launcher.desktop .local/share/applications/slippi-launcher.desktop
  else
    echo "  skip: linux/slippi-launcher.desktop (no ~/Applications/Slippi-Launcher.AppImage)"
  fi

  if command -v update-desktop-database &>/dev/null; then
    update-desktop-database "$HOME/.local/share/applications/"
    echo "  updated desktop database"
  fi
else
  echo "  skipped (Linux only)"
fi

echo ""
echo "GameCube adapter:"
# A systemd user unit and a udev rule; macOS has neither, and without this
# guard it got the unit symlinked into ~/.config/systemd and was told to
# install a udev rule into an /etc/udev that does not exist.
if [ -z "$IS_MACOS" ]; then
  link linux/gamecube/wii-u-gc-adapter.service .config/systemd/user/wii-u-gc-adapter.service
  # Deliberately not enabled at boot: while it runs, Dolphin cannot claim the
  # adapter over libusb and reports "Adapter Not Detected". See linux/gamecube/readme.md.
  if command -v systemctl &>/dev/null; then
    systemctl --user daemon-reload 2>/dev/null || true
  fi
  if [ -e /etc/udev/rules.d/51-gcadapter.rules ] &&
     cmp -s "$DOTFILES/linux/gamecube/51-gcadapter.rules" /etc/udev/rules.d/51-gcadapter.rules; then
    echo "  ok: /etc/udev/rules.d/51-gcadapter.rules"
  else
    echo "  udev rule needs root, run:"
    echo "    sudo install -m644 $DOTFILES/linux/gamecube/51-gcadapter.rules /etc/udev/rules.d/51-gcadapter.rules"
    echo "    sudo udevadm control --reload-rules && sudo udevadm trigger"
  fi
else
  echo "  skipped (Linux only)"
fi

echo ""
echo "GPU monitoring:"
# intel_gpu_top reads i915 perf counters, which are privileged. Without
# CAP_PERFMON it exits with "Failed to initialize PMU" unless run under sudo.
if ! command -v intel_gpu_top &>/dev/null; then
  echo "  skipped (intel_gpu_top not installed)"
elif getcap /usr/bin/intel_gpu_top 2>/dev/null | grep -q cap_perfmon; then
  echo "  ok: cap_perfmon on intel_gpu_top"
else
  echo "  perf access needs root, run:"
  echo "    sudo setcap cap_perfmon+ep /usr/bin/intel_gpu_top"
fi

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
echo "Python:"
# Homebrew and most distros ship `python3` but no bare `python`, so that name
# falls through to whatever else is on PATH. On this machine that was a
# MacPorts 3.11 from 2024 that `port` itself can no longer manage -- a stale
# interpreter winning a name the live one never claims. ~/.local/bin sits ahead
# of /opt/local/bin (see zsh/00-path.zsh), so one symlink points `python` at
# the same interpreter as `python3`, in scripts as well as shells. PEP 394
# leaves the unversioned name to the distributor, so this is ours to set.
if command -v python3 &>/dev/null; then
  PY3="$(command -v python3)"
  mkdir -p "$HOME/.local/bin"
  ln -sf "$PY3" "$HOME/.local/bin/python"
  echo "  ok: python -> $PY3 ($("$PY3" -V 2>&1 | cut -d' ' -f2))"
else
  echo '  WARNING: no python3 on PATH, leaving python alone'
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
# cloudflare-speed-cli, not Ookla's. Most Ookla servers are hosted by ISPs
# inside their own networks, and ISPs have both the motive and the track record
# to give that traffic a clear lane -- so the number flatters the one path it
# measures. Cloudflare's edge is an ordinary internet destination, and the CLI
# reports latency under load, jitter and packet loss, which is what decides
# whether a link feels fast, rather than peak Mbit alone.
#
# The prebuilt release binary on both platforms, not the homebrew formula:
# core bottles it for Sonoma only, so on Intel Tahoe brew builds it from source
# and drags rust in first -- the same trap the Brewfile calls out for uv. Same
# shape as uv and zoxide above, a binary in ~/.local/bin, which zshrc has on
# PATH.
if command -v cloudflare-speed-cli &>/dev/null; then
  echo "  ok: $(cloudflare-speed-cli --version)"
else
  CF_HOST="$(uname -s)-$(uname -m)"
  case "$CF_HOST" in
    Darwin-x86_64) CF_TARGET=x86_64-apple-darwin ;;
    Darwin-arm64)  CF_TARGET=aarch64-apple-darwin ;;
    Linux-x86_64)  CF_TARGET=x86_64-unknown-linux-musl ;;
    Linux-aarch64) CF_TARGET=aarch64-unknown-linux-musl ;;
    *)             CF_TARGET="" ;;
  esac
  if [ -z "$CF_TARGET" ]; then
    echo "  skipped (no build for $CF_HOST)"
  else
    # /latest/download rather than a pinned tag, for the reason rbenv gives
    # above: a hardcoded version goes stale and nothing here would notice.
    CF_DIR="cloudflare-speed-cli-$CF_TARGET"
    CF_TMP="$(mktemp -d)"
    if curl -fsSL -o "$CF_TMP/cf.tar.xz" \
        "https://github.com/kavehtehrani/cloudflare-speed-cli/releases/latest/download/$CF_DIR.tar.xz"; then
      mkdir -p "$HOME/.local/bin"
      # The tarball nests the binary in a per-target directory next to a README
      # and LICENSE; only the binary is wanted.
      tar -xf "$CF_TMP/cf.tar.xz" -C "$HOME/.local/bin" --strip-components=1 \
        "$CF_DIR/cloudflare-speed-cli"
      chmod +x "$HOME/.local/bin/cloudflare-speed-cli"
      echo "  installed to ~/.local/bin"
    else
      echo "  WARNING: cloudflare-speed-cli download failed"
    fi
    rm -rf "$CF_TMP"
  fi
fi

# `speedtest` is the name the fingers know, and on any machine that ran the
# previous version of this script it is also where Ookla's binary landed --
# aiming the name at the new tool migrates it and retires the old one in a
# single step. A symlink rather than a zsh alias so scripts, bash and
# non-interactive shells get it too, and because ~/.local/bin sits ahead of
# /usr/local/bin in zsh/00-path.zsh it also shadows a leftover brew install.
if [ -x "$HOME/.local/bin/cloudflare-speed-cli" ]; then
  ln -sf cloudflare-speed-cli "$HOME/.local/bin/speedtest"
  echo "  ok: speedtest -> cloudflare-speed-cli"
fi


echo ""
echo "GNOME Settings:"
# `command -v gsettings` alone is not enough of a check: gsettings ships with
# glib, so any Mac with a brew formula that depends on glib has the binary and
# none of the org.gnome.* schemas. gnome-settings.sh runs under `set -e`, so it
# would exit 1 on the first "No such schema" and take this script down with it
# -- hence both the platform guard and the `||`. A GNOME-less Linux box has the
# same missing schemas, which is why the fallback is not macOS-only.
if [ -n "$IS_MACOS" ]; then
  echo "  skipped (Linux only)"
elif ! command -v gsettings &>/dev/null || [ ! -f "$DOTFILES/linux/gnome-settings.sh" ]; then
  echo "  skipped (gsettings not found or linux/gnome-settings.sh missing)"
else
  "$DOTFILES/linux/gnome-settings.sh" || echo "  WARNING: gnome-settings.sh failed (no GNOME schemas?)"
fi

echo ""

# A child process cannot change its parent's environment, so `source ~/.zshrc`
# here would apply to the subshell that is about to exit and nothing else. And
# this file cannot be sourced instead: it is bash, the interactive shell is
# zsh, and `set -e` plus `exit` would take the session down with it on any
# failure. Replacing the shell is the one thing that actually works.
#
# Guarded on a tty both ways so CI, `bash install.sh | tee`, and anything
# non-interactive just finish and return, rather than exec'ing a login shell
# with nowhere to read from. DOTFILES_NO_EXEC=1 opts out by hand.
if [ -t 0 ] && [ -t 1 ] && [ -z "${DOTFILES_NO_EXEC:-}" ]; then
  echo "Done. Reloading $(basename "${SHELL:-sh}")..."
  exec "${SHELL:-/bin/zsh}" -l
else
  echo "Done. Restart your shell or run: source ~/.zshrc"
fi
