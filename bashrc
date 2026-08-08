# aliases
alias ls='ls -h --color=always'

# exporting
export EDITOR="vim"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

# Booker completion
[ -f ~/.bash_completion.d/booker ] && . ~/.bash_completion.d/booker
