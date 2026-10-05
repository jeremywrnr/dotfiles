#!/usr/bin/env bash
# install.sh — symlink dotfiles into place
set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Not `sudo ./install.sh`. Under sudo every link lands in root's home, or lands
# in yours owned by root so the next ordinary run cannot replace it; brew
# refuses to run as root outright; and the launchd agent would be bootstrapped
# into gui/0 instead of your session. The steps that need privilege are the apt
# ones, and they ask for their own.
if [ "$EUID" -eq 0 ] && [ -z "$DOTFILES_ALLOW_ROOT" ]; then
  echo "install.sh: run this as yourself, not with sudo." >&2
  echo "  the steps that need root (the apt installs) will prompt for it" >&2
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

# Separate questions: HAVE_BREW gates what needs the brew binary (Brewfile, VLC,
# rbenv); IS_MACOS gates launchd, ~/Library, `defaults` and osxkeychain;
# IS_WSL gates reaching across into the Windows side (Windows Terminal).
IS_MACOS=""
[ "$(uname -s)" = Darwin ] && IS_MACOS=1
IS_WSL=""
grep -qi microsoft /proc/version 2>/dev/null && IS_WSL=1
HAVE_APT=""
command -v apt-get &>/dev/null && HAVE_APT=1

if [ -n "$HAVE_APT" ]; then
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
    # symlinking that follows. DEBIAN_FRONTEND=noninteractive keeps a package's
    # postinst (iperf3 asks whether to run as a daemon) from blocking on a
    # debconf dialog that a headless or backgrounded run can never answer; the
    # defaults it then takes are the ones we want anyway.
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y $APT_MISSING || echo "  WARNING: apt install failed"
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
  # theme-sync.sh follows AppleInterfaceStyle, which only changes under
  # Appearance > Auto -- a pinned Light or Dark leaves it tracking nothing. Set
  # Auto (once, only when off); macOS owns AppleInterfaceStyle from then on.
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
echo "Windows Terminal:"
# Under WSL the terminal is Windows Terminal, whose settings.json it rewrites
# itself on every change made in its UI -- so merge into it rather than link it.
# Builds GitHub Dark from alacritty/dark.toml, so the two cannot drift, and
# points every WSL profile at it, over the scheme the distro's fragment ships
# (Ubuntu's aubergine). tomllib is python 3.11+; older lands in the WARNING.
if [ -z "$IS_WSL" ]; then
  echo "  skipped (WSL only)"
else
  # cmd.exe warns about a UNC working directory, so ask it from C: instead.
  WIN_LOCAL=$(cd /mnt/c && cmd.exe /c 'echo %LOCALAPPDATA%' 2>/dev/null | tr -d '\r')
  WT_SETTINGS=""
  [ -n "$WIN_LOCAL" ] && WT_SETTINGS="$(wslpath -u "$WIN_LOCAL")/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json"
  if [ ! -f "$WT_SETTINGS" ]; then
    # Windows Terminal writes settings.json on first launch, not on install.
    echo "  skipped (no settings.json yet: open Windows Terminal once, then rerun)"
  else
    [ -e "$WT_SETTINGS.bak" ] || cp "$WT_SETTINGS" "$WT_SETTINGS.bak"
    python3 - "$WT_SETTINGS" "$DOTFILES/alacritty/dark.toml" <<'WT' ||
import json, sys, tomllib
path, palette = sys.argv[1], sys.argv[2]
with open(palette, 'rb') as fh:
    c = tomllib.load(fh)['colors']
# Windows Terminal says purple where alacritty says magenta, and brightRed for
# bright.red; it has no indexed colors, so dark.toml's two extras are dropped.
wt = lambda k: 'purple' if k == 'magenta' else k
scheme = {'name': 'GitHub Dark', **c['primary'],
          'cursorColor': c['primary']['foreground'], 'selectionBackground': '#264f78'}
scheme.update({wt(k): v for k, v in c['normal'].items()})
scheme.update({'bright' + wt(k).capitalize(): v for k, v in c['bright'].items()})
with open(path, encoding='utf-8-sig') as fh:
    raw = fh.read()
d = json.loads(raw)
# Replace in place rather than append, so a rerun leaves the order alone.
schemes = d.setdefault('schemes', [])
schemes[:] = [scheme if s.get('name') == scheme['name'] else s for s in schemes]
if scheme not in schemes:
    schemes.append(scheme)
wsl = [p for p in d.get('profiles', {}).get('list', []) if p.get('source') == 'Microsoft.WSL']
for p in wsl:
    p['colorScheme'] = scheme['name']
changed = d != json.loads(raw)
if changed:
    with open(path, 'w', encoding='utf-8') as fh:
        json.dump(d, fh, indent=4, ensure_ascii=False)
        fh.write('\n')
print(f"  {'set' if changed else 'ok'}: {scheme['name']} on {len(wsl)} WSL profile(s)")
WT
      echo "  WARNING: could not update settings.json; left as is"
  fi
fi

echo ""
echo "App switcher:"
# Undocumented Dock default: by default Cmd-Tab's overlay only renders on the
# display holding the Dock, which is disorienting with multiple monitors.
# This mirrors it onto every connected display instead.
if [ -n "$IS_MACOS" ]; then
  if [ "$(defaults read com.apple.dock appswitcher-all-displays 2>/dev/null)" = 1 ]; then
    echo "  ok: Cmd-Tab shows on all displays"
  else
    defaults write com.apple.dock appswitcher-all-displays -bool true
    killall Dock 2>/dev/null || true
    echo "  set: Cmd-Tab now shows on all displays"
  fi
else
  echo "  skipped (macOS only)"
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
echo "Screen Sharing:"
# Report only, never switched on from here: it opens the Mac to remote control,
# so that stays a deliberate per-machine choice in System Settings. When on,
# launchd listens on 5900 for Apple's VNC and checks logins against this Mac's
# own accounts. print-disabled reads without sudo; it says "enabled" on recent
# macOS and "false" (as in not disabled) on older ones.
if [ -n "$IS_MACOS" ]; then
  if launchctl print-disabled system 2>/dev/null |
    grep -qE '"com\.apple\.screensharing" => (enabled|false)'; then
    echo "  ok: on, at vnc://$(scutil --get LocalHostName).local"
  else
    echo "  off: System Settings > General > Sharing > Screen Sharing to allow VNC in"
  fi
else
  echo "  skipped (macOS only)"
fi

echo ""
echo "Herdr:"
# herdr writes logs, sockets, and session.json into this same directory, so only
# config.toml is linked -- never the directory itself.
link herdr.toml   .config/herdr/config.toml
# `herdr status server` always exits 0, even when nothing is running -- it
# just prints "not running" to stdout -- so the exit code can't gate the
# reload. --json exposes a real running:true/false to grep on instead.
if command -v herdr &>/dev/null &&
  herdr status server --json 2>/dev/null | grep -q '"running":true'; then
  herdr server reload-config >/dev/null && echo "  reloaded running server"
fi

echo ""
echo "Fonts:"
# Alacritty's configured family must actually exist. If it doesn't, fontconfig
# silently falls back to a proportional face (Noto Sans), which Alacritty then
# draws on a fixed cell grid — every narrow glyph gets padded and words come out
# looking like "i n s t a l l".
# The cask is macOS-only, so HAVE_BREW alone asked the wrong question twice: it
# skipped the download under linuxbrew, leaving exactly the proportional
# fallback this block exists to prevent, and on a brew-less Mac it fell through
# to `tar --wildcards` and `fc-cache`, neither of which stock macOS has -- both
# fatal under `set -e`.
if [ -n "$HAVE_BREW" ] && [ -n "$IS_MACOS" ]; then
  echo "  skipped (font-jetbrains-mono-nerd-font cask in Brewfile)"
elif ! command -v fc-cache &>/dev/null; then
  echo "  skipped (no fc-cache to install fonts with)"
elif fc-list :family 2>/dev/null | grep -qi "JetBrainsMono Nerd Font Mono"; then
  echo "  ok: JetBrainsMono Nerd Font Mono"
else
  FONTDIR="$HOME/.local/share/fonts/JetBrainsMonoNerdFont"
  FONTTMP="$(mktemp -d)"
  echo "  downloading JetBrainsMono Nerd Font..."
  # .tar.xz, not the .zip: same 32 faces, 7MB instead of 134MB.
  #
  # Tolerated rather than bare: this section sits near the top, so under `set -e`
  # a rate-limited or offline run would abandon every symlink below it. Cleanup
  # is explicit for the same reason the cloudflare block does it that way -- an
  # EXIT trap never fires, because this script ends by exec'ing a login shell.
  if curl -fsSL -o "$FONTTMP/JetBrainsMono.tar.xz" \
      https://github.com/ryanoasis/nerd-fonts/releases/latest/download/JetBrainsMono.tar.xz; then
    mkdir -p "$FONTDIR"
    # Only the Mono + default faces. The NL (no-ligature) and Propo
    # (proportional) variants ship in the same archive; Propo would reintroduce
    # the very bug this block exists to prevent.
    tar -xJf "$FONTTMP/JetBrainsMono.tar.xz" -C "$FONTDIR" --wildcards \
      'JetBrainsMonoNerdFont-*.ttf' 'JetBrainsMonoNerdFontMono-*.ttf'
    fc-cache -f "$HOME/.local/share/fonts" >/dev/null
    echo "  installed: $FONTDIR"
  else
    echo "  WARNING: JetBrainsMono Nerd Font download failed"
  fi
  rm -rf "$FONTTMP"
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
  link linux/mimeapps.list .config/mimeapps.list
  link linux/desktop-entry-launcher.desktop .local/share/applications/desktop-entry-launcher.desktop

  # AppImages live in ~/Applications behind an unversioned symlink, so upgrading
  # only means repointing the symlink — the .desktop entry keeps working.
  if [ -e "$HOME/Applications/Slippi-Launcher.AppImage" ]; then
    link linux/slippi-launcher.desktop .local/share/applications/slippi-launcher.desktop
  else
    echo "  skipped slippi-launcher.desktop (no ~/Applications/Slippi-Launcher.AppImage)"
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
  # `2>/dev/null || true` already covers a box without systemd, so no guard.
  systemctl --user daemon-reload 2>/dev/null || true
  GC_RULE=/etc/udev/rules.d/51-gcadapter.rules
  # cmp -s exits nonzero on a missing operand, so it answers "present and
  # identical" on its own.
  if cmp -s "$DOTFILES/linux/gamecube/51-gcadapter.rules" "$GC_RULE"; then
    echo "  ok: $GC_RULE"
  else
    echo "  udev rule needs root, run:"
    echo "    sudo install -m644 $DOTFILES/linux/gamecube/51-gcadapter.rules $GC_RULE"
    echo "    sudo udevadm control --reload-rules && sudo udevadm trigger"
  fi
else
  echo "  skipped (Linux only)"
fi

echo ""
echo "GPU monitoring:"
# intel_gpu_top reads i915 perf counters, which are privileged. Without
# CAP_PERFMON it exits with "Failed to initialize PMU" unless run under sudo.
GPU_TOP="$(command -v intel_gpu_top 2>/dev/null || true)"
if [ -z "$GPU_TOP" ]; then
  echo "  skipped (intel_gpu_top not installed)"
elif getcap "$GPU_TOP" 2>/dev/null | grep -q cap_perfmon; then
  echo "  ok: cap_perfmon on $GPU_TOP"
else
  echo "  perf access needs root, run:"
  echo "    sudo setcap cap_perfmon+ep $GPU_TOP"
fi

echo ""
echo "Claude Code:"
link claude/settings.json .claude/settings.json
link claude/statusline.sh .claude/statusline.sh
link claude/tab-title.sh  .claude/tab-title.sh

# The herdrhook filter (see claude/herdr-hook-filter): .gitattributes names it,
# but its commands live in .git/config, which a clone does not carry. Set up
# before the herdr hook step below, and a fresh checkout's ~ form smudged in
# place, so that step finds herdr's own absolute path and adds no duplicate.
git -C "$DOTFILES" config filter.herdrhook.clean "claude/herdr-hook-filter clean"
git -C "$DOTFILES" config filter.herdrhook.smudge "claude/herdr-hook-filter smudge"
CLAUDE_SETTINGS="$DOTFILES/claude/settings.json"
smudged=$("$DOTFILES/claude/herdr-hook-filter" smudge < "$CLAUDE_SETTINGS")
if [ "$smudged" != "$(cat "$CLAUDE_SETTINGS")" ]; then
  printf '%s\n' "$smudged" > "$CLAUDE_SETTINGS"
  echo "  smudged: herdr hook path in claude/settings.json"
fi

echo ""
echo "Misc:"
link gemrc        .gemrc
link Brewfile     .Brewfile

echo ""
echo "Oh My Zsh theme:"
if [ -d "$HOME/.oh-my-zsh/custom/themes" ]; then
  link oh-my-zsh/themes/jwrnr.zsh-theme .oh-my-zsh/custom/themes/jwrnr.zsh-theme
else
  echo "  skipped (oh-my-zsh not installed)"
fi

# Everything below installs software: the slow half, last so the config above
# is in place if you bail out. brew bundle goes first, since rbenv, duti and VLC
# come from the Brewfile on macOS.

echo ""
echo "Xcode Command Line Tools:"
# git, clang and the SDK; a new Mac's /usr/bin/git is only a stub. Done before
# brew so there is one dialog, not two. `xcode-select --install` returns at once
# and hands off to a GUI installer, so wait for it (capped at 30 minutes).
if [ -z "$IS_MACOS" ]; then
  echo "  skipped (macOS only)"
else
  if ! xcode-select -p &>/dev/null; then
    echo "  requesting install (agree to the dialog macOS just opened)..."
    xcode-select --install 2>/dev/null || true
    CLT_WAITED=0
    while ! xcode-select -p &>/dev/null && [ "$CLT_WAITED" -lt 1800 ]; do
      sleep 10
      CLT_WAITED=$((CLT_WAITED + 10))
    done
  fi
  if CLT_PATH=$(xcode-select -p 2>/dev/null); then
    echo "  ok: $CLT_PATH"
  else
    echo "  WARNING: command line tools still missing after 30m"
    echo "  finish the install, or run: xcode-select --install"
  fi
fi

echo ""
echo "Homebrew:"
# Bootstrapped rather than skipped: every macOS block below needs brew, and
# without it the install "succeeds" silently with nothing installed. Its
# installer asks for sudo itself, hence no `sudo ./install.sh` (see the top).
if [ -n "$HAVE_BREW" ]; then
  echo "  ok: $(brew --version | head -1)"
elif [ -n "$IS_MACOS" ] && [ ! -t 0 ] && ! sudo -n true 2>/dev/null; then
  # Without a tty the installer goes non-interactive, and its sudo check fails
  # with a misleading "Need sudo access" -- unless credentials are cached, hence
  # `sudo -n true` rather than `[ -t 0 ]` alone.
  echo "  skipped: no terminal for homebrew's sudo prompt, and no cached sudo"
  echo "  run ./install.sh in a terminal, or run 'sudo -v' there first and retry"
elif [ -n "$IS_MACOS" ]; then
  echo "  installing homebrew (asks for your password)..."
  # Explicit NONINTERACTIVE off a tty, or it waits on a RETURN nobody presses.
  if [ -t 0 ]; then BREW_NI=""; else BREW_NI=1; fi
  if NONINTERACTIVE="$BREW_NI" /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    # Not on PATH yet; the prefix differs by arch (/opt/homebrew vs /usr/local).
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
  # Install what is missing, never upgrade. `brew bundle install` upgrades every
  # outdated entry by default, and Homebrew builds no bottles for macOS Intel, so
  # there that compiles git, ffmpeg and imagemagick from source for an hour.
  # Upgrades are bin/brewup's job, which keeps to bottles. The check (~1s) lets a
  # machine with nothing missing skip bundle install and `brew update` entirely;
  # it reads only what is installed, so it must not auto-update either, which
  # every bundle subcommand otherwise does (10-30s once FETCH_HEAD is a day old).
  if HOMEBREW_NO_AUTO_UPDATE=1 brew bundle check --no-upgrade --file="$DOTFILES/Brewfile" >/dev/null 2>&1; then
    echo "  ok: everything in the Brewfile is installed"
  # Not fatal: one failed entry fails the whole bundle, which under `set -e`
  # would skip everything below. bundle passes --adopt, so an app installed by
  # hand at the cask's version is taken over in place; one at another version
  # fails, and `brew install --cask --force <name>` replaces it.
  elif ! brew bundle install --no-upgrade --file="$DOTFILES/Brewfile" --quiet; then
    echo "  WARNING: some brew entries failed (see above); continuing"
  fi
  echo ""
fi

echo "jq:"
# claude/statusline.sh and claude/tab-title.sh parse Claude Code's JSON with it;
# without it the statusline shows "/" for the cwd. The Brewfile covers macOS.
if command -v jq &>/dev/null; then
  echo "  ok: $(jq --version)"
elif [ -n "$IS_MACOS" ]; then
  echo "  WARNING: jq missing (brew bundle should have installed it)"
elif command -v apt-get &>/dev/null; then
  echo "  installing jq (apt may ask for your password)"
  if sudo apt-get install -y -qq jq >/dev/null; then
    echo "  installed"
  else
    echo "  WARNING: apt-get install jq failed"
  fi
else
  echo "  WARNING: no apt-get here, install jq by hand"
fi

echo ""
echo "VLC:"
# Baseline on every machine and made the default video player: Brewfile cask +
# LaunchServices on macOS, apt (not the sandboxed snap) + xdg-mime on Linux.
if [ -n "$HAVE_BREW" ]; then
  # macOS 26+ puts a consent dialog behind every `duti -s` (one per type, and duti
  # returns before it is answered). Writing LSHandlers in
  # com.apple.launchservices.secure and restarting lsd takes effect with no
  # dialog. duti stays as the read-back check. UTIs only: extensions resolve to
  # these anyway.
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
  # `command -v vlc` is not the question -- /snap/bin is on PATH, so the snap
  # answers it, and the comment above says that is the one build we do not
  # want. Resolve the name before trusting it. A snap here is also why the
  # association block below finds nothing: snapd names its entry
  # vlc_vlc.desktop under /var/lib/snapd, and pointing video types at a
  # sandboxed player that cannot open ~/ or an external drive would be worse
  # than leaving them alone, so skipping really is the right outcome.
  VLC_BIN="$(command -v vlc 2>/dev/null || true)"
  VLC_SNAP=""
  if [ -n "$VLC_BIN" ]; then
    # Both spellings: /snap/bin/vlc is the wrapper snapd puts on PATH, and it
    # resolves to /usr/bin/snap. A `case` that matches nothing exits 0, so
    # neither of these can trip `set -e`.
    VLC_REAL="$(readlink -f "$VLC_BIN" 2>/dev/null || true)"
    case "$VLC_BIN"  in /snap/*)          VLC_SNAP=1 ;; esac
    case "$VLC_REAL" in /snap/*|*/snap)   VLC_SNAP=1 ;; esac
  fi
  if [ -n "$VLC_SNAP" ]; then
    echo "  WARNING: $VLC_BIN is the snap, which is sandboxed -- associations skipped"
    echo "    sudo snap remove vlc && sudo apt-get install -y vlc"
  elif [ -n "$VLC_BIN" ]; then
    echo "  ok: $(vlc --version 2>/dev/null | head -1)"
  elif [ -n "$HAVE_APT" ]; then
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
  # xdg-mime does not write through a symlink: it writes a temp file and mv's it
  # over the target. Where ~/.config/mimeapps.list is linked to the repo (see
  # the MIME associations section), that replaces the link with a regular file,
  # and the next run of this script moves it aside as a .bak and relinks --
  # losing these associations every time. If the repo owns the file, the
  # associations belong in it.
  MIMEAPPS="${XDG_CONFIG_HOME:-$HOME/.config}/mimeapps.list"
  if [ -L "$MIMEAPPS" ]; then
    echo "  skipped associations ($MIMEAPPS is a symlink -- set them in the repo copy)"
  elif [ -z "$VLC_DESKTOP" ] || ! command -v xdg-mime &>/dev/null; then
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
  # Latest stable from ruby-build, deliberately unpinned. Link a trivial C file
  # first: a broken toolchain (seen: a leftover newer SDK the linker cannot read)
  # otherwise fails minutes into the build behind a wall of make output.
  cc_links() {
    local t rc
    t=$(mktemp -d)
    printf 'int main(){return 0;}\n' >"$t/t.c"
    cc -o "$t/t" "$t/t.c" >/dev/null 2>&1
    rc=$?
    rm -rf "$t"
    return $rc
  }
  # `system` means no rbenv ruby. `|| true`: grep exits 1 on no match, and a bare
  # assignment is not shielded from `set -e`.
  RB_GLOBAL=$(rbenv global 2>/dev/null | grep -v '^system$' || true)
  if [ -z "$RB_GLOBAL" ] && ! cc_links; then
    RB_SDK=$(xcrun --show-sdk-path 2>/dev/null || true)
    echo "  WARNING: skipping ruby install, this toolchain cannot link a C program"
    echo "  sdk in use: ${RB_SDK:-unknown}"
    echo "  cc -o t t.c on an empty main() is enough to reproduce it"
    # xcrun picks the highest-numbered SDK, not the one MacOSX.sdk points at.
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
  # No rbenv ruby yet: system ruby's gem dir is root-owned, and this avoids sudo.
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
echo "Python:"
# Brew and most distros ship python3 but no bare `python`; point it at python3.
# On macOS /usr/bin/python3 is an xcrun shim that dispatches on argv[0], so a
# `python` symlink to it asks to install the CLT; resolve the real binary.
if [ -n "$IS_MACOS" ]; then
  PY3="$(type -ap python3 | grep -v '^/usr/bin/' | head -1)"
  [ -n "$PY3" ] || PY3="$(xcrun -f python3 2>/dev/null)"
else
  PY3="$(command -v python3)"
fi
if [ -n "$PY3" ]; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$PY3" "$HOME/.local/bin/python"
  echo "  ok: python -> $PY3 ($("$PY3" -V 2>&1 | cut -d' ' -f2))"
else
  echo '  WARNING: no python3 on PATH, leaving python alone'
fi

echo ""
echo "Upstream binaries:"
# Prebuilt binaries from each project's own installer into ~/.local/bin (first
# on PATH), the same on macOS and Linux: apt's copies lag, and brew builds some
# from source on Intel. Skipped when the command is already on PATH.
# $1: command. $2: installer URL. The rest: what the script is piped into.
fetch_bin() {
  local cmd=$1 url=$2
  shift 2
  if command -v "$cmd" &>/dev/null; then
    echo "  ok: $("$cmd" --version 2>&1 | head -1)"
  elif curl -fsSL "$url" | "$@"; then
    echo "  installed: $cmd"
  else
    echo "  WARNING: $cmd install failed"
  fi
}
# fnm: the Brewfile covers macOS only. --skip-shell, or it appends to ~/.zshrc,
# i.e. this repo's zshrc. Needs unzip. A node still comes from `fnm install --lts`.
fetch_bin fnm https://fnm.vercel.app/install \
  bash -s -- --install-dir "$HOME/.local/bin" --skip-shell
# uv: when ~/.local/bin is not on the caller's PATH (a non-interactive ssh, say)
# its installer appends a `. ~/.local/bin/env` line to .zshrc, .bashrc and
# .profile -- the first two symlinks into this repo -- and seeds a fish config.
# zsh/ and bashrc already put ~/.local/bin on PATH, so that is never needed.
fetch_bin uv https://astral.sh/uv/install.sh env UV_NO_MODIFY_PATH=1 sh
fetch_bin zoxide https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh \
  sh -s -- --bin-dir "$HOME/.local/bin"
# herdr: its installer reads the same manifest as `herdr update`, so the two agree.
fetch_bin herdr https://herdr.dev/install.sh env HERDR_INSTALL_DIR="$HOME/.local/bin" sh
# cloudflare-speed-cli over Ookla, whose ISP-hosted servers flatter the result.
# Its installer verifies with sha256sum, which older macOS lacks.
fetch_bin cloudflare-speed-cli \
  https://raw.githubusercontent.com/kavehtehrani/cloudflare-speed-cli/main/install.sh sh
# `speedtest` as a symlink, not an alias, so scripts and bash get it too.
if [ -x "$HOME/.local/bin/cloudflare-speed-cli" ]; then
  ln -sf cloudflare-speed-cli "$HOME/.local/bin/speedtest"
  echo "  ok: speedtest -> cloudflare-speed-cli"
fi

# herdr's Claude Code hook, which is what reports agent state to the sidebar:
# `herdr integration install claude` writes ~/.claude/hooks/herdr-agent-state.sh
# and adds the SessionStart entry that runs it. Only when the script is missing,
# because that command also rewrites settings.json -- a symlink into this repo.
# The entry's absolute path is kept out of git by the herdrhook filter above.
if command -v herdr &>/dev/null && [ -L "$HOME/.claude/settings.json" ] &&
  [ ! -f "$HOME/.claude/hooks/herdr-agent-state.sh" ]; then
  herdr integration install claude >/dev/null 2>&1 &&
    echo "  installed: claude agent-state hook"
fi

echo ""
echo "Vim plugins:"
# Same as the `vimup` alias; keep the two in step. Down here, not by the vim
# links, because it clones over the network. --sync so `qa` waits for vim-plug's
# async clones; exit status ignored because ex mode misparses plug.vim (E10) and
# quits 1 even on success -- ~/.vim/plugged is what to believe.
if ! command -v vim &>/dev/null; then
  echo "  skipped (no vim on PATH)"
# A tiny build (some package managers' default `vim`) has no vimscript at all:
# plug#begin is a silent no-op and :PlugInstall never exists, so the run below
# would only end in the misleading "nothing landed" warning.
elif vim --version 2>/dev/null | grep -q -- '-eval'; then
  echo "  skipped (vim lacks +eval, so it can't run plugins; install a full build of vim)"
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
echo "GNOME Settings:"
# `command -v gsettings` is not a GNOME check on its own -- gsettings ships with
# glib, so any Mac with a glib-dependent formula has the binary and none of the
# org.gnome.* schemas. Hence the platform test too; gnome-settings.sh handles a
# schema that is missing anyway, and prints its own status line.
if [ -z "$IS_MACOS" ] && command -v gsettings &>/dev/null; then
  "$DOTFILES/linux/gnome-settings.sh"
else
  echo "  skipped (Linux + GNOME only)"
fi

echo ""

# A child cannot reload its parent's shell, so replace it -- only on a tty, so
# pipes and CI just return. DOTFILES_NO_EXEC=1 opts out.
if [ -t 0 ] && [ -t 1 ] && [ -z "${DOTFILES_NO_EXEC:-}" ]; then
  echo "Done. Reloading $(basename "${SHELL:-sh}")..."
  exec "${SHELL:-/bin/zsh}" -l
else
  echo "Done. Restart your shell or run: source ~/.zshrc"
fi
