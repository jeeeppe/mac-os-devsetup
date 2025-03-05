#!/bin/bash

# Configuration Management System Test
# Tests and deploys the configuration management system

# Set script directory and load helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

print_header "Setting Up Configuration Management System"

# Create necessary directories
ensure_dir_exists "$SCRIPT_DIR/configs/registry"

# Create test registry files
print_info "Creating registry files..."

# Create shell registry
cat > "$SCRIPT_DIR/configs/registry/shell.json" << 'EOL'
{
  "name": "Shell Configuration",
  "description": "Zsh shell configuration files",
  "configs": [
    {
      "name": "zshrc",
      "description": "Main zsh configuration file",
      "source": "shell/.zshrc",
      "target": "$HOME/.zshrc",
      "type": "symlink"
    },
    {
      "name": "zsh_path",
      "description": "Path and environment variables",
      "source": "shell/zsh/paths.zsh",
      "target": "$XDG_CONFIG_HOME/zsh/paths.zsh",
      "type": "symlink"
    },
    {
      "name": "zsh_aliases",
      "description": "Shell aliases",
      "source": "shell/zsh/aliases.zsh",
      "target": "$XDG_CONFIG_HOME/zsh/aliases.zsh",
      "type": "symlink"
    },
    {
      "name": "zsh_functions",
      "description": "Shell functions",
      "source": "shell/zsh/functions.zsh",
      "target": "$XDG_CONFIG_HOME/zsh/functions.zsh",
      "type": "symlink"
    },
    {
      "name": "zsh_theme",
      "description": "Shell prompt and theme",
      "source": "shell/zsh/theme.zsh",
      "target": "$XDG_CONFIG_HOME/zsh/theme.zsh",
      "type": "symlink"
    },
    {
      "name": "zsh_completion",
      "description": "Completion configuration",
      "source": "shell/zsh/completion.zsh",
      "target": "$XDG_CONFIG_HOME/zsh/completion.zsh",
      "type": "symlink"
    }
  ]
}
EOL

# Create git registry
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

# Create vscode registry
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
    }
  ]
}
EOL

print_success "Registry files created successfully"

# Ensure configuration directories exist
print_info "Creating configuration directories..."
ensure_dir_exists "$SCRIPT_DIR/configs/shell/zsh"
ensure_dir_exists "$SCRIPT_DIR/configs/git"
ensure_dir_exists "$SCRIPT_DIR/configs/vscode"

# Create basic configuration files for testing
print_info "Creating basic configuration files for testing..."

# Create main zshrc file
cat > "$SCRIPT_DIR/configs/shell/.zshrc" << 'EOL'
# ~/.zshrc - Main zsh configuration file
# This file is a symlink to configs/shell/.zshrc

# Define XDG Base Directory paths
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Path to the development setup repository
SETUP_DIR="${SETUP_DIR:-$HOME/macos-dev-setup}"

# Ensure XDG directories exist
mkdir -p "$XDG_CONFIG_HOME/zsh"
mkdir -p "$XDG_CACHE_HOME/zsh"
mkdir -p "$XDG_DATA_HOME/zsh"

# Load Homebrew
if [[ $(uname -m) == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Define custom history file path (XDG compliant)
export HISTFILE="$XDG_STATE_HOME/zsh/history"
mkdir -p "$(dirname "$HISTFILE")"

# Load modular configuration files
for config_file in "$XDG_CONFIG_HOME/zsh"/*.zsh; do
    source "$config_file"
done

# Load completion from Homebrew if available
if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
    FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"

    # Initialize completion system
    autoload -Uz compinit
    compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
fi

# Load additional zsh plugins if installed
for plugin in zsh-syntax-highlighting zsh-autosuggestions; do
    plugin_path="$(brew --prefix)/share/$plugin/$plugin.zsh"
    if [ -f "$plugin_path" ]; then
        source "$plugin_path"
    fi
done

# Initialize FZF
[ -f "${XDG_CONFIG_HOME:-$HOME/.config}/fzf/fzf.zsh" ] && source "${XDG_CONFIG_HOME:-$HOME/.config}/fzf/fzf.zsh"

# Welcome message
echo "Welcome to $(hostname -s)!"
echo "macOS $(sw_vers -productVersion)"
echo "Type 'sysinfo' for system information"
EOL

# Create other zsh config files
cat > "$SCRIPT_DIR/configs/shell/zsh/paths.zsh" << 'EOL'
# Path and environment variables

# Add Homebrew paths
if [[ $(uname -m) == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Add local bin directory to PATH
export PATH="$HOME/.local/bin:$PATH"

# Add additional brew paths
export PATH="$(brew --prefix)/opt/curl/bin:$PATH"
export PATH="$(brew --prefix)/opt/openssl/bin:$PATH"
export PATH="$(brew --prefix)/sbin:$PATH"

# Python settings
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# Editor settings
export EDITOR="micro"
export VISUAL="code"

# FZF settings
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# Homebrew settings
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1
EOL

print_success "Basic configuration files created successfully"

# Deploy and test configuration manager
print_info "Deploying and testing configuration manager..."

# Check if jq is installed
if ! command_exists jq; then
    print_warning "jq is required for the configuration manager. Installing..."
    brew install jq
fi

# Create configuration manager utility
cat > "$SCRIPT_DIR/utils/config_manager.sh" << 'EOL'
#!/bin/bash

# Configuration Manager
# A utility to manage configuration files and symlinks

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

# Configuration constants
CONFIG_DIR="$SCRIPT_DIR/configs"
REGISTRY_DIR="$CONFIG_DIR/registry"
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

# Function to load a configuration registry
load_registry() {
    local registry="$1"
    local registry_file="$REGISTRY_DIR/$registry.json"

    if [ ! -f "$registry_file" ]; then
        print_error "Registry file not found: $registry_file"
        return 1
    fi

    # Load and parse the registry file
    local registry_data
    registry_data=$(cat "$registry_file")

    echo "$registry_data"
}

# Function to process a single configuration entry
process_config() {
    local config_name="$1"
    local source_path="$2"
    local target_path="$3"
    local link_type="$4"

    # Expand target path if it contains variables
    target_path=$(eval echo "$target_path")

    # Check if source exists
    if [ ! -f "$source_path" ] && [ ! -d "$source_path" ]; then
        print_error "Source does not exist: $source_path"
        return 1
    fi

    # Create target directory if it doesn't exist
    ensure_dir_exists "$(dirname "$target_path")"

    # Process based on link type
    case "$link_type" in
        symlink)
            # Create symlink
            if [ -L "$target_path" ]; then
                # Check if symlink is correct
                local current_link
                current_link=$(readlink "$target_path")

                if [ "$current_link" == "$source_path" ]; then
                    print_info "Symlink already exists and is correct: $target_path -> $source_path"
                    return 0
                else
                    print_warning "Symlink exists but points to different location: $target_path -> $current_link"
                    backup_file "$target_path"
                    ln -sf "$source_path" "$target_path"
                    print_success "Updated symlink: $target_path -> $source_path"
                fi
            elif [ -f "$target_path" ] || [ -d "$target_path" ]; then
                # Regular file or directory exists, backup and replace
                backup_file "$target_path"
                ln -sf "$source_path" "$target_path"
                print_success "Replaced file/directory with symlink: $target_path -> $source_path"
            else
                # Create new symlink
                ln -sf "$source_path" "$target_path"
                print_success "Created symlink: $target_path -> $source_path"
            fi
            ;;

        copy)
            # Copy file
            if [ -f "$target_path" ] || [ -d "$target_path" ]; then
                backup_file "$target_path"
            fi

            cp -R "$source_path" "$target_path"
            print_success "Copied: $source_path -> $target_path"
            ;;

        template)
            # Process template
            if [ -f "$target_path" ]; then
                backup_file "$target_path"
            fi
            # Read template variables and prompt for values


            local template_vars
            template_vars=$(grep -o "{{[^}]*}}" "$source_path" | sort -u)

            if [ -n "$template_vars" ]; then
                print_info "Template requires the following variables:"

                # Create temporary file for processed template
                local temp_file
                temp_file=$(mktemp)

                # Copy source to temp file
                cp "$source_path" "$temp_file"

                # Process each variable
                for var in $template_vars; do
                    # Extract variable name without braces
                    local var_name
                    var_name=$(echo "$var" | sed 's/{{//g' | sed 's/}}//g')

                    # Prompt for value
                    read -p "Enter value for $var_name: " var_value

                    # Replace in temp file
                    sed -i '' "s/$var/$var_value/g" "$temp_file"
                done

                # Move processed template to target
                mv "$temp_file" "$target_path"
                print_success "Processed template: $source_path -> $target_path"
            else
                # No variables, just copy
                cp "$source_path" "$target_path"
                print_success "Copied template: $source_path -> $target_path"
            fi
            ;;

        *)
            print_error "Unknown link type: $link_type"
            return 1
            ;;
    esac

    return 0
}

# Function to install configurations from a registry
install_configs() {
    local registry="$1"
    local registry_data

    registry_data=$(load_registry "$registry")

    if [ $? -ne 0 ]; then
        return 1
    fi

    print_header "Installing $registry configurations"

    # Process each configuration entry
    echo "$registry_data" | jq -c '.configs[]' | while read -r config; do
        local name
        local source
        local target
        local type

        name=$(echo "$config" | jq -r '.name')
        source=$(echo "$config" | jq -r '.source')
        target=$(echo "$config" | jq -r '.target')
        type=$(echo "$config" | jq -r '.type // "symlink"')

        # Make source path absolute
        if [[ ! "$source" == /* ]]; then
            source="$CONFIG_DIR/$source"
        fi

        print_info "Processing configuration: $name"
        process_config "$name" "$source" "$target" "$type"
    done
}

# Function to check if configurations are correctly installed
check_configs() {
    local registry="$1"
    local registry_data

    registry_data=$(load_registry "$registry")

    if [ $? -ne 0 ]; then
        return 1
    fi

    print_header "Checking $registry configurations"

    local all_correct=true

    # Check each configuration entry
    echo "$registry_data" | jq -c '.configs[]' | while read -r config; do
        local name
        local source
        local target
        local type

        name=$(echo "$config" | jq -r '.name')
        source=$(echo "$config" | jq -r '.source')
        target=$(echo "$config" | jq -r '.target')
        target=$(eval echo "$target")
        type=$(echo "$config" | jq -r '.type // "symlink"')

        # Make source path absolute
        if [[ ! "$source" == /* ]]; then
            source="$CONFIG_DIR/$source"
        fi

        print_info "Checking configuration: $name"

        # Check based on link type
        case "$type" in
            symlink)
                if [ -L "$target" ]; then
                    local current_link
                    current_link=$(readlink "$target")

                    if [ "$current_link" == "$source" ]; then
                        print_success "Symlink is correct: $target -> $source"
                    else
                        print_warning "Symlink points to wrong location: $target -> $current_link"
                        all_correct=false
                    fi
                else
                    print_warning "Not a symlink: $target"
                    all_correct=false
                fi
                ;;

            copy|template)
                if [ -f "$target" ] || [ -d "$target" ]; then
                    print_success "File/directory exists: $target"
                else
                    print_warning "File/directory does not exist: $target"
                    all_correct=false
                fi
                ;;

            *)
                print_error "Unknown link type: $type"
                all_correct=false
                ;;
        esac
    done

    if $all_correct; then
        print_success "All configurations are correctly installed"
        return 0
    else
        print_warning "Some configurations need attention"
        return 1
    fi
}

# Function to scan for common configuration files in home directory
scan_configs() {
    print_header "Scanning for configuration files"

    # Array of common configuration files to look for
    local common_files=(
        ".zshrc"
        ".bashrc"
        ".bash_profile"
        ".profile"
        ".gitconfig"
        ".gitignore_global"
        ".vimrc"
        ".tmux.conf"
    )

    # Scan for common files
    for file in "${common_files[@]}"; do
        if [ -f "$HOME/$file" ]; then
            if [ -L "$HOME/$file" ]; then
                local link_target
                link_target=$(readlink "$HOME/$file")
                print_info "Found symlink: $HOME/$file -> $link_target"
            else
                print_info "Found file: $HOME/$file"

                # Ask if user wants to add to repository
                read -p "Do you want to add this file to the repository? (y/n) " -n 1 -r
                echo
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    # Determine appropriate category
                    local category

                    if [[ $file == .zsh* ]] || [[ $file == .bash* ]] || [[ $file == .profile ]]; then
                        category="shell"
                    elif [[ $file == .git* ]]; then
                        category="git"
                    elif [[ $file == .vim* ]]; then
                        category="vim"
                    elif [[ $file == .tmux* ]]; then
                        category="tmux"
                    else
                        category="misc"
                    fi

                    # Create category directory if it doesn't exist
                    ensure_dir_exists "$CONFIG_DIR/$category"

                    # Copy file to repository
                    cp "$HOME/$file" "$CONFIG_DIR/$category/$file"
                    print_success "Added $file to repository at $CONFIG_DIR/$category/$file"

                    # Create backup of original file
                    backup_file "$HOME/$file"

                    # Create symlink
                    ln -sf "$CONFIG_DIR/$category/$file" "$HOME/$file"
                    print_success "Created symlink: $HOME/$file -> $CONFIG_DIR/$category/$file"
                fi
            fi
        fi
    done

    # Scan for additional directories
    local common_dirs=(
        ".config"
        ".local/share"
        "Library/Application Support/Code/User"
    )

    # Scan for common directories
    for dir in "${common_dirs[@]}"; do
        if [ -d "$HOME/$dir" ]; then
            print_info "Found directory: $HOME/$dir"

            # If directory is .config, scan for specific subdirectories
            if [ "$dir" == ".config" ]; then
                for config_dir in "$HOME/$dir"/*; do
                    if [ -d "$config_dir" ]; then
                        local dir_name
                        dir_name=$(basename "$config_dir")
                        print_info "  Found config directory: $dir_name"
                    fi
                done
            fi
        fi
    done
}

# Function to print usage information
print_usage() {
    echo "Configuration Manager"
    echo "Usage: config_manager.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  install <registry>     Install configurations from a registry"
    echo "  check <registry>       Check if configurations are correctly installed"
    echo "  scan                   Scan for common configuration files in home directory"
    echo "  list                   List all available registries"
    echo "  help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  config_manager.sh install shell"
    echo "  config_manager.sh check git"
    echo "  config_manager.sh scan"
    echo "  config_manager.sh list"
}

# Main functionality based on first argument
case "$1" in
    install)
        if [ -z "$2" ]; then
            print_error "Registry name is required"
            print_usage
            exit 1
        fi
        install_configs "$2"
        ;;
    check)
        if [ -z "$2" ]; then
            print_error "Registry name is required"
            print_usage
            exit 1
        fi
        check_configs "$2"
        ;;
    scan)
        scan_configs
        ;;
    list)
        # List all available registries
        print_header "Available Configuration Registries"
        for registry in "$REGISTRY_DIR"/*.json; do
            if [ -f "$registry" ]; then
                basename "$registry" .json
            fi
        done
        ;;
    help)
        print_usage
        ;;
    *)
        print_usage
        exit 1
        ;;
esac
EOL

# Make the configuration manager executable
chmod +x "$SCRIPT_DIR/utils/config_manager.sh"

print_success "Configuration manager deployed successfully"

# Test the configuration manager
print_info "Testing configuration manager..."

# List available registries
"$SCRIPT_DIR/utils/config_manager.sh" list

print_success "Configuration management system test completed successfully"
