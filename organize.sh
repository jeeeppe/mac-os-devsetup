#!/bin/bash

# Create main directories
mkdir -p dotfiles scripts settings source-lists

# Move configuration files to dotfiles
mv .zshrc dotfiles/
mv .gitconfig dotfiles/
#mv .vimrc dotfiles/

# Move scripts to scripts directory
mv install.sh scripts/
mv setup.sh scripts/
mv brew-install.sh scripts/
mv organize.sh scripts/

# Move settings files to settings directory
mv vscode-settings.json settings/
#mv iterm2-profile.json settings/

# Move package lists to source-lists directory
mv brew-packages.txt source-lists/
mv npm-packages.txt source-lists/
mv vscode-extensions.txt source-lists/

# Make all scripts executable
chmod +x scripts/*.sh
