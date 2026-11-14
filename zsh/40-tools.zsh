# Third-party shell integrations, and machine-local overrides last.

# fnm's default node, as a plain PATH entry. `fnm env --use-on-cd` cost a fork
# per shell, left a multishell symlink behind each one, and switched versions per
# directory for projects that pin none. `fnm default <ver>` still retargets this.
[ -d "$HOME/.local/share/fnm/aliases/default/bin" ] &&
  export PATH="$HOME/.local/share/fnm/aliases/default/bin:$PATH"

(( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
(( $+commands[just] )) && eval "$(just --completions zsh)"

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
[ -f "$HOME/.fzf.zsh" ] && source "$HOME/.fzf.zsh"
[ -f "$HOME/.cargo/env" ] && source "$HOME/.cargo/env"
# Homebrew's rustup is keg-only, because its cargo and rustc would collide with
# the rust formula's: brew links none of them into its bin.
# After ~/.cargo/env, so that this wins where both exist. `brew --prefix` would
# cost a fork per shell, and the keg is only ever here, on arm64.
[ -d /opt/homebrew/opt/rustup/bin ] && export PATH="/opt/homebrew/opt/rustup/bin:$PATH"

# meteor -- its installer appends this to ~/.zshrc, which is this repo's zshrc.
[ -d "$HOME/.meteor" ] && export PATH="$HOME/.meteor:$PATH"

# Load local config (not in version control)
[ -f "$HOME/.zshrc.local" ] && source "$HOME/.zshrc.local"
