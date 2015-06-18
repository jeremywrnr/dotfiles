# source git cmds
source ~/.git-prompt.sh

# color prompts, pulled from:
# https://wiki.archlinux.org/index.php/Color_Bash_Prompt
# example: PS1="\[$txtblu\]foo\[$txtred\] bar\[$txtrst\] baz : "

Color_Off='\e[0m'       # Text Reset
Black='\e[0;30m'        # Black
Red='\e[0;31m'          # Red
Green='\e[0;32m'        # Green
Cyan='\e[0;36m'         # Cyan
White='\e[0;37m'        # White
BGreen='\e[1;32m'       # Green
URed='\e[4;31m'         # Red
UGreen='\e[4;32m'       # Green
On_Black='\e[40m'       # Black
BIGreen='\e[1;92m'      # Green
BIWhite='\e[1;97m'      # White
On_IGreen='\e[0;102m'   # Green

# aliases
alias g='git'
alias vi='vim'
alias ..="cd ../"
alias ...="cd ../../"
alias ....="cd ../../../"
alias .....="cd ../../../../"
alias matlab='matlab -nodesktop -nosplash -r'
alias gi="vim .gitignore; git add .gitignore; git commit -m 'update gitignore'"
alias gwc='git whatchanged -p --abbrev-commit --pretty=medium'
alias glg="git log --pretty=format:'%C(yellow)%h %C(cyan)%ad%Cgreen%d %Creset%s' --date=short"
alias gps="ps aux | grep "

# listing files
alias ls='ls -h --color=always'
alias sl="ls"
alias l="ls -h"
alias lh="ls -A | grep '^\.'"
alias ll="ls -o"
alias lw="echo 'lines, words, chars, in files:'; ls -S | xargs wc"
alias tre="tree -C"
alias tree="tree -C"

# location aliases
alias gocl="cd ~/csc-454/"
alias godot='cd ~/GitHub/dotfiles'

# exporting
export EDITOR="vim"
export PATH=/u/cs254/bin:~/GitHub/util:$PATH
export PS1="\n\[$Cyan\]\u@\h \[$BIWhite\]\W\[$Green\]$(__git_ps1)\[$Color_Off\] "

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

# added by travis gem
[ -f /Users/jeremywrnr/.travis/travis.sh ] && source /Users/jeremywrnr/.travis/travis.sh

[ -f ~/.fzf.bash ] && source ~/.fzf.bash

# added by travis gem
[ -f /Users/jwrnr/.travis/travis.sh ] && source /Users/jwrnr/.travis/travis.sh
eval "$(rbenv init -)"
