# aliases
alias g='git'
alias vi='vim'
alias ls='ls -h --color=always'

# exporting
export EDITOR="vim"
export PATH="$PATH:$HOME/.rvm/bin"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# path
. "$HOME/.cargo/env"

# Source nerfstudio autocompletions.
source /Users/jeremy/Code/sdfstudio/scripts/completions/setup.bash