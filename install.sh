#!/bin/bash
# install.sh — symlink dotfiles into place
set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

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

echo "Installing dotfiles from $DOTFILES"
echo ""

HAVE_BREW=""
command -v brew &>/dev/null && HAVE_BREW=1

if [ -n "$HAVE_BREW" ] && [ -f "$DOTFILES/Brewfile" ]; then
  echo "Brew:"
  brew bundle install --file="$DOTFILES/Brewfile" --quiet
  echo ""
fi

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
  AGENT="com.jeremy.alacritty-theme"
  PLIST="$HOME/Library/LaunchAgents/$AGENT.plist"
  sed "s|__DOTFILES__|$DOTFILES|g" "$DOTFILES/alacritty/$AGENT.plist" >"$PLIST"
  launchctl bootout "gui/$UID/$AGENT" 2>/dev/null || true
  launchctl bootstrap "gui/$UID" "$PLIST"
  echo "  loaded: $AGENT (light/dark follows macOS appearance)"
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

echo ""
echo "GameCube adapter:"
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
echo "uv:"
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
echo "Oh My Zsh theme:"
if [ -d "$HOME/.oh-my-zsh/custom/themes" ]; then
  link oh-my-zsh/themes/jwrnr.zsh-theme .oh-my-zsh/custom/themes/jwrnr.zsh-theme
else
  echo "  skipped (oh-my-zsh not installed)"
fi

echo ""
echo "GNOME Settings:"
if command -v gsettings &>/dev/null && [ -f "$DOTFILES/linux/gnome-settings.sh" ]; then
  "$DOTFILES/linux/gnome-settings.sh"
else
  echo "  skipped (gsettings not found or linux/gnome-settings.sh missing)"
fi

echo ""
echo "Done. Restart your shell or run: source ~/.zshrc"
