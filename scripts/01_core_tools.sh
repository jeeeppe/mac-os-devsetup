#!/bin/bash

# Core development tools installation script
# Installs essential development tools via Homebrew

# Set script directory and load helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

print_header "Installing Core Development Tools"

# Make sure Homebrew is initialized for this session
if [[ $(uname -m) == "arm64" ]]; then
    # M1/M2 Mac
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    # Intel Mac
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Check if Homebrew is working
if ! command_exists brew; then
    print_error "Homebrew is not available. Please check the installation."
    exit 1
fi

# Update Homebrew
print_info "Updating Homebrew..."
brew update

# Install Git
print_info "Installing Git and related tools..."
brew_install "git" || exit 1
brew_install "git-lfs" || exit 1

# Install terminal utilities
print_info "Installing terminal utilities..."
brew_install "micro" || exit 1  # Terminal editor
brew_install "bat" || exit 1    # Better cat
brew_install "exa" || exit 1    # Better ls
brew_install "fd" || exit 1     # Better find
brew_install "ripgrep" || exit 1 # Better grep
brew_install "fzf" || exit 1    # Fuzzy finder
brew_install "jq" || exit 1     # JSON processor
brew_install "yq" || exit 1     # YAML processor
brew_install "htop" || exit 1   # Process viewer
brew_install "tmux" || exit 1   # Terminal multiplexer
brew_install "tree" || exit 1   # Directory tree view

# Install shell enhancements (for zsh)
print_info "Installing shell enhancements..."
brew_install "zsh-syntax-highlighting" || exit 1
brew_install "zsh-autosuggestions" || exit 1
brew_install "zsh-completions" || exit 1

# Install additional core tools
print_info "Installing additional core tools..."
brew_install "wget" || exit 1
brew_install "curl" || exit 1
brew_install "rsync" || exit 1
brew_install "openssl" || exit 1
brew_install "ssh-copy-id" || exit 1

# Install build tools
print_info "Installing build tools..."
brew_install "cmake" || exit 1
brew_install "make" || exit 1
brew_install "automake" || exit 1
brew_install "pkg-config" || exit 1

# Setup fzf
print_info "Setting up fzf..."
$(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish

# Creating a simple Git configuration if none exists
if [ ! -f "$HOME/.gitconfig" ]; then
    print_info "Creating a basic Git configuration..."
    echo "You'll need to provide some basic information for Git:"
    read -p "Enter your full name for Git: " git_name
    read -p "Enter your email for Git: " git_email
    
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    git config --global core.editor "micro"
    git config --global init.defaultBranch "main"
    git config --global pull.rebase false
    git config --global color.ui auto
    
    print_success "Git configured with name: $git_name and email: $git_email"
else
    print_info "Git configuration already exists, skipping basic setup"
fi

print_success "Core development tools installed successfully"
exit 0
