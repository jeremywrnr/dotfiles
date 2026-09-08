# Aliases.

alias acp="git acp"
alias rg="nocorrect rg"
alias bx="bundle exec"
alias c="zed ."
alias fw='nocorrect fw'
alias g="git"
alias gi="\vim .gitignore; git add .gitignore; git commit -m 'update gitignore'"
alias godot="cd $DOTFILES"
alias up="git pull"
alias h='fc -l 1'
alias ll="ls -l"
alias lw="echo 'lines, words, chars, in files:'; ls -S | xargs wc"
alias o="open ."
alias path='echo -e ${PATH//:/\\n}'
alias tree="tree -C"
alias trim="awk 'length(\$0) < 120'"
alias vi="vim"
alias vimup="\vim +PlugInstall +PlugUpdate +PlugUpgrade +qa"
alias timezsh="for i in {1..5}; do /usr/bin/time /bin/zsh -i -c exit; done 2>&1 | grep real"
alias ytdl="yt-dlp -f 'bestvideo[ext=mp4]+bestaudio[ext=m4a]/mp4'"

# Duplicate files (rdfind). Look before you delete.
alias dupes="rdfind -dryrun true ."
alias dupes-rm="rdfind -deleteduplicates true ."

# Directory sizes, biggest last. Was 105 lines of hand-rolled awk and sed.
alias dudir="du -sh -- */ 2>/dev/null | sort -h"

# Files by extension, most common first. Was 100 lines of Python.
alias count-ext="find . -type f -name '*.*' | sed 's|.*/||; s|.*\.||' | tr 'A-Z' 'a-z' | sort | uniq -c | sort -rn"

# Format conversion is `conv` now (see bin/conv). The m4a2mp3 / wav2mp3 /
# webp2png / webp2jpg one-liners that used to live here are `conv mp3`,
# `conv png` and `conv jpg`. webp2jpg was quietly broken anyway: dwebp cannot
# write JPEG, so it produced PNGs named .jpg.
