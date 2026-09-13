tap "cloudflare/cloudflare"
tap "dart-lang/dart"
tap "homebrew/services"
tap "lizardbyte/homebrew"
tap "mongodb/brew"
tap "jeremywrnr/tap"
tap "sass/sass"
tap "teamookla/speedtest"

# shell
brew "fzf"
brew "eza"
brew "zoxide"
brew "ripgrep"
brew "tree"
brew "watch"
brew "wget"
brew "htop"
brew "telnet"
brew "iperf3"
brew "speedtest"
brew "jq"

# git
brew "git"
brew "gh"

# node
brew "fnm"

# ruby
brew "rbenv"

# python -- uv is deliberately not here. Homebrew dropped macOS Intel x86_64
# support, so there is no bottle and `brew bundle` builds uv from source,
# which means building llvm@22 and rust first -- an hour of CPU for a tool
# Astral ships as a prebuilt binary. install.sh fetches that instead.
brew "python@3.13"

# media -- the backends bin/conv and bin/set-media-date shell out to.
# librsvg is absent for the same Intel-bottle reason as uv above -- hours of
# llvm@22 and rust for a crate that builds in three minutes on its own. It
# still matters though: this ImageMagick is not linked against librsvg (`magick
# -list format` says SVG ... XML, not RSVG) and its svg delegate just shells
# out to rsvg-convert, so without that binary conv falls back to ImageMagick's
# internal MSVG renderer, which mishandles gradients, filters and text.
# Get the binary alone with cargo instead, off the rustup toolchain rather than
# brew's. bin/conv prints the exact pinned command when a conversion needs it,
# so it lives there once rather than being restated here. Note the crates.io
# `librsvg` crate is library-only and there is no `rsvg-convert` crate -- the
# binary is the unpublished `rsvg_convert` workspace member, hence the git URL.
brew "ffmpeg"
brew "imagemagick"
brew "exiftool"
brew "rdfind"
brew "libheif"
brew "yt-dlp"
brew "unrar"

# personal
brew "apple-to-last-fm"

# misc
# duti sets macOS default-app associations (see the VLC block in install.sh).
brew "duti"
brew "cloudflared"
# web-ext is absent for the same Intel-bottle reason as uv above, one step
# removed: its one heavy dependency is node, so every node bump rebuilt it from
# source -- for a binary nothing here runs, since fnm owns the node actually on
# PATH. Get the tool from npm on fnm's node instead:
#   npm install -g web-ext        (or `npx web-ext` to install nothing at all)
# Caveat: fnm scopes global packages per node version, so a global install
# needs redoing after a node switch. brew's copy was version-independent.
brew "gmp"
brew "just"
brew "libffi"
brew "pango"

# terminal
brew "tmux"

# fonts + apps
cask "font-meslo-lg-nerd-font"
cask "font-jetbrains-mono-nerd-font"
cask "basictex"
cask "vlc"
cask "zed"
