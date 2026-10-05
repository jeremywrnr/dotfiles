# macOS only.
[[ "$OSTYPE" == darwin* ]] || return 0

# eza comes from the Brewfile, so it is absent until brew bundle has run --
# and an unguarded alias there breaks `ls` itself, which is a rough thing to
# hit on a new machine. Same $+commands guard the rest of the config uses;
# without eza this falls through to /bin/ls, and `ll` with it.
(( $+commands[eza] )) && alias ls="eza --icons=always"
alias rwifi="nwifi && sleep 4 && ywifi"
alias nwifi="networksetup -setairportpower en0 off"
alias ywifi="networksetup -setairportpower en0 on"
# brewup and its banner filter moved to bin/brewup. A shell that loaded the old
# functions keeps running them, ahead of PATH, until it restarts -- re-sourcing
# zshrc drops them so bin/brewup takes over.
unfunction brewup brew-drop-intel-banner 2>/dev/null

export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
(( $+commands[fzf] )) && source <(fzf --zsh)

# Force a clock resync against Apple's NTP servers, for when macOS drifts and
# the uncheck/recheck dance in System Settings is the usual fix.
alias timesync='sudo sntp -sS time.apple.com'
