# aliases
alias g='git'
alias vi='vim'
alias ls='ls -h --color=always'

# exporting
export EDITOR="vim"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"
[ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"
