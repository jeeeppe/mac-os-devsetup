#!/bin/bash

# Prerequisites setup script
# Checks system requirements and installs Homebrew

# Set script directory and load helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

print_header "Setting Up Prerequisites"

# Check if running as root (not recommended for Homebrew)
if [ "$EUID" -eq 0 ]; then
    print_error "This script should not be run as root"
    exit 1
fi

# Check macOS version (minimum 10.15 Catalina)
check_macos_version "10.15" || exit 1

# Check if command line tools are installed
# if ! xcode-select -p &>/dev/null; then
#     print_info "Installing Command Line Tools..."
#     xcode-select --install
    
#     # Wait for xcode-select to complete
#     print_warning "Please complete the Command Line Tools installation before continuing."
#     print_warning "Press any key after the installation has completed..."
#     read -n 1
# else
#     print_info "Command Line Tools are already installed"
# fi

# Create standard directories
print_info "Creating standard directories..."
ensure_dir_exists "$HOME/.config" || exit 1
ensure_dir_exists "$HOME/.cache" || exit 1
ensure_dir_exists "$HOME/.local/bin" || exit 1
ensure_dir_exists "$HOME/.local/share" || exit 1

# Install or update Homebrew
ensure_homebrew || exit 1

# Update and upgrade Homebrew formulas
print_info "Updating Homebrew formulas..."
brew update && brew upgrade

# Verify Homebrew install
if command_exists brew; then
    brew_version=$(brew --version | head -n 1)
    print_success "Homebrew is ready: $brew_version"
else
    print_error "Homebrew installation verification failed"
    exit 1
fi

# Add Homebrew to shell profile for current session and future sessions
if [[ $(uname -m) == "arm64" ]]; then
    # M1/M2 Mac
    BREW_PATH=/opt/homebrew/bin/brew
else
    # Intel Mac
    BREW_PATH=/usr/local/bin/brew
fi

# Add to current session
eval "$($BREW_PATH shellenv)"

# Add to shell config for future sessions
BREW_INIT="eval \"\$($BREW_PATH shellenv)\""
SHELL_CONFIG="$HOME/.zshrc"

if [ -f "$SHELL_CONFIG" ]; then
    backup_file "$SHELL_CONFIG"
    if ! grep -q "brew shellenv" "$SHELL_CONFIG"; then
        print_info "Adding Homebrew to $SHELL_CONFIG"
        echo "" >> "$SHELL_CONFIG"
        echo "# Homebrew initialization" >> "$SHELL_CONFIG"
        echo "$BREW_INIT" >> "$SHELL_CONFIG"
    else
        print_info "Homebrew initialization already in $SHELL_CONFIG"
    fi
else
    print_info "Creating $SHELL_CONFIG with Homebrew initialization"
    echo "# Homebrew initialization" > "$SHELL_CONFIG"
    echo "$BREW_INIT" >> "$SHELL_CONFIG"
fi

print_success "Prerequisites setup completed successfully"
exit 0
