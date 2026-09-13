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
brew "tree"
brew "watch"
brew "wget"
brew "htop"
brew "telnet"
brew "iperf3"
brew "jq"

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
brew "unrar"

# personal
brew "apple-to-last-fm"

# misc
# duti sets macOS default-app associations (see the VLC block in install.sh).
brew "duti"
brew "cloudflared"
# web-ext is absent for the uv reason above, one step removed: it depends on
# node, so every node bump rebuilt it. Use `npx web-ext`, or `npm i -g web-ext`
# -- but fnm scopes globals per node version, so a global install needs redoing
# after a node switch.
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
