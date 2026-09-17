# PATH and environment.

# .zshrc gets evaluated more than once in some sessions (herdr panes, nested
# shells), and every line below prepends -- without this, PATH grows a duplicate
# of itself each time.
typeset -U path PATH

export EDITOR="vim"
export LANG=en_US.UTF-8
export MANPATH="/usr/local/man:$MANPATH"

export PATH="/usr/local/bin:$PATH"

# Apple Silicon's brew prefix is /opt/homebrew, which -- unlike Intel's
# /usr/local/bin -- is on no default PATH, so without this brew is invisible to
# every shell on an M-series Mac. shellenv rather than a bare prepend, for
# MANPATH/INFOPATH and HOMEBREW_PREFIX. It sits here rather than in
# 10-darwin.zsh so the two lines below still win over brew: ~/.local/bin holds
# the uv, zoxide and speedtest binaries install.sh puts there deliberately in
# place of the brew formulae.
#
# The completions shellenv puts on fpath land too late to matter here -- compinit
# has already run by the time this file is sourced -- so zshrc registers that
# directory itself, before oh-my-zsh.
#
# Skipped when HOMEBREW_PREFIX is already set: shellenv exports everything it
# touches, so a nested shell or a re-sourced zshrc (herdr panes do both) has it
# all inherited, and this would spend ~9ms of fork+exec recomputing it.
if [[ -z "$HOMEBREW_PREFIX" && -x /opt/homebrew/bin/brew ]]; then
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

export PATH="$HOME/.local/bin:$PATH"

export PATH="$DOTFILES/bin:$PATH"
