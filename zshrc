export ZSH=$HOME/.oh-my-zsh    # Path to your oh-my-zsh installation.
COMPLETION_WAITING_DOTS="true" # display red dots whilst waiting for completion.
ZSH_THEME="jwrnr"              # Themes: Look in ~/.oh-my-zsh/themes/
ENABLE_CORRECTION="true"       # enable command auto-correction.
HISTSIZE=100000                # use case-sensitive completion.

CODEPATH="$HOME/Documents/Code"

# ~/.oh-my-zsh/plugins/*
plugins=(npm git osx history-substring-search)
source $ZSH/oh-my-zsh.sh

# User configuration
export EDITOR="vim"
export TERM=screen-256color
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/share/python:$PATH"
export PATH="$HOME/.bin:$PATH"
export PATH="$CODEPATH/util:$PATH"
export MANPATH="/usr/local/man:$MANPATH"
export ARCHFLAGS="-arch x86_64"
export LANG=en_US.UTF-8

# os dependent macros
if [[ "$OSTYPE" == "linux-gnu" ]]; then # linux dev

    alias brew="sudo apt-get"
    alias vi="vim"

elif [[ "$OSTYPE" == "darwin"* ]]; then # Mac OSX

    alias ag="nocorrect ag"
    alias ytdl="youtube-dl -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4'"
    alias brewup="brew update && brew upgrade && brew cleanup --prune-prefix && brew cleanup"
    alias brewvim="brew reinstall macvim && brew linkapps macvim"
    alias nwifi="networksetup -setairportpower en0 off"
    alias m4a2mp3='find . -name "*m4a" | sed -e "s/.m4a$//" | xargs -I % ffmpeg -i "%.m4a" -acodec libmp3lame -ab 320k "%.mp3"'
    alias wav2mp3='find . -name "*wav" | sed -e "s/.wav$//" | xargs -I % ffmpeg -i "%.wav" -acodec libmp3lame -ab 320k "%.mp3"'
    alias mvim='/Applications/MacVim.app/Contents/bin/mvim'
    alias sub="open -a Sublime\ Text"
    alias rmds="find . -type f -iname .DS_Store -exec rm -v {} \;"
    alias rwifi="nwifi && sleep 4 && ywifi"
    alias ywifi="networksetup -setairportpower en0 on"
    alias yvpn="launchctl load /Library/LaunchAgents/com.paloaltonetworks.gp.pangp*"
    alias nvpn="killall GlobalProtect & launchctl unload /Library/LaunchAgents/com.paloaltonetworks.gp.pangp*"
    eval "$(fasd --init posix-alias zsh-hook)"
    export FZF_DEFAULT_COMMAND='ag -g ""'

fi

# common user aliases
alias acp="git-add-commit-push"
alias bx="bundle exec"
alias h='fc -l 1'
alias fw='nocorrect fw'
alias g="git"
alias gi="\vim .gitignore; git add .gitignore; git commit -m 'update gitignore'"
alias gwc='git log --numstat --oneline'
alias glp="git log -p"
alias glg="git log --pretty=format:'%C(yellow)%h %C(cyan)%ad%Cgreen%d %Creset%s' --date=short"
alias godot="cd $CODEPATH/dotfiles"
alias nyan="telnet nyancat.dakko.us"
alias path='echo -e ${PATH//:/\\n}'
alias pipup="pip3 list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip3 install -U"
alias sshot="screencapture -T 2 $HOME/Desktop/$(date +"%y-%m-%d@%H.%M.%S").png"
alias rmswp="find . -type f -name '*swp' -exec rm -v {} \;; find . -type f -name '*swo' -exec rm -v {} \;"
alias rmicon="find . -type f -name 'Icon?' -exec rm -v {} \;"
alias trim="awk 'length(\$0) < 120'"
alias vimup="\vim +PlugInstall +PlugUpdate +PlugUpgrade +qa"
alias ycmup="cd $HOME/.vim/plugged/YouCompleteMe && git submodule update --init --recursive && python3 ./install.py --clang-completer"
alias zshrc="$CODEPATH/util/zshrc-update; zshconfig"
alias zshconfig="source $HOME/.zshrc"

# listing files
alias ll="ls -l"
alias lw="echo 'lines, words, chars, in files:'; ls -S | xargs wc"
alias tree="tree -C"
alias tre="tree"

# shell initialization
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
eval "$(rbenv init -)"
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init --path)"
fi

