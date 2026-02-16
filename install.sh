#!/bin/bash

kernelName="$(uname -s)"

if [ "$kernelName" != 'Darwin' ]; then
  echo "Not support OS."
  exit 1
fi

echo "\n-- install Homebrew and formulaes --"
if ! command -v brew &> /dev/null; then
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | /bin/bash
fi
brew bundle -v --cleanup

echo "\n-- create symbolic links with stow --"
mkdir -p ~/.config/yazi ~/.claude ~/.codex ~/.config/worktrunk
cd packages
stow -v -t ~ zsh vim wezterm git npm starship yazi claude codex claude-skills worktrunk
cd ..

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

echo "\n-- done! --"
