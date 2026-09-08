# macOS only.
[[ "$OSTYPE" == darwin* ]] || return 0

alias ls="eza --icons=always"
alias rwifi="nwifi && sleep 4 && ywifi"
alias nwifi="networksetup -setairportpower en0 off"
alias ywifi="networksetup -setairportpower en0 on"
alias brewup="brew update && brew trust jeremywrnr/tap cloudflare/cloudflare dart-lang/dart lizardbyte/homebrew mongodb/brew sass/sass && brew upgrade --yes && brew cleanup --prune-prefix && brew cleanup && brew bundle cleanup --force --file=$DOTFILES/Brewfile"

export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
(( $+commands[fzf] )) && source <(fzf --zsh)

export PATH="/usr/local/opt/ruby/bin:$PATH"

# Force a clock resync against Apple's NTP servers, for when macOS drifts and
# the uncheck/recheck dance in System Settings is the usual fix.
alias timesync='sudo sntp -sS time.apple.com'
