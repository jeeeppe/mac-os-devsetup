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

# Install specified formulae
print_info "Installing specified formulae..."
brew_install "git" || exit 1
brew_install "uv" || exit 1
brew_install "docker" || exit 1
brew_install "mullvad" || exit 1
brew_install "micro" || exit 1

# Install additional utilities
print_info "Installing additional utilities..."
brew_install "wget" || exit 1
brew_install "curl" || exit 1
brew_install "jq" || exit 1
brew_install "yq" || exit 1
brew_install "ripgrep" || exit 1
brew_install "fd" || exit 1
brew_install "bat" || exit 1
brew_install "htop" || exit 1
brew_install "tmux" || exit 1

# Install shell enhancements (manually, not oh-my-zsh)
print_info "Installing shell enhancements..."
brew_install "zsh-syntax-highlighting" || exit 1
brew_install "zsh-autosuggestions" || exit 1
brew_install "zsh-completions" || exit 1

# Install fzf (fuzzy finder)
print_info "Installing fzf..."
brew_install "fzf" || exit 1
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
    
    # Move Git config to centralized location
    ensure_dir_exists "$SCRIPT_DIR/configs/git"
    cp "$HOME/.gitconfig" "$SCRIPT_DIR/configs/git/.gitconfig"
    ln -sf "$SCRIPT_DIR/configs/git/.gitconfig" "$HOME/.gitconfig"
    
    print_success "Git configured with name: $git_name and email: $git_email"
else
    print_info "Git configuration already exists, moving to centralized location"
    ensure_dir_exists "$SCRIPT_DIR/configs/git"
    backup_file "$HOME/.gitconfig"
    cp "$HOME/.gitconfig" "$SCRIPT_DIR/configs/git/.gitconfig"
    ln -sf "$SCRIPT_DIR/configs/git/.gitconfig" "$HOME/.gitconfig"
fi

print_success "Core development tools installed successfully"
exit 0
