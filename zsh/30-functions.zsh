# Functions.

# --- nas ------------------------------------------------------------------

to-content() { rsync -avP "$@" nas:/volume1/Content/; }
to-media()   { rsync -avP "$@" nas:/volume2/Media/; }

ingest-nas-official() {
    rsync -avhP "$@" nas:/volume2/Media/Music/Library/ && ssh nas 'chgrp -R music /volume2/Media/Music/Library && chmod -R g+rwX /volume2/Media/Music/Library' 2>/dev/null;
}
ingest-nas-personal() {
    rsync -avhP "$@" nas:/volume2/Media/Music/Originals/ && ssh nas 'chgrp -R music /volume2/Media/Music/Originals && chmod -R g+rwX /volume2/Media/Music/Originals' 2>/dev/null;
}

# Drop an album in the NAS inbox; Lidarr imports it (Wanted -> Manual Import)
# and Navidrome picks it up from there.
upload-music() { rsync -avP "$@" nas:/volume2/Media/Downloads/; }

# --- files ----------------------------------------------------------------

# Delete the droppings: .DS_Store and Icon? from macOS, vim swap files.
# Replaces rmds, rmicon and rmswp.
rmjunk() {
    local dir="${1:-.}"
    [[ -d "$dir" ]] || { print -u2 "rmjunk: no such directory: $dir"; return 1 }
    find "$dir" -type f \( -name '.DS_Store' -o -name 'Icon?' \
        -o -name '*.swp' -o -name '*.swo' \) -print -delete
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
git-each() {
    (( $# )) || { print -u2 "usage: git-each '<command>'"; return 1 }
    local d
    for d in **/.git(N/); do
        ( cd "${d:h}" && print -P "%F{cyan}${d:h}%f" && eval "$@" )
    done
}

# --- dotfiles -------------------------------------------------------------

# Edit this config, commit it, push it, reload it. Pushes HEAD rather than a
# hardcoded main, because this repo keeps a branch per machine.
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
        git add -A vimrc gvimrc vim
        if git diff --cached --quiet; then
            print "no changes"
        else
            git commit -v && git push origin HEAD
        fi
        ./install.sh >/dev/null
    )
}
