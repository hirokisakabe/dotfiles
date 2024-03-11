#!/bin/sh

kernelName="$(uname -s)"

if [ $kernelName != 'Darwin' ]; then
  echo "Not support OS."
  return 1
fi

echo "\n-- create symbolic link --"
ln -fs $PWD/.zshrc ~/.zshrc
ln -fs $PWD/.vimrc ~/.vimrc
ln -fs $PWD/.tmux.conf ~/.tmux.conf
ln -fs $PWD/.wezterm.lua ~/.wezterm.lua
ln -fs $PWD/.gitconfig ~/.gitconfig
ln -fs $PWD/.gitignore_global ~/.gitignore_global
ln -fs $PWD/starship.toml ~/.config/starship.toml
source ~/.zshrc

echo "\n-- install Homebrew and formulaes --"
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | /bin/bash
brew bundle -v --cleanup
