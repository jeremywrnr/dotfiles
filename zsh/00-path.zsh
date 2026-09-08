# PATH and environment.

# .zshrc gets evaluated more than once in some sessions (herdr panes, nested
# shells), and every line below prepends -- without this, PATH grows a duplicate
# of itself each time.
typeset -U path PATH

export EDITOR="vim"
export LANG=en_US.UTF-8
export MANPATH="/usr/local/man:$MANPATH"

export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

export PATH="$DOTFILES/bin:$PATH"
