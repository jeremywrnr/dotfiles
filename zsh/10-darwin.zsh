# macOS only.
[[ "$OSTYPE" == darwin* ]] || return 0

alias ls="eza --icons=always"
alias rwifi="nwifi && sleep 4 && ywifi"
alias nwifi="networksetup -setairportpower en0 off"
alias ywifi="networksetup -setairportpower en0 on"
# Homebrew prints a ten-line "macOS Intel x86_64 is unsupported" banner ahead of
# every install or upgrade (Library/Homebrew/extend/os/mac/diagnostic.rb,
# check_for_unsupported_macos, emitted through opoo so it lands on stderr).
# HOMEBREW_DEVELOPER=1 is the only switch that turns it off, but that flag is
# read in ~39 other places -- it makes some warnings fatal and adds post-install
# PATH audits -- which is far too much to buy silence on one banner.
#
# Match the banner's own lines rather than deleting a /start/,/end/ range. A
# range whose terminator upstream reworded would run to EOF and eat every later
# stderr line, real errors included; nine independent patterns can only ever
# fail open, leaking a line of banner instead. The two blank lines inside the
# banner do survive -- cheap next to swallowing a build error.
# Only stderr is filtered, so stdout keeps its tty and brew's progress renders.
brew-drop-intel-banner() {
  sed -e '/^Warning: You are using macOS /d' \
      -e '/^We do not provide support for this /d' \
      -e '/^Apple have dropped Intel x86_64 support/d' \
      -e '/^GitHub Actions are dropping macOS Intel/d' \
      -e '/^Homebrew is a non-profit project run entirely by volunteers/d' \
      -e '/^If the biggest companies in the world cannot support/d' \
      -e '/^any longer, sadly neither can we\.$/d' \
      -e '/^You will have better luck with MacPorts/d' \
      -e '/^ *https:\/\/www\.macports\.org$/d'
}

brewup() {
  {
    brew update &&
    brew upgrade --yes &&
    brew cleanup --prune-prefix &&
    brew cleanup &&
    brew bundle cleanup --force --file="$DOTFILES/Brewfile"
  } 2> >(brew-drop-intel-banner >&2)
}

export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
(( $+commands[fzf] )) && source <(fzf --zsh)

export PATH="/usr/local/opt/ruby/bin:$PATH"

# Force a clock resync against Apple's NTP servers, for when macOS drifts and
# the uncheck/recheck dance in System Settings is the usual fix.
alias timesync='sudo sntp -sS time.apple.com'
