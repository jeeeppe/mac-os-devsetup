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
if ! xcode-select -p &>/dev/null; then
    print_info "Installing Command Line Tools..."
    xcode-select --install
    
    # Wait for xcode-select to complete
    print_warning "Please complete the Command Line Tools installation before continuing."
    print_warning "Press any key after the installation has completed..."
    read -n 1
else
    print_info "Command Line Tools are already installed"
fi

# Create standard XDG directories
print_info "Creating standard XDG directories..."
ensure_dir_exists "$HOME/.config" || exit 1
ensure_dir_exists "$HOME/.cache" || exit 1
ensure_dir_exists "$HOME/.local/bin" || exit 1
ensure_dir_exists "$HOME/.local/share" || exit 1

# Create project directories
ensure_dir_exists "$SCRIPT_DIR/configs/registry" || exit 1
ensure_dir_exists "$SCRIPT_DIR/configs/shell/zsh" || exit 1
ensure_dir_exists "$SCRIPT_DIR/configs/git" || exit 1
ensure_dir_exists "$SCRIPT_DIR/configs/vscode" || exit 1
ensure_dir_exists "$SCRIPT_DIR/configs/apps" || exit 1

# Install or update Homebrew
ensure_homebrew || exit 1

# Update and upgrade Homebrew formulas
print_info "Updating Homebrew formulas..."
brew update && brew upgrade

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

# Create dependency registry files
print_info "Creating registry files..."

# Shell registry
cat > "$SCRIPT_DIR/configs/registry/shell.json" << 'EOL'
{
  "name": "Shell Configuration",
  "description": "Zsh shell configuration files",
  "configs": [
    {
      "name": "zshrc",
      "description": "Main zsh configuration file",
      "source": "shell/zshrc",
      "target": "$HOME/.zshrc",
      "type": "symlink"
    },
    {
      "name": "zsh_aliases",
      "description": "Shell aliases",
      "source": "shell/zsh/aliases.zsh",
      "target": "$HOME/.config/zsh/aliases.zsh",
      "type": "symlink"
    },
    {
      "name": "zsh_functions",
      "description": "Shell functions",
      "source": "shell/zsh/functions.zsh",
      "target": "$HOME/.config/zsh/functions.zsh",
      "type": "symlink"
    },
    {
      "name": "zsh_theme",
      "description": "Shell prompt and theme",
      "source": "shell/zsh/theme.zsh",
      "target": "$HOME/.config/zsh/theme.zsh",
      "type": "symlink"
    },
    {
      "name": "zsh_completion",
      "description": "Completion configuration",
      "source": "shell/zsh/completion.zsh",
      "target": "$HOME/.config/zsh/completion.zsh",
      "type": "symlink"
    }
  ]
}
EOL

# Git registry
cat > "$SCRIPT_DIR/configs/registry/git.json" << 'EOL'
{
  "name": "Git Configuration",
  "description": "Git version control configuration files",
  "configs": [
    {
      "name": "gitconfig",
      "description": "Main Git configuration file",
      "source": "git/gitconfig",
      "target": "$HOME/.gitconfig",
      "type": "template"
    },
    {
      "name": "gitignore",
      "description": "Global Git ignore file",
      "source": "git/gitignore",
      "target": "$HOME/.gitignore_global",
      "type": "symlink"
    },
    {
      "name": "gitconfig_xdg",
      "description": "XDG-compliant Git configuration",
      "source": "git/gitconfig",
      "target": "$XDG_CONFIG_HOME/git/config",
      "type": "template"
    },
    {
      "name": "gitignore_xdg",
      "description": "XDG-compliant global Git ignore file",
      "source": "git/gitignore",
      "target": "$XDG_CONFIG_HOME/git/ignore",
      "type": "symlink"
    }
  ]
}
EOL

# VS Code registry
cat > "$SCRIPT_DIR/configs/registry/vscode.json" << 'EOL'
{
  "name": "VS Code Configuration",
  "description": "Visual Studio Code editor configurations",
  "configs": [
    {
      "name": "settings",
      "description": "VS Code user settings",
      "source": "vscode/settings.json",
      "target": "$HOME/Library/Application Support/Code/User/settings.json",
      "type": "symlink"
    },
    {
      "name": "keybindings",
      "description": "VS Code keyboard shortcuts",
      "source": "vscode/keybindings.json",
      "target": "$HOME/Library/Application Support/Code/User/keybindings.json",
      "type": "symlink"
    },
    {
      "name": "snippets",
      "description": "VS Code code snippets",
      "source": "vscode/snippets",
      "target": "$HOME/Library/Application Support/Code/User/snippets",
      "type": "symlink"
    },
    {
      "name": "profile_coding",
      "description": "VS Code coding profile settings",
      "source": "vscode/profiles/coding/settings.json",
      "target": "$XDG_CONFIG_HOME/vscode/profiles/coding/settings.json",
      "type": "symlink"
    },
    {
      "name": "profile_diagramming",
      "description": "VS Code diagramming profile settings",
      "source": "vscode/profiles/diagramming/settings.json",
      "target": "$XDG_CONFIG_HOME/vscode/profiles/diagramming/settings.json",
      "type": "symlink"
    }
  ]
}
EOL

print_success "Prerequisites setup completed successfully"
exit 0
