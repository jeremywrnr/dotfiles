# Loader. Everything else lives in zsh/, sourced in filename order.
# ~/.zshrc is a symlink into this repo, so resolve through it: %x is the file
# being sourced, :A resolves symlinks, :h takes the directory.
export DOTFILES="${${(%):-%x}:A:h}"
export CODEPATH="${DOTFILES:h}"

export ZSH=$HOME/.oh-my-zsh    # Path to your oh-my-zsh installation.
COMPLETION_WAITING_DOTS="true" # display red dots whilst waiting for completion.
ZSH_THEME="jwrnr"              # Themes: Look in ~/.oh-my-zsh/themes/
ENABLE_CORRECTION="true"       # enable command auto-correction.
HISTSIZE=100000
SAVEHIST=100000

# Booker completion
fpath=(~/.zsh/completion $fpath)

# ~/.oh-my-zsh/plugins/*
plugins=(git history-substring-search)
source $ZSH/oh-my-zsh.sh

for _zmod in "$DOTFILES"/zsh/*.zsh(N); do source "$_zmod"; done
unset _zmod
