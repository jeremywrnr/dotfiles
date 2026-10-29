# Functions.

# --- shell ------------------------------------------------------------------

# Auto-rehash + retry once when a command isn't found, so freshly-installed
# binaries (e.g. a new `zed` shim in /usr/local/bin) work without a new shell.
command_not_found_handler() {
    hash -r
    if whence -p "$1" >/dev/null 2>&1; then
        "$@"
        return $?
    fi
    print -u2 "zsh: command not found: $1"
    return 127
}

# --- git --------------------------------------------------------------------

# Never fail a checkout because a sibling worktree holds the branch. There is no
# checkout.* config for this, and git ignores aliases shadowing built-ins.
git() {
    case $1 in
        co|checkout|sw|switch) command git "$1" --ignore-other-worktrees "${@:2}" ;;
        *) command git "$@" ;;
    esac
}

# --- files ----------------------------------------------------------------

# Delete the droppings: .DS_Store and Icon? from macOS, vim swap files.
# Replaces rmicon and rmswp.
rmjunk() {
    local dir="${1:-.}"
    [[ -d "$dir" ]] || { print -u2 "rmjunk: no such directory: $dir"; return 1 }
    find "$dir" -type f \( -name '.DS_Store' -o -name 'Icon?' \
        -o -name '*.swp' -o -name '*.swo' \) -print -delete
}

# Just the .DS_Store files -- the ones that sneak into a commit or onto a
# shared drive. rmjunk is the wider net; this leaves swap files alone, which
# matters when vim is still open somewhere under $dir.
rmds() {
    local dir="${1:-.}"
    [[ -d "$dir" ]] || { print -u2 "rmds: no such directory: $dir"; return 1 }
    find "$dir" -type f -name '.DS_Store' -print -delete
}

# --- inspection -----------------------------------------------------------

# Print the source of any script on PATH, by name. Replaces cw (91 lines of
# Perl) and hw (its pygmentize-flavored twin).
cw() {
    (( $# )) || { print -u2 "usage: cw <command> [command ...]"; return 1 }
    local a p
    for a in "$@"; do
        if ! p=$(command -v "$a" 2>/dev/null); then
            print -u2 "cw: $a not found"; continue
        fi
        if [[ ! -f "$p" ]]; then
            print -u2 "cw: $(whence -w "$a") -- not a file on disk"; continue
        fi
        print -P "%F{cyan}# $a -- $p%f"
        if (( $+commands[bat] )); then
            bat --style=plain --paging=never "$p"
        elif (( $+commands[pygmentize] )); then
            pygmentize -g "$p"
        else
            cat "$p"
        fi
    done
}

# Certificate verification status for a host.
# https://serverfault.com/questions/589695/
ssl-status() {
    (( $# )) || { print -u2 "usage: ssl-status <host> [host ...]"; return 1 }
    local h
    for h in "$@"; do
        print -P "%F{cyan}$h%f"
        print "" | openssl s_client -showcerts -status -verify 0 \
            -connect "$h:443" 2>&1 | grep -E "Verify return|subject="
    done
}

# Run a command in every git repo below the cwd:  git-each 'git status -s'
# Both names reach the same script: `git exec ...` finds bin/git-exec on PATH.
git-each() { git exec "$@" }

# --- remote ---------------------------------------------------------------

# Block until an ssh host answers again, e.g. after rebooting it:
#   ssh -t <host> 'sudo reboot'; waitssh <host> && herdr --remote <host>
waitssh() {
    (( $# == 1 )) || { print -u2 "usage: waitssh <ssh-host>"; return 1 }
    until ssh -o ConnectTimeout=3 -o BatchMode=yes "$1" true 2>/dev/null; do
        sleep 5
    done
    print "$1 is up"
}

# --- dotfiles -------------------------------------------------------------

# Edit this config, commit it, push it, reload it. Pushes HEAD rather than a
# hardcoded main, so it also works from a feature branch.
zshrc() {
    (
        cd "$DOTFILES" || return 1
        ${EDITOR:-vim} zshrc zsh/*.zsh
        git add -A zshrc zsh
        if git diff --cached --quiet; then
            print "no changes"
        else
            git commit -v && git push origin HEAD
        fi
    ) && source "$HOME/.zshrc" && print "zshrc reloaded."
}

# Same, for vim. Relinks through install.sh -- the old version called srcdot,
# which would overwrite install.sh's symlinks with copies.
vimrc() {
    (
        cd "$DOTFILES" || return 1
        ${EDITOR:-vim} vim/mappings.vim
        git add -A vimrc vim
        if git diff --cached --quiet; then
            print "no changes"
        else
            git commit -v && git push origin HEAD
        fi
        ./install.sh >/dev/null
    )
}
