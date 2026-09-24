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
  # A Mac only grows ~/Library/LaunchAgents once something installs an agent, so
  # on a fresh account the sed redirect below has nowhere to write -- and under
  # `set -e` that takes the rest of the install with it.
  mkdir -p "$(dirname "$plist")"
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
  # The agent below only means anything under System Settings > Appearance >
  # Auto. theme-sync.sh reads AppleInterfaceStyle, and a manually pinned Light or
  # Dark never changes, so it would sync once and then track nothing -- which is
  # exactly what happened here: a terminal sitting in dark at 4pm, following a
  # system that had been told to stay dark. The script's own header assumed Auto
  # and nothing asserted it.
  #
  # Auto is AppleInterfaceStyleSwitchesAutomatically. The current shade is the
  # presence (Dark) or absence (Light) of AppleInterfaceStyle, which macOS owns
  # once Auto is on -- so clearing it just means "light until the daemon says
  # otherwise", and it will say otherwise at the next sunset. Only done when Auto
  # is off, so a deliberate pin is overridden once, not on every run.
  if [ "$(defaults read -g AppleInterfaceStyleSwitchesAutomatically 2>/dev/null)" = 1 ]; then
    echo "  ok: appearance follows the sun"
  else
    defaults write -g AppleInterfaceStyleSwitchesAutomatically -bool true
    defaults delete -g AppleInterfaceStyle 2>/dev/null || true
    # SystemUIServer caches the appearance; without this the menu bar keeps the
    # old one until something else restarts it.
    killall SystemUIServer 2>/dev/null || true
    echo "  set: appearance to Auto (was pinned)"
  fi
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
echo "Xcode Command Line Tools:"
# git, clang, make and the macOS SDK all live here, and a new Mac has none of
# them -- the /usr/bin/git it ships is a stub whose only trick is to raise the
# install dialog. Homebrew's installer would pull the tools in on its own, but
# doing it first means git exists before anything wants it, and one dialog to
# agree to rather than two prompts interleaved.
#
# `xcode-select --install` hands the work to a GUI installer and returns
# immediately, so this has to wait for it rather than run on into a brew
# install that has no compiler yet.
if [ -z "$IS_MACOS" ]; then
  echo "  skipped (macOS only)"
else
  if ! xcode-select -p &>/dev/null; then
    echo "  requesting install (agree to the dialog macOS just opened)..."
    xcode-select --install 2>/dev/null || true
    # Cap the wait rather than spin forever: someone who dismissed the dialog, or
    # a download that died, should get the script back instead of a hung terminal.
    CLT_WAITED=0
    while ! xcode-select -p &>/dev/null && [ "$CLT_WAITED" -lt 1800 ]; do
      sleep 10
      CLT_WAITED=$((CLT_WAITED + 10))
    done
  fi
  # One report for both paths -- already there, and just waited for.
  if CLT_PATH=$(xcode-select -p 2>/dev/null); then
    echo "  ok: $CLT_PATH"
  else
    echo "  WARNING: command line tools still missing after 30m"
    echo "  finish the install, or run: xcode-select --install"
  fi
fi

echo ""
echo "Homebrew:"
# Everything the macOS half of this script installs comes out of the Brewfile --
# the nerd font alacritty.toml names, VLC, zed, rbenv, and the CLI tools the zsh
# aliases assume are there. Every one of those blocks skips itself when brew is
# missing, which on a new Mac is all of them, silently: the install "succeeds"
# and leaves a machine with an alacritty that cannot find its font. So bootstrap
# brew rather than skip past it. Its installer asks for sudo on its own, which
# is why this script must not be run under sudo (see the top).
if [ -n "$HAVE_BREW" ]; then
  echo "  ok: $(brew --version | head -1)"
elif [ -n "$IS_MACOS" ] && [ ! -t 0 ] && ! sudo -n true 2>/dev/null; then
  # Homebrew's installer drops into non-interactive mode when stdin is not a
  # tty, and its first act is a sudo check that then has nowhere to prompt --
  # it fails with "Need sudo access on macOS", which reads like a permissions
  # problem and is not one. Nothing here can supply a password, so say what to
  # do rather than run an installer that is guaranteed to fail.
  #
  # A tty is not the real requirement though, sudo working is: with credentials
  # already cached the non-interactive install goes through, which is what makes
  # this reachable from a pipe or an agent shell at all. Hence `sudo -n true`
  # rather than `[ -t 0 ]` alone, short-circuited so a normal run never calls it.
  echo "  skipped: no terminal for homebrew's sudo prompt, and no cached sudo"
  echo "  run ./install.sh in a terminal, or run 'sudo -v' there first and retry"
elif [ -n "$IS_MACOS" ]; then
  echo "  installing homebrew (asks for your password)..."
  # Say non-interactive outright when stdin is not a tty. The installer would
  # work it out on its own, but only after a "press RETURN to continue" that
  # nothing is going to answer. Empty is what it checks for, so a tty run stays
  # interactive.
  if [ -t 0 ]; then BREW_NI=""; else BREW_NI=1; fi
  if NONINTERACTIVE="$BREW_NI" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    # A just-installed brew is not on this shell's PATH yet, and the prefix
    # differs by arch -- /opt/homebrew on Apple Silicon, /usr/local on Intel.
    # shellenv rather than a bare PATH prepend, so the rest of the run gets
    # HOMEBREW_PREFIX and MANPATH too.
    for p in /opt/homebrew /usr/local; do
      if [ -x "$p/bin/brew" ]; then eval "$("$p/bin/brew" shellenv)"; break; fi
    done
    command -v brew &>/dev/null && HAVE_BREW=1
  fi
  if [ -z "$HAVE_BREW" ]; then
    echo "  WARNING: homebrew install failed; everything below that needs it will be skipped"
  fi
else
  echo "  skipped (macOS only; linux blocks below use apt or upstream installers)"
fi

echo ""
if [ -n "$HAVE_BREW" ] && [ -f "$DOTFILES/Brewfile" ]; then
  echo "Brew:"
  # Not fatal. A cask whose app or font was already installed by hand stops at
  # "It seems there is already an App at ...", and brew bundle then exits
  # nonzero for the whole file -- which under `set -e` would take VLC, ruby,
  # python, uv and everything below it with it, over one app that is already
  # there. `brew install --cask --force <name>` adopts it if you want brew to
  # own it from then on.
  brew bundle install --file="$DOTFILES/Brewfile" --quiet ||
    echo "  WARNING: some brew entries failed (see above); continuing"
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
  # macOS 26 and 27 gate default-handler changes behind a LaunchServices consent
  # dialog. It is not duti's: `duti -s` returns 0 in ~20ms while the prompt is
  # still on screen, so the old code here could not even tell whether a type had
  # been set -- it counted requests and called them results -- and a new Mac meant
  # one dialog per type. duti has no flag for this; System Settings goes through
  # the same API.
  #
  # So write the store rather than calling the API. LSHandlers in
  # com.apple.launchservices.secure is where LaunchServices keeps these. A write
  # on its own changes nothing -- the entry lands in the plist and the live
  # database never sees it -- but lsd re-reads the domain when it restarts, and
  # killing it is enough. No rebuild, no dialog, verified in both directions and
  # for entries that did not exist yet.
  #
  # duti stays, for reading: it is the only honest check that LaunchServices took
  # what we wrote, rather than that we wrote it.
  #
  # UTIs only. `duti -s <ext>` resolved the extension and wrote a UTI entry
  # anyway, so the 23-extension list this replaces was 23 ways of writing these
  # 20 -- mp4 is public.mpeg-4, mov and qt are com.apple.quicktime-movie, mpg and
  # mpeg are public.mpeg, ogv and ogm are org.xiph.ogg-video, and so on.
  VLC_UTI="public.movie public.video public.avi public.mpeg public.mpeg-4
    public.mpeg-2-transport-stream public.avchd-mpeg-2-transport-stream
    public.3gpp com.apple.quicktime-movie com.apple.m4v-video
    com.microsoft.windows-media-wmv com.microsoft.advanced-systems-format
    org.matroska.mkv org.webmproject.webm org.xiph.ogg-video org.videolan.divx
    org.videolan.vob com.adobe.flash.video com.real.realmedia
    com.real.realmedia-vbr"
  VLC_ID=org.videolan.vlc
  if [ ! -d "/Applications/VLC.app" ]; then
    echo "  WARNING: /Applications/VLC.app missing (brew bundle should have installed the cask)"
  elif ! command -v duti &>/dev/null; then
    echo "  WARNING: duti not on PATH, leaving video associations alone"
  else
    # Half of these never need an entry: VLC declares mkv, vob, divx, wmv and the
    # real types itself and wins them unopposed, so only what disagrees is written.
    VLC_N=$(echo $VLC_UTI | wc -w | tr -d ' ')
    VLC_TODO=""
    for u in $VLC_UTI; do
      [ "$(duti -d "$u" 2>/dev/null | tail -1)" = "$VLC_ID" ] || VLC_TODO="$VLC_TODO $u"
    done
    VLC_WANT=$(echo $VLC_TODO | wc -w | tr -d ' ')
    if [ "$VLC_WANT" -eq 0 ]; then
      echo "  ok: already default for $VLC_N video types"
    elif ! command -v python3 &>/dev/null; then
      # Nothing to edit a plist with, so the API and its dialogs it is.
      for u in $VLC_TODO; do duti -s "$VLC_ID" "$u" all 2>/dev/null || true; done
      echo "  asked duti for $VLC_WANT of $VLC_N types (macOS prompts for each)"
    else
      VLC_DOMAIN=com.apple.LaunchServices/com.apple.launchservices.secure
      VLC_TMP="$(mktemp -d)"
      defaults export "$VLC_DOMAIN" "$VLC_TMP/handlers.plist"
      python3 - "$VLC_TMP/handlers.plist" "$VLC_ID" $VLC_TODO <<'PLIST'
import plistlib, sys, time
path, app, utis = sys.argv[1], sys.argv[2], sys.argv[3:]
with open(path, 'rb') as fh:
    d = plistlib.load(fh)
handlers = d.setdefault('LSHandlers', [])
# Seconds since 2001, the epoch every other entry in here is stamped in.
now = int(time.time()) - 978307200
for uti in utis:
    entry = next((h for h in handlers if h.get('LSHandlerContentType') == uti), None)
    if entry is None:
        entry = {'LSHandlerContentType': uti}
        handlers.append(entry)
    entry['LSHandlerRoleAll'] = app
    entry['LSHandlerModificationDate'] = now
    entry['LSHandlerPreferredVersions'] = {'LSHandlerRoleAll': '-'}
with open(path, 'wb') as fh:
    plistlib.dump(d, fh)
PLIST
      # Through defaults, not straight at the file: cfprefsd holds this domain in
      # memory and would write its own copy back over ours.
      defaults import "$VLC_DOMAIN" "$VLC_TMP/handlers.plist"
      rm -rf "$VLC_TMP"
      # launchd brings lsd back by itself; the sleep is for the re-read.
      killall lsd 2>/dev/null || true
      sleep 2
      VLC_SET=0
      for u in $VLC_TODO; do
        [ "$(duti -d "$u" 2>/dev/null | tail -1)" = "$VLC_ID" ] && VLC_SET=$((VLC_SET + 1))
      done
      if [ "$VLC_SET" -eq "$VLC_WANT" ]; then
        echo "  ok: set $VLC_SET of $VLC_N video types, no dialogs"
      else
        echo "  WARNING: $((VLC_WANT - VLC_SET)) of $VLC_WANT types did not take"
        echo "  if macOS has closed this off, duti -s <uti> all still works, with a prompt each"
      fi
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
  # ruby-build compiles ruby and its openssl from source, which takes minutes
  # before it would discover a broken toolchain -- and the failure it prints is
  # a wall of make output ending in a linker error, which says nothing about the
  # cause. Link a two-line C file first: same failure, immediately, with the one
  # thing worth knowing. Seen here as an SDK the linker is older than, where
  # `xcrun --show-sdk-path` resolves to a leftover newer SDK whose .tbd files
  # name an architecture this ld cannot parse.
  cc_links() {
    local t rc
    t=$(mktemp -d)
    printf 'int main(){return 0;}\n' >"$t/t.c"
    cc -o "$t/t" "$t/t.c" >/dev/null 2>&1
    rc=$?
    rm -rf "$t"
    return $rc
  }
  # A bare `system` is rbenv saying it has no ruby of its own, so it reads the
  # same as no answer at all. Probed once: both branches below ask this.
  # `|| true` because grep exits 1 when it filters everything out, and a bare
  # assignment -- unlike the condition this replaced -- is not protected from
  # `set -e` at the top of the file.
  RB_GLOBAL=$(rbenv global 2>/dev/null | grep -v '^system$' || true)
  if [ -z "$RB_GLOBAL" ] && ! cc_links; then
    RB_SDK=$(xcrun --show-sdk-path 2>/dev/null || true)
    echo "  WARNING: skipping ruby install, this toolchain cannot link a C program"
    echo "  sdk in use: ${RB_SDK:-unknown}"
    echo "  cc -o t t.c on an empty main() is enough to reproduce it"
    # xcrun picks the highest-numbered SDK it finds, not the one MacOSX.sdk
    # points at -- so a beta SDK left behind by an older toolchain outranks the
    # current one, and ld cannot read the .tbd files it ships. Moving it aside
    # is enough; name the exact command, since guessing it from the linker
    # error is the hard part.
    if [ -n "$RB_SDK" ] && [ -d "$RB_SDK" ] &&
       [ "$(readlink "$(dirname "$RB_SDK")/MacOSX.sdk")" != "$(basename "$RB_SDK")" ]; then
      echo "  a newer sdk than this linker understands is the usual cause:"
      echo "    sudo mv '$RB_SDK' '$RB_SDK.disabled'"
    fi
  elif [ -z "$RB_GLOBAL" ]; then
    RB_LATEST=$(rbenv install -l 2>/dev/null | grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | tail -1)
    if [ -n "$RB_LATEST" ]; then
      echo "  installing ruby $RB_LATEST (compiles from source, takes a few minutes)"
      rbenv install -s "$RB_LATEST" && rbenv global "$RB_LATEST" && rbenv rehash
    else
      echo "  WARNING: could not determine a ruby version to install"
    fi
  else
    echo "  ok: ruby $RB_GLOBAL"
  fi
else
  echo "  WARNING: rbenv not on PATH after install"
fi

echo ""
echo "Gems:"
# Gems install into the active rbenv version's prefix, so this needs no sudo.
if [ "$(command -v gem 2>/dev/null)" = /usr/bin/gem ]; then
  # The comment above holds only once rbenv has a ruby. Until then `gem` is
  # macOS's system ruby 2.6, whose gem dir under /Library/Ruby is root-owned:
  # every install there fails on permissions, and the way to make it not fail
  # is the sudo this block deliberately avoids.
  echo "  skipped (only macOS system ruby; nothing to install into yet)"
elif command -v gem &>/dev/null; then
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
echo "Node:"
# fnm came from the Brewfile alone, and the Brewfile only runs on macOS -- so a
# Linux box got zsh/40-tools.zsh's `fnm env --use-on-cd` guard, found no fnm,
# and silently had no node manager at all. Upstream's installer fills that in.
# It installs fnm and nothing else -- unlike the Ruby block above, which also
# builds a ruby -- so a node version still comes from `fnm install --lts`.
#
# --skip-shell is not optional. Without it the installer appends an fnm block to
# ~/.zshrc with `tee -a`, which follows the symlink and writes those lines into
# this repo's zshrc -- where 40-tools.zsh already runs the same eval.
#
# --install-dir because its default on Linux is ~/.local/share/fnm, which is on
# no PATH; ~/.local/bin is the one 00-path.zsh exports. On macOS the script
# shells out to `brew install fnm` unless --force-install, which never comes up
# here: the Brewfile got there first and command -v skips the whole block. The
# releases are .zip only, so a minimal box needs unzip for this to land.
if command -v fnm &>/dev/null; then
  echo "  ok: $(fnm --version)"
else
  curl -fsSL https://fnm.vercel.app/install |
    bash -s -- --install-dir "$HOME/.local/bin" --skip-shell ||
    echo "  WARNING: fnm install failed"
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
echo "herdr:"
# herdr.dev's installer, the same shape as uv and zoxide above: a prebuilt
# binary in ~/.local/bin, which zshrc has on PATH, on macOS and Linux alike.
# Nothing here installed it before, so a fresh machine got herdr.toml, the chpwd
# hook in zsh/35-herdr.zsh and no herdr -- the alacritty story the Brewfile
# tells. The config half above links config.toml whether or not this runs.
#
# Not brew's formula: brew is only installed by this script on macOS, so the apt
# path would still need this, and the installer reads the same latest.json
# manifest `herdr update` does -- so an install and a later self-update agree on
# what "latest" is, where a brew copy and `herdr update` would fight over the
# same binary. It checksums the download against that manifest before moving it
# into place.
#
# HERDR_INSTALL_DIR is the installer's own override; passed explicitly so this
# does not depend on its default staying ~/.local/bin.
if command -v herdr &>/dev/null; then
  echo "  ok: $(herdr --version)"
else
  curl -fsSL https://herdr.dev/install.sh | HERDR_INSTALL_DIR="$HOME/.local/bin" sh ||
    echo "  WARNING: herdr install failed"
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
# Upstream's install.sh on both platforms, not the homebrew formula: core
# bottles it for Sonoma only, so on Intel Tahoe brew builds it from source and
# drags rust in first -- the same trap the Brewfile calls out for uv. Same shape
# as uv, zoxide and herdr, a binary in ~/.local/bin, which zshrc has on PATH.
#
# It resolves the tag through the GitHub API rather than /latest/download, so it
# can be rate-limited on a shared IP, and it verifies the .sha256 that ships
# beside the tarball -- which the hand-rolled fetch this replaced never did.
# That check is `sha256sum -c`, and sha256sum is not a tool macOS has always had
# (it is /sbin/sha256sum here on 27); on an older release only shasum exists and
# the installer stops there, so the warning below is the answer, or coreutils.
if command -v cloudflare-speed-cli &>/dev/null; then
  echo "  ok: $(cloudflare-speed-cli --version)"
else
  curl -fsSL https://raw.githubusercontent.com/kavehtehrani/cloudflare-speed-cli/main/install.sh | sh ||
    echo "  WARNING: cloudflare-speed-cli install failed"
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
echo "Vim plugins:"
# The Vim section above installs vim-plug and links plugins.vim, then stops --
# so a new machine opened vim on 20 `Plug` lines with an empty ~/.vim/plugged
# behind them. This is the `vimup` alias in zsh/20-aliases.zsh (PlugInstall,
# PlugUpdate, PlugUpgrade), run once here so the first vim on a fresh box is the
# configured one. Keep the two in step. It lives down here rather than beside
# the vim links because it clones 20 repos over the network: ~6s cold, ~3s when
# everything is already present.
#
# --sync on the two that fetch, because vim-plug drives its clones as async jobs
# and would otherwise hit `qa` before they finish. PlugUpgrade is plug.vim
# updating itself, which pairs with the curl bootstrap above.
#
# Run through `vim -es`, and the exit status deliberately ignored: ex mode
# misparses the line continuations in plug.vim (E10) and quits 1 even when every
# clone succeeded, so ~/.vim/plugged is the thing worth believing.
if ! command -v vim &>/dev/null; then
  echo "  skipped (no vim on PATH)"
elif [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
  echo "  skipped (vim-plug missing; rerun the Vim section)"
else
  vim -es -u "$HOME/.vimrc" -i NONE \
    +'PlugInstall --sync' +'PlugUpdate --sync' +PlugUpgrade +qa \
    </dev/null >/dev/null 2>&1 || true
  VIM_PLUGS=$(ls "$HOME/.vim/plugged" 2>/dev/null | wc -l | tr -d ' ')
  if [ "$VIM_PLUGS" -gt 0 ]; then
    echo "  ok: $VIM_PLUGS plugins in ~/.vim/plugged"
  else
    echo "  WARNING: nothing landed in ~/.vim/plugged, run vimup by hand"
  fi
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
