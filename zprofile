# Login-shell PATH. ~/.zprofile is a symlink into this repo, like ~/.zshrc.
#
# zshrc is read only by interactive shells, so without this a login shell that
# runs a command -- `zsh -lc …`, which is how LaunchAgents and other scripted
# callers get a "real" environment -- has no ~/.local/bin or dotfiles bin/ on
# PATH: claude resolves to Homebrew's copy, and uv and the like are
# missing. zshenv can't carry this on macOS, because /etc/zprofile runs
# path_helper after it and puts the system and Homebrew paths back in front;
# ~/.zprofile is the first user file read after path_helper.
#
# Interactive login shells (every new terminal tab on macOS) read zshrc next,
# which sources 00-path.zsh again; that file dedupes PATH and skips brew
# shellenv once HOMEBREW_PREFIX is set, so the second pass changes nothing.
export DOTFILES="${${(%):-%x}:A:h}"
source "$DOTFILES/zsh/00-path.zsh"
