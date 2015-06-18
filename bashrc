# aliases
alias g='git'
alias vi='vim'
alias gwc='git whatchanged -p --abbrev-commit --pretty=medium'
alias glg="git log --pretty=format:'%C(yellow)%h %C(cyan)%ad%Cgreen%d %Creset%s' --date=short"

# listing files
alias ls='ls -h --color=always'
alias sl="ls"
alias ll="ls -o"

# exporting
export EDITOR="vim"

# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# added by travis gem
[ -f /Users/jwrnr/.travis/travis.sh ] && source /Users/jwrnr/.travis/travis.sh
