#!/bin/bash

# Cleanup script
# Performs final cleanup and verification of setup

# Set script directory and load helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

print_header "Performing Final Cleanup and Verification"

# Make sure Homebrew is initialized for this session
if [[ $(uname -m) == "arm64" ]]; then
    # M1/M2 Mac
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    # Intel Mac
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Clean up Homebrew
print_info "Cleaning up Homebrew..."
brew cleanup

# Verify key software installations
print_info "Verifying key software installations..."

verify_installation() {
    local name="$1"
    local command="$2"
    local version_cmd="$3"
    
    if command_exists "$command"; then
        local version
        version=$($version_cmd)
        print_success "$name is installed: $version"
    else
        print_error "$name is not installed properly"
    fi
}

verify_installation "Git" "git" "git --version"
verify_installation "Python" "python3" "python3 --version"
verify_installation "UV" "uv" "uv --version"
verify_installation "VS Code" "code" "code --version | head -n 1"
verify_installation "Docker" "docker" "docker --version"
verify_installation "Homebrew" "brew" "brew --version | head -n 1"

# Check zsh configuration
print_info "Verifying shell configuration..."
if [[ "$SHELL" == *"zsh"* ]]; then
    print_success "zsh is the default shell"
else
    print_warning "zsh is not the default shell"
fi

if [ -f "$HOME/.zshrc" ]; then
    if [ -L "$HOME/.zshrc" ]; then
        print_success ".zshrc is properly symlinked to our configuration"
    else
        print_warning ".zshrc exists but is not symlinked to our configuration"
    fi
else
    print_error ".zshrc does not exist"
fi

# Verify configuration manager
print_info "Verifying configuration manager..."
if [ -x "$SCRIPT_DIR/utils/config_manager.sh" ]; then
    print_success "Configuration manager is executable"
else
    print_error "Configuration manager is not executable"
    chmod +x "$SCRIPT_DIR/utils/config_manager.sh"
fi

# Verify credentials manager
print_info "Verifying credentials manager..."
if [ -x "$SCRIPT_DIR/utils/credentials_manager.sh" ]; then
    print_success "Credentials manager is executable"
else
    print_error "Credentials manager is not executable"
    chmod +x "$SCRIPT_DIR/utils/credentials_manager.sh"
fi

# Verify environment manager
print_info "Verifying environment manager..."
if [ -x "$SCRIPT_DIR/utils/env_manager.sh" ]; then
    print_success "Environment manager is executable"
else
    print_error "Environment manager is not executable"
    chmod +x "$SCRIPT_DIR/utils/env_manager.sh"
fi

# Verify VS Code profile switcher
print_info "Verifying VS Code profile switcher..."
if [ -x "$SCRIPT_DIR/utils/vscode_profile.sh" ]; then
    print_success "VS Code profile switcher is executable"
else
    print_error "VS Code profile switcher is not executable"
    chmod +x "$SCRIPT_DIR/utils/vscode_profile.sh"
fi

# Check if all necessary config directories exist
print_info "Verifying configuration directories..."
CONFIG_DIRS=(
    "$SCRIPT_DIR/configs/shell/zsh"
    "$SCRIPT_DIR/configs/git"
    "$SCRIPT_DIR/configs/vscode"
    "$SCRIPT_DIR/configs/registry"
    "$SCRIPT_DIR/configs/apps"
)

for dir in "${CONFIG_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        print_success "Configuration directory $dir exists"
    else
        print_error "Configuration directory $dir does not exist"
        ensure_dir_exists "$dir"
    fi
done

# Create a README.md file with instructions
print_info "Creating README.md with instructions..."
cat > "$SCRIPT_DIR/README.md" << 'EOL'
# macOS Developer Environment Setup

This repository contains scripts and configurations to automate the setup of a macOS developer environment. It's designed to be run on a fresh macOS installation to set up a complete development environment with all necessary tools and configurations.

## What's Included

This setup includes:

- Core development tools (Git, terminal utilities, etc.)
- Python management with UV (instead of pip/virtualenv)
- Applications (VS Code, iTerm2, Docker, Mullvad VPN, etc.)
- Shell configuration (zsh with modern configurations)
- macOS system preferences optimized for development
- Configuration management system to maintain settings
- Credential management for secure API keys storage
- Environment management for isolated project environments

## Project Structure

- `install.sh`: Main orchestration script
- `scripts/`: Individual installation scripts for different components
- `configs/`: Configuration files for applications and tools
- `utils/`: Utility scripts and helpers

## Usage

1. Clone this repository:

```bash
git clone https://github.com/yourusername/macos-dev-setup.git
cd macos-dev-setup
```

2. Make the install script executable:

```bash
chmod +x install.sh
```

3. Run the install script:

```bash
./install.sh
```

The script will guide you through the installation process and will require your input at various stages.

## Post-Installation

After running the installation script, you should:

1. Restart your computer to apply all macOS system changes
2. Run `source ~/.zshrc` to reload your shell configuration
3. Complete any additional setup steps for specific applications (like signing in to accounts)

## Utilities

### Configuration Manager

The configuration manager centralizes and manages configuration files across your system:

```bash
# Install configurations from a registry
./utils/config_manager.sh install shell

# Check if configurations are correctly installed
./utils/config_manager.sh check git

# List all available configuration registries
./utils/config_manager.sh list
```

### Credentials Manager

The credentials manager securely stores and manages API keys:

```bash
# List stored API keys
./utils/credentials_manager.sh list

# Add a new API key
./utils/credentials_manager.sh add OPENAI_API_KEY your_api_key_here

# Get an API key
./utils/credentials_manager.sh get OPENAI_API_KEY

# Remove an API key
./utils/credentials_manager.sh remove OPENAI_API_KEY

# Load API keys into environment
./utils/credentials_manager.sh load OPENAI
```

### Environment Manager

The environment manager creates and manages isolated development environments:

```bash
# Create a new Python environment
./utils/env_manager.sh create myproject python

# List all environments
./utils/env_manager.sh list

# Activate an environment
./utils/env_manager.sh activate myproject

# Remove an environment
./utils/env_manager.sh remove myproject
```

### VS Code Profile Switcher

The VS Code profile switcher allows you to switch between different VS Code configurations:

```bash
# Switch to coding profile
./utils/vscode_profile.sh coding

# Switch to diagramming profile
./utils/vscode_profile.sh diagramming
```

## Customization

You can customize this setup by:

1. Editing the configuration files in the `configs/` directory
2. Modifying the installation scripts in the `scripts/` directory
3. Adding your own tools and configurations to the appropriate directories

## Maintenance

To update your environment:

1. Pull the latest changes from the repository
2. Run the install script again to apply the updates
3. Or run individual scripts to update specific components

## License

This project is released under the MIT License.
EOL

print_success "README.md created with instructions"

# Create a backup utility for periodic backups
print_info "Creating backup utility..."
cat > "$SCRIPT_DIR/utils/backup_config.sh" << 'EOL'
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

# Backup VS Code settings
VS_CODE_SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
print_info "Backing up VS Code settings..."
backup_config_file "$VS_CODE_SETTINGS_DIR/settings.json" "$SCRIPT_DIR/configs/backups/vscode/settings.json-$timestamp"
backup_config_file "$VS_CODE_SETTINGS_DIR/keybindings.json" "$SCRIPT_DIR/configs/backups/vscode/keybindings.json-$timestamp"

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

# Export Homebrew packages
if command_exists brew; then
    print_info "Exporting Homebrew packages list..."
    brew leaves > "$SCRIPT_DIR/configs/backups/brew-leaves-$timestamp.txt"
    brew list --cask > "$SCRIPT_DIR/configs/backups/brew-casks-$timestamp.txt"
    print_success "Homebrew packages list exported"
else
    print_warning "Homebrew not found, skipping packages backup"
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
    
    # Update VS Code settings
    if [ -f "$SCRIPT_DIR/configs/backups/vscode/settings.json-$timestamp" ]; then
        cp "$SCRIPT_DIR/configs/backups/vscode/settings.json-$timestamp" "$SCRIPT_DIR/configs/vscode/settings.json"
        print_success "Updated main VS Code settings file"
    fi
    
    # Update Git configuration
    if [ -f "$SCRIPT_DIR/configs/backups/git/.gitconfig-$timestamp" ]; then
        cp "$SCRIPT_DIR/configs/backups/git/.gitconfig-$timestamp" "$SCRIPT_DIR/configs/git/gitconfig"
        print_success "Updated main Git configuration file"
    fi
    
    if [ -f "$SCRIPT_DIR/configs/backups/git/.gitignore_global-$timestamp" ]; then
        cp "$SCRIPT_DIR/configs/backups/git/.gitignore_global-$timestamp" "$SCRIPT_DIR/configs/git/gitignore"
        print_success "Updated main Git ignore file"
    fi
fi

print_success "Configuration backup completed successfully"
print_info "Backup files are stored in $SCRIPT_DIR/configs/backups/"
EOL

# Make backup utility executable
chmod +x "$SCRIPT_DIR/utils/backup_config.sh"
print_success "Backup utility created and made executable"

# Update permissions on all scripts
print_info "Updating permissions on all scripts..."
find "$SCRIPT_DIR/utils" -type f -name "*.sh" -exec chmod +x {} \;
find "$SCRIPT_DIR/scripts" -type f -name "*.sh" -exec chmod +x {} \;
chmod +x "$SCRIPT_DIR/install.sh"
print_success "Permissions updated"

# Remind user to restart
print_header "Setup Complete!"
echo "Your macOS developer environment has been set up successfully!"
echo ""
echo "Please restart your computer to ensure all changes take effect."
echo ""
echo "After restarting:"
echo "1. Open Terminal to see your new shell configuration"
echo "2. Check VS Code and other applications to make sure they're correctly set up"
echo ""
echo "Utilities available in $SCRIPT_DIR/utils/:"
echo "- config_manager.sh: Manage configuration files"
echo "- credentials_manager.sh: Manage API keys securely"
echo "- env_manager.sh: Manage development environments"
echo "- vscode_profile.sh: Switch between VS Code profiles"
echo "- backup_config.sh: Back up your configurations"
echo ""
echo "For more information, see the README.md file."

exit 0
