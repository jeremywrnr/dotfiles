# aliases
alias g='git'
alias vi='vim'
alias ls='ls -h --color=always'

# exporting
export EDITOR="vim"
export PATH="$PATH:$HOME/.rvm/bin"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# added by travis gem
[ ! -s /Users/jeremy/.travis/travis.sh ] || source /Users/jeremy/.travis/travis.sh
. "$HOME/.cargo/env"
