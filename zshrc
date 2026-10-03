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
typeset -U fpath
fpath=(~/.zsh/completion $fpath)

# Brew's completions have to be on fpath BEFORE compinit, and compinit runs
# inside the oh-my-zsh.sh sourced below -- so this cannot wait for the
# `brew shellenv` in zsh/00-path.zsh, which is sourced after it. That is why
# _gh, _eza, _git and the rest of /opt/homebrew/share/zsh/site-functions used to
# be missing from a login shell, and only appeared in nested ones (shellenv
# exports FPATH, so children inherited what the parent registered too late).
#
# The directory rather than another `brew shellenv` fork: one stat instead of
# ~9ms of Homebrew's bash driver, and 00-path.zsh still owns the PATH half.
# typeset -U above keeps the nested-shell case from stacking duplicates.
[[ -d /opt/homebrew/share/zsh/site-functions ]] &&
  fpath=(/opt/homebrew/share/zsh/site-functions $fpath)

# ~/.oh-my-zsh/plugins/*
plugins=(git history-substring-search)
source $ZSH/oh-my-zsh.sh

for _zmod in "$DOTFILES"/zsh/*.zsh(N); do source "$_zmod"; done
unset _zmod
