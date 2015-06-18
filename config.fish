##
# Aliases
#
alias g="git"
alias frake='foreman run rake'
alias frails='foreman run rails'
alias fr='foreman run'
alias fs='foreman start'

# jeremy dotfiles location
DF="$HOME/Code/dotfiles"

# Linux specific
alias pacman="sudo pacman"

##
# Styling, greeting, and prompt
#
set fish_color_command green

function fish_greeting
    set_color green
    echo "Be nice."
    set_color normal
end

function fish_prompt
    set_color yellow
    echo -n (hostname)
    echo -n ' '
    set_color red
    echo -n (prompt_pwd)
    set_color normal
    echo -n ' ~> '
    set_color normal
end

##
# Plugins
#
source $DF/fish-scripts/acquire_git_changes.fish
source $DF/fish-scripts/git.fish
fish_vi_key_bindings

##
# Env helpers
#
rvm default
