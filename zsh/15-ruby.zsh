# Ruby, via rbenv on every platform.
#
# This used to differ per machine: macOS went through rbenv (Brewfile) while
# Linux exported GEM_HOME=~/.gems and put ~/.gems/bin on PATH. Neither the
# rbenv nor the gems directory actually existed on Linux, so `gem` was simply
# missing there. Both now use rbenv, and gems land in the active version's
# prefix rather than a hand-rolled GEM_HOME.

# rbenv itself: git install on Linux, Homebrew on macOS (already on PATH).
[[ -d "$HOME/.rbenv/bin" ]] && export PATH="$HOME/.rbenv/bin:$PATH"

# Shims eagerly, so ruby/gem/bundle work in a fresh shell without paying for
# init. RBENV_ROOT defaults to ~/.rbenv under both install methods.
[[ -d "$HOME/.rbenv/shims" ]] && export PATH="$HOME/.rbenv/shims:$PATH"

# `rbenv init` is only needed for `rbenv shell` and rehashing, and costs real
# milliseconds on every prompt. Defer it until rbenv is actually called.
if (( $+commands[rbenv] )); then
    rbenv() { unfunction rbenv; eval "$(command rbenv init - zsh)"; rbenv "$@"; }
fi
