# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Themes: Look in ~/.oh-my-zsh/themes/
ZSH_THEME="jeremywrnr"

# use case-sensitive completion.
HISTSIZE=100000

# enable command auto-correction.
ENABLE_CORRECTION="true"

# display red dots whilst waiting for completion.
COMPLETION_WAITING_DOTS="true"

# Uncomment if you want to disable marking untracked files under VCS as dirty.
# This makes repository status check for large repositories much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
plugins=(git brew npm perl history-substring-search osx)

source $ZSH/oh-my-zsh.sh

# User configuration

export EDITOR='vim'
export PATH="/usr/local/heroku/bin:$PATH"
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin"
export PATH=/usr/texbin:/usr/local/bin/cask:$PATH
export PATH=/usr/local/bin:/usr/local/sbin:~/bin:$PATH
export PATH=$HOME/GitHub/util:$PATH
export MANPATH="/usr/local/man:$MANPATH"
export LANG=en_US.UTF-8

# Preferred settings for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
    #sshed in
    #export EDITOR='vim'
else
    #local session
    #export EDITOR='vim'
fi

# Compilation flags
export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# os dependent macros
# http://stackoverflow.com/questions/394230/detect-the-os-from-a-bash-script
if [[ "$OSTYPE" == "linux-gnu" ]]; then # linux dev

    printf '[nix] '
    alias brew="sudo apt-get"
    alias vi="vim"

elif [[ "$OSTYPE" == "darwin"* ]]; then # Mac OSX

    printf '[osx] '
    alias bfg="java -jar ~/Dropbox/library/system/mac-osx/dsk-image/bfg-1.11.8.jar"
    alias brewup="brew update && brew upgrade --all && brew prune && brew cleanup && brew linkapps macvim"
    alias brewvim="brew reinstall macvim && brew linkapps macvim"
    alias chromedev="open -a \"Google Chrome\" --args --allow-file-access-from-files"
    alias empty="sudo rm -rf ~/.Trash && clean-external && echo Trash emptied."
    alias gdb="lldb"
    alias nwifi="networksetup -setairportpower en0 off"
    alias sub="open -a Sublime\ Text"
    alias rmds="_ find /Users -type f -iname .DS_Store -exec rm -v {} \;"
    alias vi="mvim -v"
    alias vim="mvim -v"
    alias web="nocorrect web"
    alias ywifi="networksetup -setairportpower en0 on"
    export DB=~/Dropbox/words/todo
    export EDITOR="mvim -v"
    export PYENV_ROOT=/usr/local/var/pyenv
    export PATH=/Applications/Postgres.app/Contents/Versions/9.3/bin:$PATH

elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" ==  "msys" ]]; then #windoze

    printf '[win] '
    alias vi="vim"
    export PATH=/cygdrive/c/Users/jeremywrnr/GitHub/dotfiles/util:$PATH

fi

# common user aliases
alias ....="cd ../../../"
alias .....="cd ../../../../"
alias c="cat <(printlabels) <(printlists) | less -R"
alias hi="pygmentize -g"
alias clockme="clock -c -u jeremywrnr@gmail.com"
alias clean_photo="chmod 644 *; mvext JPG jpg; mvext PNG png; cd ..; l"
alias clean_video="chmod 644 *; mvext MP4 mp4; mvext AVI avi; mvext MOV mp4; cd ..; l"
alias h='fc -l 1'
alias g="git"
alias gi="vim .gitignore; git add .gitignore; git commit -m 'update gitignore'"
alias glg="git log --pretty=format:'%C(yellow)%h %C(cyan)%ad%Cgreen%d %Creset%s' --date=short"
alias gps="ps aux | grep "
alias nyan="telnet nyancat.dakko.us"
alias pingg="grc ping google.com"
alias t="editsplit; ~/Dropbox/words/todo/store | less; c"
alias rmicon="find ~/Google\ Drive -type f -iname 'Icon?' -exec rm -v {} \;"
alias rmiconall="find ~/ -type f -iname 'Icon?' -exec rm -v {} \;"
alias rmicondry="find ~/Google\ Drive -type f -iname 'Icon?'"
alias tmuxcolors="for i in {0..255} ; do; printf \"\x1b[38;5;${i}mcolour${i}\n\"; done "
alias zen="curl https://api.github.com/zen"
alias zshrc="~/GitHub/util/zshrc_update; zshconfig"
alias zshconfig="source ~/.zshrc"

# user subaliases (used in above aliases, never direct)
alias editsplit="vim $DB/to_plan.txt -c 'vsp $DB/to_do.txt'"
alias clean-external="ls /Volumes | grep -v 'Macintosh HD' | xargs -I % sh -c 'cd /Volumes/% && sudo clean-usb'"
alias printlabels="pr -m -t -w 150 $DB/td_lab.txt $DB/tp_lab.txt | grep . --color=always"
alias printlists="pr -m -t -w 150 $DB/to_do.txt $DB/to_plan.txt"

# listing files
alias sl="ls"
alias l="ls -h"
alias lh="ls -A | grep '^\.'"
alias ll="ls -o"
alias lw="echo 'lines, words, chars, in files:'; ls -S | xargs wc"
alias dudir="echo size in mb:; du -sm * | sort -nr"
alias tre="tree"
alias tree="tree -C"

# location aliases
alias gocl="cd ~/google\ drive/class"
alias godot="cd ~/GitHub/dotfiles"
alias gohub='cd ~/GitHub'
alias gohk='cd ~/Dropbox/research/Jeremy-Philip-research-shared/hackathons'
alias gowd="cd /Users/jeremywrnr/Dropbox/words"

# hello jeremy :)
gshuf -n 1 "$DB/smile.txt"
