export ZSH=$HOME/.oh-my-zsh    # Path to your oh-my-zsh installation.
COMPLETION_WAITING_DOTS="true" # display red dots whilst waiting for completion.
ZSH_THEME="jwrnr"              # Themes: Look in ~/.oh-my-zsh/themes/
ENABLE_CORRECTION="true"       # enable command auto-correction.
HISTSIZE=100000
SAVEHIST=100000
CODEPATH="$HOME/Code"

# Booker completion
fpath=(~/.zsh/completion $fpath)

# ~/.oh-my-zsh/plugins/*
plugins=(git history-substring-search)
source $ZSH/oh-my-zsh.sh

# User configuration
export EDITOR="vim"
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.rbenv/bin:$PATH"
export PATH="$HOME/.bin:$PATH"
export PATH="$CODEPATH/util:$PATH"
export MANPATH="/usr/local/man:$MANPATH"
export LANG=en_US.UTF-8

# OS dependent
if [[ "$OSTYPE" == "linux-gnu" ]]; then

    alias brew="sudo apt-get"
    # Install Ruby Gems to ~/.gems
    export GEM_HOME="$HOME/.gems"
    export PATH="$HOME/.gems/bin:$PATH"
    export PATH="$HOME/.rbenv/shims:$PATH"

elif [[ "$OSTYPE" == "darwin"* ]]; then # Mac OSX

    alias ls="eza --icons=always"
    alias rwifi="nwifi && sleep 4 && ywifi"
    alias nwifi="networksetup -setairportpower en0 off"
    alias ywifi="networksetup -setairportpower en0 on"
    (( $+commands[zoxide] )) && eval "$(zoxide init zsh)"
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
    # Set up fzf key bindings and fuzzy completion
    source <(fzf --zsh)
    # shims on PATH immediately (so gem/ruby/bundle work), full init deferred
    export PATH="$HOME/.rbenv/shims:$PATH"
    rbenv() { unfunction rbenv; eval "$(command rbenv init -)"; rbenv "$@"; }
fi

# Aliases
alias acp="git-add-commit-push"
alias rg="nocorrect rg"
alias brewup="brew update && brew trust jeremywrnr/tap cloudflare/cloudflare dart-lang/dart lizardbyte/homebrew mongodb/brew sass/sass && brew upgrade --yes && brew cleanup --prune-prefix && brew cleanup && brew bundle cleanup --force --file=$CODEPATH/dotfiles/Brewfile"
alias bx="bundle exec"
alias c="zed ."
alias fw='nocorrect fw'
alias g="git"
alias gi="\vim .gitignore; git add .gitignore; git commit -m 'update gitignore'"
alias godot="cd $CODEPATH/dotfiles"
alias up="git pull"
alias h='fc -l 1'
alias ll="ls -l"
alias lw="echo 'lines, words, chars, in files:'; ls -S | xargs wc"
alias m4a2mp3='find . -name "*m4a" | sed -e "s/.m4a$//" | xargs -I % ffmpeg -i "%.m4a" -acodec libmp3lame -ab 320k "%.mp3"'
alias o="open ."
alias path='echo -e ${PATH//:/\\n}'
alias rmicon="find . -type f -name 'Icon?' -exec rm -v {} \;"
alias rmswp="find . -type f -name '*swp' -exec rm -v {} \;; find . -type f -name '*swo' -exec rm -v {} \;"
alias tree="tree -C"
alias trim="awk 'length(\$0) < 120'"
alias vi="vim"
alias vimup="\vim +PlugInstall +PlugUpdate +PlugUpgrade +qa"
alias timezsh="for i in {1..5}; do /usr/bin/time /bin/zsh -i -c exit; done 2>&1 | grep real"
alias wav2mp3='find . -name "*wav" | sed -e "s/.wav$//" | xargs -I % ffmpeg -i "%.wav" -acodec libmp3lame -ab 320k "%.mp3"'
alias webp2png='find . -name "*webp" | sed -e "s/.webp$//" | xargs -I % dwebp "%.webp" -o "%.png"'
alias webp2jpg='find . -name "*webp" | sed -e "s/.webp$//" | xargs -I % dwebp "%.webp" -o "%.jpg"'
alias ytdl="yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4'"
alias zshrc="$CODEPATH/util/zshrc-update; source $HOME/.zshrc"

to-content() { rsync -avP "$@" nas:/volume1/Content/; }
to-files()   { rsync -avP "$@" nas:/volume2/Media/; }

ingest-nas-official() {
    rsync -avhP "$@" nas:/volume2/Media/Music/Library/ && ssh nas 'chgrp -R music /volume2/Media/Music/Library && chmod -R g+rwX /volume2/Media/Music/Library' 2>/dev/null;
}
ingest-nas-personal() {
    rsync -avhP "$@" nas:/volume2/Media/Music/Originals/ && ssh nas 'chgrp -R music /volume2/Media/Music/Originals && chmod -R g+rwX /volume2/Media/Music/Originals' 2>/dev/null;
}

# fnm (Fast Node Manager)
(( $+commands[fnm] )) && eval "$(fnm env --use-on-cd --shell zsh)"

# Load local config (not in version control)
[ -f ~/.zshrc.local ] && source ~/.zshrc.local

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# shell initialization (fzf/ruby)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

export PATH="/usr/local/opt/ruby/bin:$PATH"
source $HOME/.cargo/env

export XDG_DATA_DIRS="/var/lib/flatpak/exports/share:/home/jeremy/.local/share/flatpak/exports/share:$XDG_DATA_DIRS"

eval "$(zoxide init zsh)"

# bun completions
[ -s "/Users/jeremy/.bun/_bun" ] && source "/Users/jeremy/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"


