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

## layout

- `zshrc` — a loader; the actual config is `zsh/*.zsh`, sourced in filename order
- `zsh/` — `00-path`, `10-linux` / `10-darwin`, `20-aliases`, `30-functions`, `35-herdr`, `40-tools`
- `bin/` — standalone scripts, on `$PATH` (see `bin/readme.md`)
- `vim/`, `zed/`, `alacritty/` — per-tool config

Platform differences live in `zsh/10-linux.zsh` and `zsh/10-darwin.zsh` rather
than in per-machine branches, so the same commit works on every machine.
