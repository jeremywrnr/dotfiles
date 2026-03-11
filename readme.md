my dotfiles. to install on a new machine, in `~/Code/`:

    git clone https://github.com/jeremywrnr/dotfiles.git
    cd dotfiles && ./install.sh

existing files get backed up to `.bak`. machine-local config (api keys, etc) goes in `~/.zshrc.local`.

## deps

    brew bundle install
    git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

## notes

- `z` for directory jumping (zoxide)
- `timezsh` to benchmark shell startup
