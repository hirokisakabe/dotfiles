#!/bin/bash

kernelName="$(uname -s)"

if [ "$kernelName" != 'Darwin' ]; then
  echo "Not support OS."
  exit 1
fi

printf '\n-- install Homebrew and formulaes --\n'
if ! command -v brew &> /dev/null; then
  curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install.sh | /bin/bash
fi
brew bundle -v --cleanup

printf '\n-- create symbolic links with stow --\n'
make link

printf '\n-- install gh extensions --\n'
gh extension install dlvhdr/gh-dash || true

printf '\n-- install GitAlias --\n'
echo "Downloading GitAlias..."
mkdir -p ~/.git-extensions
curl -fsSL https://raw.githubusercontent.com/GitAlias/gitalias/main/gitalias.txt -o ~/.git-extensions/gitalias.txt

# Add GitAlias include to .gitconfig if it's not already there
if ! grep -q "\[include\]" ~/.gitconfig || ! grep -q "path = ~/.git-extensions/gitalias.txt" ~/.gitconfig; then
  printf '\n# GitAlias configuration\n[include]\n    path = ~/.git-extensions/gitalias.txt\n' >> ~/.gitconfig
  echo "GitAlias configured successfully!"
else
  echo "GitAlias already configured."
fi

printf '\n-- done! --\n'
