export ZSH=$HOME/.oh-my-zsh    # Path to your oh-my-zsh installation.
COMPLETION_WAITING_DOTS="true" # display red dots whilst waiting for completion.
ZSH_THEME="jwrnr"              # Themes: Look in ~/.oh-my-zsh/themes/
ENABLE_CORRECTION="true"       # enable command auto-correction.
HISTSIZE=100000                # use case-sensitive completion.
CODEPATH="$HOME/Code"

# ~/.oh-my-zsh/plugins/*
plugins=(git macos history-substring-search)
source $ZSH/oh-my-zsh.sh

# User configuration
export EDITOR="vim"
export TERM=xterm-256color
export PATH="/usr/local/bin:$PATH"
export PATH="/usr/local/share/python:$PATH"
export PATH="$HOME/Library/Python/3.9/bin/$PATH"
export PATH="$HOME/.meteor:$PATH"
export PATH="$HOME/.bin:$PATH"
export PATH="$CODEPATH/util:$PATH"
export MANPATH="/usr/local/man:$MANPATH"
export LANG=en_US.UTF-8

# OS dependent
if [[ "$OSTYPE" == "linux-gnu" ]]; then

    alias brew="sudo apt-get"
    export PATH="$HOME/gems/bin:$PATH"
    export PATH="$HOME/.rbenv/shims:$PATH"

elif [[ "$OSTYPE" == "darwin"* ]]; then # Mac OSX

    alias ag="nocorrect ag"
    alias nwifi="networksetup -setairportpower en0 off"
    alias rwifi="nwifi && sleep 4 && ywifi"
    alias ywifi="networksetup -setairportpower en0 on"
    eval "$(fasd --init posix-alias zsh-hook)"
    export FZF_DEFAULT_COMMAND='ag -g ""'

fi

# Aliases
alias acp="git-add-commit-push"
alias bx="bundle exec"
alias brewup="brew update && brew upgrade && brew cleanup --prune-prefix && brew cleanup"
alias c="code ."
alias h='fc -l 1'
alias fast="speedtest"
alias fw='nocorrect fw'
alias g="git"
alias gi="\vim .gitignore; git add .gitignore; git commit -m 'update gitignore'"
alias godot="cd $CODEPATH/dotfiles"
alias inkscape="/Applications/Inkscape.app/Contents/MacOS/inkscape"
alias ll="ls -l"
alias lw="echo 'lines, words, chars, in files:'; ls -S | xargs wc"
alias m4a2mp3='find . -name "*m4a" | sed -e "s/.m4a$//" | xargs -I % ffmpeg -i "%.m4a" -acodec libmp3lame -ab 320k "%.mp3"'
alias o="open ."
alias path='echo -e ${PATH//:/\\n}'
alias python="python3"
alias rmswp="find . -type f -name '*swp' -exec rm -v {} \;; find . -type f -name '*swo' -exec rm -v {} \;"
alias rmicon="find . -type f -name 'Icon?' -exec rm -v {} \;"
alias sub="open -a Sublime\ Text"
alias tree="tree -C"
alias tre="tree"
alias trim="awk 'length(\$0) < 120'"
alias vi="vim"
alias vimup="\vim +PlugInstall +PlugUpdate +PlugUpgrade +qa"
alias wav2mp3='find . -name "*wav" | sed -e "s/.wav$//" | xargs -I % ffmpeg -i "%.wav" -acodec libmp3lame -ab 320k "%.mp3"'
alias webp2png='find . -name "*webp" | sed -e "s/.webp$//" | xargs -I % dwebp "%.webp" -o "%.png"'
alias webp2jpg='find . -name "*webp" | sed -e "s/.webp$//" | xargs -I % dwebp "%.webp" -o "%.jpg"'
alias ytdl="yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4'"
alias zshrc="$CODEPATH/util/zshrc-update; zshconfig"
alias zshconfig="source $HOME/.zshrc"

# shell initialization (fzf/ruby)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
source /usr/local/opt/chruby/share/chruby/chruby.sh

