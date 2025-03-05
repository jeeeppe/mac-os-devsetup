#!/bin/bash

# Configuration backup utility
# Backs up key configuration files to the repository

# Set script directory and load helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

print_header "Backing Up Developer Environment Configuration"

# Create backup directories if they don't exist
mkdir -p "$SCRIPT_DIR/configs/backups/shell"
mkdir -p "$SCRIPT_DIR/configs/backups/vscode"
mkdir -p "$SCRIPT_DIR/configs/backups/git"
mkdir -p "$SCRIPT_DIR/configs/backups/apps"
mkdir -p "$SCRIPT_DIR/configs/backups/homebrew"

# Timestamp for backup files
timestamp=$(date +%Y%m%d-%H%M%S)

# Function to safely backup a file
backup_config_file() {
    local src="$1"
    local dest="$2"
    
    if [ -f "$src" ]; then
        print_info "Backing up $src to $dest"
        cp "$src" "$dest"
        if [ $? -eq 0 ]; then
            print_success "Backup successful"
        else
            print_error "Failed to backup $src"
        fi
    else
        print_warning "Source file $src does not exist, skipping"
    fi
}

# Backup shell configuration files
print_info "Backing up shell configuration..."
backup_config_file "$HOME/.zshrc" "$SCRIPT_DIR/configs/backups/shell/.zshrc-$timestamp"

# If config files are symlinks, backup the actual source files
if [ -L "$HOME/.zshrc" ]; then
    src_file=$(readlink "$HOME/.zshrc")
    if [ -f "$src_file" ]; then
        backup_config_file "$src_file" "$SCRIPT_DIR/configs/backups/shell/zshrc-$timestamp"
    fi
fi

# Backup zsh modular config files
for config_file in "$HOME/.config/zsh"/*.zsh; do
    if [ -f "$config_file" ]; then
        filename=$(basename "$config_file")
        backup_config_file "$config_file" "$SCRIPT_DIR/configs/backups/shell/$filename-$timestamp"
    fi
done

# Backup VS Code settings
VS_CODE_SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
print_info "Backing up VS Code settings..."
backup_config_file "$VS_CODE_SETTINGS_DIR/settings.json" "$SCRIPT_DIR/configs/backups/vscode/settings.json-$timestamp"
backup_config_file "$VS_CODE_SETTINGS_DIR/keybindings.json" "$SCRIPT_DIR/configs/backups/vscode/keybindings.json-$timestamp"

# Backup VS Code profile settings
for profile_dir in "$HOME/.config/vscode/profiles"/*; do
    if [ -d "$profile_dir" ]; then
        profile_name=$(basename "$profile_dir")
        ensure_dir_exists "$SCRIPT_DIR/configs/backups/vscode/profiles/$profile_name"
        backup_config_file "$profile_dir/settings.json" "$SCRIPT_DIR/configs/backups/vscode/profiles/$profile_name/settings.json-$timestamp"
    fi
done

# Export VS Code extensions
if command_exists code; then
    print_info "Exporting VS Code extensions list..."
    code --list-extensions > "$SCRIPT_DIR/configs/backups/vscode/extensions-$timestamp.txt"
    print_success "VS Code extensions list exported"
else
    print_warning "VS Code command-line tools not found, skipping extensions backup"
fi

# Backup Git configuration
print_info "Backing up Git configuration..."
backup_config_file "$HOME/.gitconfig" "$SCRIPT_DIR/configs/backups/git/.gitconfig-$timestamp"
backup_config_file "$HOME/.gitignore_global" "$SCRIPT_DIR/configs/backups/git/.gitignore_global-$timestamp"

# Backup XDG-compliant Git configuration
backup_config_file "$HOME/.config/git/config" "$SCRIPT_DIR/configs/backups/git/config-$timestamp"
backup_config_file "$HOME/.config/git/ignore" "$SCRIPT_DIR/configs/backups/git/ignore-$timestamp"

# Export Homebrew packages
if command_exists brew; then
    print_info "Exporting Homebrew packages list..."
    brew leaves > "$SCRIPT_DIR/configs/backups/homebrew/brew-leaves-$timestamp.txt"
    brew list --cask > "$SCRIPT_DIR/configs/backups/homebrew/brew-casks-$timestamp.txt"
    # Export full Homebrew bundle
    brew bundle dump --file="$SCRIPT_DIR/configs/backups/homebrew/Brewfile-$timestamp"
    print_success "Homebrew packages list exported"
else
    print_warning "Homebrew not found, skipping packages backup"
fi

# Backup Terminal profiles
print_info "Backing up Terminal profiles..."
# Terminal preferences
plutil -convert xml1 -o "$SCRIPT_DIR/configs/backups/apps/terminal-prefs-$timestamp.plist" ~/Library/Preferences/com.apple.Terminal.plist

# Backup iTerm2 profiles if installed
if [ -d "$HOME/Library/Application Support/iTerm2" ]; then
    print_info "Backing up iTerm2 profiles..."
    # Create iTerm2 backup directory
    ensure_dir_exists "$SCRIPT_DIR/configs/backups/apps/iterm2"
    
    # Try to export current profile as JSON
    if [ -f "$HOME/Library/Application Support/iTerm2/DynamicProfiles" ]; then
        cp -r "$HOME/Library/Application Support/iTerm2/DynamicProfiles" "$SCRIPT_DIR/configs/backups/apps/iterm2/DynamicProfiles-$timestamp"
    fi
    
    # Backup iTerm2 preferences
    if [ -f "$HOME/Library/Preferences/com.googlecode.iterm2.plist" ]; then
        plutil -convert xml1 -o "$SCRIPT_DIR/configs/backups/apps/iterm2-prefs-$timestamp.plist" "$HOME/Library/Preferences/com.googlecode.iterm2.plist"
    fi
fi

# Backup Docker configuration if Docker is installed
if [ -d "$HOME/.docker" ]; then
    print_info "Backing up Docker configuration..."
    ensure_dir_exists "$SCRIPT_DIR/configs/backups/apps/docker"
    
    if [ -f "$HOME/.docker/config.json" ]; then
        backup_config_file "$HOME/.docker/config.json" "$SCRIPT_DIR/configs/backups/apps/docker/config.json-$timestamp"
    fi
fi

# Backup UV configuration if UV is installed
if command_exists uv; then
    print_info "Backing up UV configuration..."
    # Look for UV configuration files
    if [ -f "$HOME/.config/uv/uv.toml" ]; then
        ensure_dir_exists "$SCRIPT_DIR/configs/backups/apps/uv"
        backup_config_file "$HOME/.config/uv/uv.toml" "$SCRIPT_DIR/configs/backups/apps/uv/uv.toml-$timestamp"
    fi
fi

# Update main configuration files if needed
read -p "Do you want to update the main configuration files with the latest backups? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_info "Updating main configuration files..."
    
    # Update shell configuration
    if [ -f "$SCRIPT_DIR/configs/backups/shell/zshrc-$timestamp" ]; then
        cp "$SCRIPT_DIR/configs/backups/shell/zshrc-$timestamp" "$SCRIPT_DIR/configs/shell/zshrc"
        print_success "Updated main zshrc file"
    fi
    
    # Update zsh module files
    for module_file in "$SCRIPT_DIR/configs/backups/shell"/*.zsh-"$timestamp"; do
        if [ -f "$module_file" ]; then
            module_name=$(basename "$module_file" "-$timestamp")
            cp "$module_file" "$SCRIPT_DIR/configs/shell/zsh/$module_name"
            print_success "Updated $module_name"
        fi
    done
    
    # Update VS Code settings
    if [ -f "$SCRIPT_DIR/configs/backups/vscode/settings.json-$timestamp" ]; then
        cp "$SCRIPT_DIR/configs/backups/vscode/settings.json-$timestamp" "$SCRIPT_DIR/configs/vscode/settings.json"
        print_success "Updated main VS Code settings file"
    fi
    
    # Update VS Code profile settings
    for profile_dir in "$SCRIPT_DIR/configs/backups/vscode/profiles"/*; do
        if [ -d "$profile_dir" ]; then
            profile_name=$(basename "$profile_dir")
            settings_file="$profile_dir/settings.json-$timestamp"
            if [ -f "$settings_file" ]; then
                ensure_dir_exists "$SCRIPT_DIR/configs/vscode/profiles/$profile_name"
                cp "$settings_file" "$SCRIPT_DIR/configs/vscode/profiles/$profile_name/settings.json"
                print_success "Updated VS Code $profile_name profile settings"
            fi
        fi
    done
    
    # Update Git configuration
    if [ -f "$SCRIPT_DIR/configs/backups/git/.gitconfig-$timestamp" ]; then
        cp "$SCRIPT_DIR/configs/backups/git/.gitconfig-$timestamp" "$SCRIPT_DIR/configs/git/gitconfig"
        print_success "Updated main Git configuration file"
    fi
    
    if [ -f "$SCRIPT_DIR/configs/backups/git/.gitignore_global-$timestamp" ]; then
        cp "$SCRIPT_DIR/configs/backups/git/.gitignore_global-$timestamp" "$SCRIPT_DIR/configs/git/gitignore"
        print_success "Updated main Git ignore file"
    fi
    
    # Update Docker configuration
    if [ -f "$SCRIPT_DIR/configs/backups/apps/docker/config.json-$timestamp" ]; then
        ensure_dir_exists "$SCRIPT_DIR/configs/docker"
        cp "$SCRIPT_DIR/configs/backups/apps/docker/config.json-$timestamp" "$SCRIPT_DIR/configs/docker/config.json"
        print_success "Updated Docker configuration"
    fi
    
    # Update UV configuration
    if [ -f "$SCRIPT_DIR/configs/backups/apps/uv/uv.toml-$timestamp" ]; then
        ensure_dir_exists "$SCRIPT_DIR/configs/uv"
        cp "$SCRIPT_DIR/configs/backups/apps/uv/uv.toml-$timestamp" "$SCRIPT_DIR/configs/uv/uv.toml"
        print_success "Updated UV configuration"
    fi
    
    # Update Homebrew bundle file
    if [ -f "$SCRIPT_DIR/configs/backups/homebrew/Brewfile-$timestamp" ]; then
        cp "$SCRIPT_DIR/configs/backups/homebrew/Brewfile-$timestamp" "$SCRIPT_DIR/configs/homebrew/Brewfile"
        print_success "Updated Homebrew Brewfile"
    fi
fi

print_success "Configuration backup completed successfully"
print_info "Backup files are stored in $SCRIPT_DIR/configs/backups/"
print_info "You can run this script periodically to keep your configurations backed up"
print_info "Run './install.sh' to apply any updated configurations to your system"
