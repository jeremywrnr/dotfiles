# Third-party shell integrations, and machine-local overrides last.

# fnm (Fast Node Manager)
(( $+commands[fnm] )) && eval "$(fnm env --use-on-cd --shell zsh)"

(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
[ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

# Load local config (not in version control)
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
