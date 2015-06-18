export ZSH=$HOME/.oh-my-zsh # Path to your oh-my-zsh installation.
#setopt list_ambiguous # complete even when ambiguous
#bindkey -v # Vi mode for text selection

COMPLETION_WAITING_DOTS="true" # display red dots whilst waiting for completion.
ZSH_THEME="jwrnr" # Themes: Look in ~/.oh-my-zsh/themes/
ENABLE_CORRECTION="true" # enable command auto-correction.
HISTSIZE=100000 # use case-sensitive completion.

# ~/.oh-my-zsh/plugins/*
plugins=(brew npm git osx history-substring-search rake-completion)
source $ZSH/oh-my-zsh.sh


# User configuration
export EDITOR="vim"
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin:$PATH"
export PATH="/usr/local/bin/cask:$PATH"
export PATH="/usr/local/heroku/bin:$PATH"
export PATH="$HOME/GitHub/util:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$HOME/anaconda/bin:$PATH"
export MANPATH="/usr/local/man:$MANPATH"
export ARCHFLAGS="-arch x86_64"
export LANG=en_US.UTF-8

# os dependent macros
if [[ "$OSTYPE" == "linux-gnu" ]]; then # linux dev

    alias brew="sudo apt-get"
    alias vi="vim"
    export DB="$HOME/Dropbox/todos"

elif [[ "$OSTYPE" == "darwin"* ]]; then # Mac OSX

    alias ag="nocorrect ag"
    alias arduino="/Applications/Arduino.app/Contents/MacOS/Arduino"
    alias brewup="brew update && brew upgrade && brew prune && brew cleanup"
    alias brewvim="brew reinstall macvim && brew linkapps macvim"
    alias clean-external="ls /Volumes | grep -v 'Macintosh HD' | xargs -I % sh -c 'cd /Volumes/% && sudo clean-usb'"
    alias chromedev="open -a \"Google Chrome\" --args --allow-file-access-from-files"
    alias decolor='sed -E "s/"$'\E'"\[([0-9]{1,3}((;[0-9]{1,3})*)?)?[m|K]//g"'
    alias empty="sudo rm -ri $HOME/.Trash && clean-external && echo Trash emptied."
    alias frails="foreman run rails"
    alias frake="foreman run rake" alias f="open ." alias git="hub"
    #alias ls="exa --group-directories-first"
    alias nwifi="networksetup -setairportpower en0 off"
    alias m4a2mp3='find . -name "*m4a" | sed -e "s/.m4a$//" | xargs -I % ffmpeg -i "%.m4a" -acodec libmp3lame -ab 320k "%.mp3"'
    alias sub="open -a Sublime\ Text"
    alias rmds="_ find /Users -type f -iname .DS_Store -exec rm -v {} \;"
    alias rmbackup="while read line; do
        sudo tmutil delete '/Volumes/jeremy-mac/Backups.backupdb/jeremywrnr_mbp/${line}'
    done < <(ls /Volumes/jeremy-mac/Backups.backupdb/jeremywrnr_mbp | tail -r | tail -n +3)"
    alias rwifi="nwifi && sleep 4 && ywifi"
    alias vi='mvim'
    alias vim='mvim'
    alias web="nocorrect booker"
    alias ywifi="networksetup -setairportpower en0 on"

    eval "$(fasd --init posix-alias zsh-hook)"
    export DB=$HOME/Dropbox/todos
    export FZF_DEFAULT_COMMAND='ag -g ""'
    export PATH="/usr/local/texlive/2015basic/bin/x86_64-darwin:$PATH"
    export PATH="$HOME/.node/bin:$PATH"
    #export PATH="/Applications/Racket v6.2.1/bin:$PATH"
    #export PATH="/Applications/Postgres.app/Contents/Versions/9.3/bin:$PATH"

elif [[ "$OSTYPE" == "cygwin" || "$OSTYPE" ==  "msys" ]]; then #windoze

    alias vi="vim"
    export PATH=/cygdrive/c/Users/jeremywrnr/GitHub/dotfiles/util:$PATH

fi

# common user aliases
alias ....="cd ../../../"
alias .....="cd ../../../../"
alias bx="bundle exec"
alias pg="cat $DB/to-plan | less -R"
alias hi="pygmentize -g"
alias clockme="clock -c -u jeremywrnr@gmail.com"
alias clean-photo="chmod 644 *; modname -e JPG jpg; modname -e PNG png; cd ..; l"
alias clean-video="chmod 644 *; modname -e MP4 mp4; modname -e AVI avi; modname -e MOV mp4; cd ..; l"
alias h='fc -l 1'
alias fw='nocorrect fw'
alias g="git"
alias gi="\vim .gitignore; git add .gitignore; git commit -m 'update gitignore'"
alias gwc='git whatchanged -p --abbrev-commit --pretty=medium'
alias glg="git log --pretty=format:'%C(yellow)%h %C(cyan)%ad%Cgreen%d %Creset%s' --date=short"
alias gps="ps aux | grep "
alias nyan="telnet nyancat.dakko.us"
alias pipup="pip freeze --local | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip install -U"
alias pingg="grc ping google.com"
alias sshot="screencapture -T 2 $HOME/Desktop/$(date +"%y-%m-%d@%H.%M.%S").png"
alias qs="grep '^?'"
alias rmswp="find . -type f -name '*swp' -exec rm -v {} \;; find . -type f -name '*swo' -exec rm -v {} \;"
alias rmicon="find $HOME/Google\ Drive -type f -name 'Icon?' -exec rm -v {} \;"
alias rmiconall="find $HOME/ -type f -name 'Icon?' -exec rm -v {} \;"
alias rmicondry="find $HOME/Google\ Drive -type f -name 'Icon?'"
alias tmuxcolors="for i in {0..255} ; do; printf \"\x1b[38;5;${i}mcolour${i}\n\"; done "
alias vimup="\vim +PlugInstall +PlugUpdate +PlugUpgrade +qa"
alias ycmup="cd $HOME/.vim/plugged/YouCompleteMe && git submodule update --init --recursive && ./install.py --clang-completer"
alias zen="curl https://api.github.com/zen"
alias zshrc="$HOME/GitHub/util/zshrc-update; zshconfig"
alias zshconfig="source $HOME/.zshrc"

# listing files
alias l="ls"
alias sl="ls"
alias lh="ls -a | grep '^\.'"
alias ll="ls -l"
alias la="ls -a"
alias lw="echo 'lines, words, chars, in files:'; ls -S | xargs wc"
alias tre="tree -C"
alias tree="tree -C"
alias trim="awk 'length(\$0) < 120'"

# location aliases
alias godot="cd $HOME/GitHub/dotfiles"

# junegunn fuzzy finder
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# iterm tmux integration
test -e "${HOME}/.iterm2_shell_integration.zsh" && source "${HOME}/.iterm2_shell_integration.zsh"

# added by travis gem
[ -f /Users/jwrnr/.travis/travis.sh ] && source /Users/jwrnr/.travis/travis.sh

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/jwrnr/Downloads/google-cloud-sdk/path.zsh.inc' ]; then source '/Users/jwrnr/Downloads/google-cloud-sdk/path.zsh.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/Users/jwrnr/Downloads/google-cloud-sdk/completion.zsh.inc' ]; then source '/Users/jwrnr/Downloads/google-cloud-sdk/completion.zsh.inc'; fi
