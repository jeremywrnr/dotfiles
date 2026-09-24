# Homebrew 6 will not load a formula or cask from a third-party tap until that
# tap has been trusted, and refuses outright rather than prompting -- which
# aborts `brew bundle install` on the first one. `trusted: true` records that
# decision here, in the file that already says which taps this machine wants,
# so install.sh needs no separate `brew trust` step.
tap "jeremywrnr/tap", trusted: true

# shell
brew "fzf"
brew "eza"
brew "zoxide"
brew "ripgrep"
# What cw() in zsh/30-functions.zsh reaches for first to print a script with
# syntax highlighting; without it that falls through to plain cat.
brew "bat"
brew "tree"
brew "watch"
brew "wget"
brew "htop"
brew "telnet"
brew "iperf3"
brew "jq"
# macOS ships openrsync, which reports itself as "rsync version 2.6.9
# compatible" and speaks protocol 29. Two things it does worse than rsync 3.x:
# it re-scans the whole destination on every resumed pass, and it has no
# --info=progress2, so a long transfer prints nothing until a file completes
# and there is no way to see a stall. Homebrew's rsync 3.x fixes both and takes
# PATH precedence.
#
# It is NOT established that openrsync is the throughput limit here. Folding
# ~/Downloads/airplug-band onto the NAS held ~22 MB/s on a link that measured
# 100 MB/s with plain ssh, but the laptop was at load 18 (a browser alone was
# eating 3 cores) and ssh is single-threaded per connection, so CPU contention
# explains that gap at least as well. Measure on an idle machine before
# blaming the tool.
brew "rsync"

# git
brew "git"
brew "gh"

# node
brew "fnm"

# ruby
brew "rbenv"

# python -- uv is deliberately not here, and it is the reference case for the
# two absences below. Homebrew dropped macOS Intel x86_64 bottles, so anything
# unbottled builds llvm@22 and rust first: an hour of CPU for a tool upstream
# ships as a prebuilt binary. install.sh fetches those instead.
brew "python@3.14"

# media -- the backends bin/conv and bin/set-media-date shell out to.
# librsvg is absent for the uv reason above, but it still matters: this
# ImageMagick is not linked against it (`magick -list format` says SVG ... XML,
# not RSVG) and its svg delegate shells out to rsvg-convert, so without that
# binary conv falls back to the internal MSVG renderer, which mishandles
# gradients, filters and text. bin/conv prints the exact cargo command when a
# conversion needs it.
brew "ffmpeg"
brew "imagemagick"
brew "exiftool"
brew "rdfind"
brew "libheif"
brew "yt-dlp"
# unar, not unrar: homebrew-core dropped the unrar formula (its source is not
# open enough for the license terms brew requires). unar reads rar all the same.
brew "unar"

# personal
brew "apple-to-last-fm"

# misc
# duti reads the live LaunchServices database, which is how the VLC block in
# install.sh checks which video types actually point at VLC -- it writes them
# through the preference store instead, since `duti -s` now costs a dialog each.
brew "duti"
brew "cloudflared"
# mole (github.com/tw93/Mole) -- cache/log cleanup, app uninstall that also
# takes the leftovers, disk usage by directory, and a system monitor, in place
# of CleanMyMac/AppCleaner/DaisyDisk. It answers to both `mo` and `mole`; the
# README and its own help use `mo`.
#
# The core formula, not the curl | bash the README leads with: same upstream
# tags, and it stays inside the one thing that already knows what this machine
# has. It drops a zsh completion in brew's site-functions, which zshrc already
# has on fpath, so that needs nothing here. macOS only, and core bottles it for
# arm64 alone -- an Intel Mac builds it from source and pulls go in to do that.
brew "mole"
# web-ext is absent for the uv reason above, one step removed: it depends on
# node, so every node bump rebuilt it. Use `npx web-ext`, or `npm i -g web-ext`
# -- but fnm scopes globals per node version, so a global install needs redoing
# after a node switch.
brew "gmp"
brew "just"
brew "libffi"
brew "pango"

# imessage-exporter gets Messages out of its SQLite store, so the export can be
# backed up -- the live database is a moving target mid-snapshot.
brew "restic"
brew "imessage-exporter"

# terminal
brew "tmux"

# fonts + apps
# This repo carries alacritty.toml, the theme-sync script and a LaunchAgent that
# follows the macOS appearance -- all of which configure a terminal that nothing
# here installed, so a new Mac ended up with the config and no app. The font
# casks below are the same story: alacritty.toml names a nerd font by family, and
# without them it starts, warns, and silently falls back to Menlo.
#
# alacritty is pinned off: brew disabled the cask on 2026-09-01 because the
# upstream build stopped passing the macOS Gatekeeper check, so `brew bundle`
# fails on this line rather than skipping it. The app itself still runs, so
# install it by hand (or from a release dmg) and re-enable this when the cask
# comes back.
# cask "alacritty"
cask "font-meslo-lg-nerd-font"
cask "font-jetbrains-mono-nerd-font"
cask "vlc"
cask "zed"
