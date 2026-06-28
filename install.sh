#!/bin/bash
# install.sh — symlink dotfiles into place
set -e

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$DOTFILES/$1"
  local dst="$HOME/$2"

  mkdir -p "$(dirname "$dst")"

  # already points to the right place — skip
  if [ "$(readlink "$dst")" = "$src" ]; then
    echo "  ok: $dst"
    return
  fi

  # real file exists — back up once, then replace
  if [ -e "$dst" ] && [ ! -L "$dst" ]; then
    if [ ! -e "$dst.bak" ]; then
      echo "  backup: $dst → $dst.bak"
      mv "$dst" "$dst.bak"
    else
      echo "  removing: $dst (backup already exists)"
      rm "$dst"
    fi
  fi

  ln -sf "$src" "$dst"
  echo "  linked: $dst"
}

echo "Installing dotfiles from $DOTFILES"
echo ""

if command -v brew &>/dev/null && [ -f "$DOTFILES/Brewfile" ]; then
  echo "Brew:"
  brew bundle install --file="$DOTFILES/Brewfile" --quiet
  echo ""
fi

if command -v apt-get &>/dev/null; then
  echo "APT keys:"
  KEYRING=/etc/apt/keyrings/yarn-archive-keyring.gpg
  if [ ! -f "$KEYRING" ]; then
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | gpg --dearmor | sudo tee "$KEYRING" > /dev/null
    echo "  installed: yarn keyring"
  else
    echo "  ok: yarn keyring"
  fi
  echo ""
fi

echo "Shell:"
link zshrc        .zshrc
link bashrc       .bashrc

echo ""
echo "Git:"
link gitconfig    .gitconfig
link gitignore    .gitignore_global

echo ""
echo "Vim:"
if [ ! -f "$HOME/.vim/autoload/plug.vim" ]; then
  echo "  installing vim-plug..."
  curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi
link vimrc              .vimrc
link gvimrc             .gvimrc
link vim/plugins.vim    .vim/plugins.vim
link vim/settings.vim   .vim/settings.vim
link vim/mappings.vim   .vim/mappings.vim
link vim/functions.vim  .vim/functions.vim

echo ""
echo "Tmux:"
link tmux.conf    .tmux.conf

echo ""
echo "Alacritty:"
link alacritty.toml .config/alacritty/alacritty.toml

echo ""
echo "Zed:"
link zed/settings.json .config/zed/settings.json

echo ""
echo "MIME associations:"
link mimeapps.list                   .config/mimeapps.list
link desktop-entry-launcher.desktop  .local/share/applications/desktop-entry-launcher.desktop
if command -v update-desktop-database &>/dev/null; then
  update-desktop-database "$HOME/.local/share/applications/"
  echo "  updated desktop database"
fi

echo ""
echo "Misc:"
link gemrc        .gemrc
link pytest.ini   .pytest.ini
link Brewfile     .Brewfile

echo ""
echo "uv:"
if ! command -v uv &>/dev/null; then
  curl -LsSf https://astral.sh/uv/install.sh | sh
  echo "  installed"
else
  echo "  ok: $(uv --version)"
fi

echo ""
echo "Oh My Zsh theme:"
if [ -d "$HOME/.oh-my-zsh/custom/themes" ]; then
  link oh-my-zsh/themes/jwrnr.zsh-theme .oh-my-zsh/custom/themes/jwrnr.zsh-theme
else
  echo "  skipped (oh-my-zsh not installed)"
fi

echo ""
echo "GNOME Settings:"
if command -v gsettings &>/dev/null && [ -f "$DOTFILES/gnome-settings.sh" ]; then
  "$DOTFILES/gnome-settings.sh"
else
  echo "  skipped (gsettings not found or gnome-settings.sh missing)"
fi

echo ""
echo "Done. Restart your shell or run: source ~/.zshrc"
