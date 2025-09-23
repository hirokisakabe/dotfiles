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
ln -fs $PWD/claude/settings.json ~/.claude/settings.json
ln -fs $PWD/claude/CLAUDE.md ~/.claude/CLAUDE.md
source ~/.zshrc

echo "\n-- install GitAlias --"
echo "Downloading GitAlias..."
mkdir -p ~/.git-extensions
curl -fsSL https://raw.githubusercontent.com/GitAlias/gitalias/main/gitalias.txt -o ~/.git-extensions/gitalias.txt

# Add GitAlias include to .gitconfig if it's not already there
if ! grep -q "\[include\]" ~/.gitconfig || ! grep -q "path = ~/.git-extensions/gitalias.txt" ~/.gitconfig; then
  echo "\n# GitAlias configuration\n[include]\n    path = ~/.git-extensions/gitalias.txt" >> ~/.gitconfig
  echo "GitAlias configured successfully!"
else
  echo "GitAlias already configured."
fi

echo "\n-- install Homebrew and formulaes --"
curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | /bin/bash
brew bundle -v --cleanup
