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
echo "Done. Restart your shell or run: source ~/.zshrc"
