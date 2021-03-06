export ZSH=$HOME/.oh-my-zsh    # Path to your oh-my-zsh installation.
COMPLETION_WAITING_DOTS="true" # display red dots whilst waiting for completion.
ZSH_THEME="jwrnr"              # Themes: Look in ~/.oh-my-zsh/themes/
ENABLE_CORRECTION="true"       # enable command auto-correction.
HISTSIZE=100000                # use case-sensitive completion.

CODEPATH="$HOME/Documents/Code"

# ~/.oh-my-zsh/plugins/*
plugins=(git osx history-substring-search)
source $ZSH/oh-my-zsh.sh

# User configuration
export EDITOR="vim"
export TERM=screen-256color
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/share/python:$PATH"
export PATH="$HOME/.bin:$PATH"
export PATH="$CODEPATH/util:$PATH"
export MANPATH="/usr/local/man:$MANPATH"
export LANG=en_US.UTF-8

# OS dependent macros
if [[ "$OSTYPE" == "linux-gnu" ]]; then

    alias brew="sudo apt-get"
    alias vi="vim"

elif [[ "$OSTYPE" == "darwin"* ]]; then # Mac OSX

    alias ag="nocorrect ag"
    alias brewup="brew update && brew upgrade && brew cleanup --prune-prefix && brew cleanup"
    alias nwifi="networksetup -setairportpower en0 off"
    alias rmds="find . -type f -iname .DS_Store -exec rm -v {} \;"
    alias rwifi="nwifi && sleep 4 && ywifi"
    alias ywifi="networksetup -setairportpower en0 on"
    alias yvpn="launchctl load /Library/LaunchAgents/com.paloaltonetworks.gp.pangp*"
    alias nvpn="killall GlobalProtect & launchctl unload /Library/LaunchAgents/com.paloaltonetworks.gp.pangp*"
    eval "$(fasd --init posix-alias zsh-hook)"
    export FZF_DEFAULT_COMMAND='ag -g ""'

fi

# common user aliases
alias bx="bundle exec"
alias h='fc -l 1'
alias fw='nocorrect fw'
alias godot="cd $CODEPATH/dotfiles"
alias m4a2mp3='find . -name "*m4a" | sed -e "s/.m4a$//" | xargs -I % ffmpeg -i "%.m4a" -acodec libmp3lame -ab 320k "%.mp3"'
alias npmup="ncu -g"
alias path='echo -e ${PATH//:/\\n}'
alias pipup="pip3 list --outdated --format=freeze | grep -v '^\-e' | cut -d = -f 1  | xargs -n1 pip3 install -U"
alias rmswp="find . -type f -name '*swp' -exec rm -v {} \;; find . -type f -name '*swo' -exec rm -v {} \;"
alias rmicon="find . -type f -name 'Icon?' -exec rm -v {} \;"
alias sub="open -a Sublime\ Text"
alias trim="awk 'length(\$0) < 120'"
alias vimup="\vim +PlugInstall +PlugUpdate +PlugUpgrade +qa"
alias wav2mp3='find . -name "*wav" | sed -e "s/.wav$//" | xargS -i % ffmpeg -i "%.wav" -acodec libmp3lame -ab 320k "%.mp3"'
alias ycmup="cd $HOME/.vim/plugged/YouCompleteMe && git submodule update --init --recursive && python3 ./install.py --clang-completer"
alias ytdl="youtube-dl -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4'"
alias zshrc="$CODEPATH/util/zshrc-update; zshconfig"
alias zshconfig="source $HOME/.zshrc"


# git extras
alias g="git"
alias gi="\vim .gitignore; git add .gitignore; git commit -m 'update gitignore'"
alias acp="git-add-commit-push"
function git2https()
{
    local git_base=$(git remote get-url origin | sed 's/https:\/\/github.com\///' | sed 's/git@github.com://')
    git remote set-url origin https://github.com/$git_base
    git remote -v
}
function git2ssl()
{
    local git_base=$(git remote get-url origin | sed 's/https:\/\/github.com\///' | sed 's/git@github.com://')
    git remote set-url origin git@github.com:$git_base
    git remote -v
}


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

