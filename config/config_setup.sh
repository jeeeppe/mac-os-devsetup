#!/bin/bash

# Configuration Management System Setup
# Sets up the configuration management system

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

print_header "Setting Up Configuration Management System"

# Create necessary directories
ensure_dir_exists "$SCRIPT_DIR/configs/registry"
ensure_dir_exists "$SCRIPT_DIR/configs/shell/zsh"
ensure_dir_exists "$SCRIPT_DIR/configs/git"
ensure_dir_exists "$SCRIPT_DIR/configs/vscode"
ensure_dir_exists "$SCRIPT_DIR/configs/apps"

# Create the configuration manager utility
print_info "Creating configuration manager utility..."

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
                        print_success "Symlink is correct: $target -> $

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

# Create registry files
print_info "Creating configuration registry files..."

# Shell registry
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

# Create basic configuration files

# Create zshrc
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
mkdir -p "$XDG_STATE_HOME/zsh"

# Load Homebrew
if [[ $(uname -m) == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Define custom history file path (XDG compliant)
export HISTFILE="$XDG_STATE_HOME/zsh/history"
mkdir -p "$(dirname "$HISTFILE")"

# Basic zsh settings
setopt AUTO_CD                  # Change directory without cd
setopt EXTENDED_HISTORY         # Record timestamp of command
setopt HIST_EXPIRE_DUPS_FIRST   # Delete duplicates first when HISTFILE size exceeds HISTSIZE
setopt HIST_IGNORE_DUPS         # Ignore duplicated commands in history
setopt HIST_IGNORE_SPACE        # Ignore commands that start with space
setopt HIST_VERIFY              # Show command with history expansion before running it
setopt SHARE_HISTORY            # Share command history data
setopt INTERACTIVE_COMMENTS     # Allow comments in interactive shell
setopt PROMPT_SUBST             # Allow prompt substitution

# Load modular configuration files
for config_file in "$XDG_CONFIG_HOME/zsh"/*.zsh; do
    if [ -f "$config_file" ]; then
        source "$config_file"
    fi
done

# Load completion from Homebrew if available
if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
    FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"

    # Initialize completion system
    autoload -Uz compinit

    # Only check completion dump once a day
    if [ $(date +'%j') != $(stat -f '%Sm' -t '%j' "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION" 2>/dev/null || echo 0) ]; then
      compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
    else
      compinit -C -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"
    fi
fi

# Load additional zsh plugins if installed
for plugin in zsh-syntax-highlighting zsh-autosuggestions; do
    plugin_path="$(brew --prefix)"/share/$plugin/$plugin.zsh
    if [ -f "$plugin_path" ]; then
        source "$plugin_path"
    fi
done

# Initialize FZF if installed
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Welcome message
echo "Welcome to $(hostname -s)!"
echo "macOS $(sw_vers -productVersion)"
echo "Type 'sysinfo' for system information"
EOL

# Create paths.zsh
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

# Add UV bin directory to PATH
export PATH="$HOME/.local/bin/uv:$PATH"

# Add additional brew paths
export PATH="$(brew --prefix)/opt/curl/bin:$PATH"
export PATH="$(brew --prefix)/opt/openssl/bin:$PATH"
export PATH="$(brew --prefix)/sbin:$PATH"

# Add Python user bin if it exists
if [ -d "$HOME/.local/bin" ]; then
    export PATH="$HOME/.local/bin:$PATH"
fi

# Python settings
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# Editor settings
export EDITOR="micro"
export VISUAL="code"

# Less configuration
export LESS="-R"
export LESSCHARSET="utf-8"

# History settings
export HISTSIZE=10000
export HISTFILESIZE=20000
export HISTCONTROL=ignoreboth:erasedups
export HISTTIMEFORMAT="%F %T "

# Set language
export LANG="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

# Homebrew settings
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1

# FZF settings
export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --inline-info"
export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"

# UV settings
export UV_PYTHON_BIN_DIR="$HOME/.local/bin"
export UV_TOOL_BIN_DIR="$HOME/.local/bin"
export UV_TOOL_DIR="$HOME/.local/share/uv/tools"
export UV_PYTHON_INSTALL_DIR="$HOME/.local/share/uv/pythons"
EOL

# Create aliases.zsh
cat > "$SCRIPT_DIR/configs/shell/zsh/aliases.zsh" << 'EOL'
# Shell aliases

# Navigation
alias ..="cd .."
alias ...="cd ../.."
alias ....="cd ../../.."
alias ~="cd ~"

# List files
if command -v exa >/dev/null 2>&1; then
    alias ls="exa"
    alias ll="exa -la"
    alias la="exa -a"
    alias lt="exa --tree"
else
    alias ls="ls -G"
    alias ll="ls -la"
    alias la="ls -a"
fi

# Cat with syntax highlighting
if command -v bat >/dev/null 2>&1; then
    alias cat="bat"
fi

# Find with better default
if command -v fd >/dev/null 2>&1; then
    alias find="fd"
fi

# Grep with better defaults
if command -v rg >/dev/null 2>&1; then
    alias grep="rg"
fi

# Directory operations
alias mkdir="mkdir -p"
alias md="mkdir"
alias rd="rmdir"

# Editor aliases
if command -v micro >/dev/null 2>&1; then
    alias m="micro"
    alias edit="micro"
fi

# Git aliases
alias g="git"
alias gs="git status"
alias ga="git add"
alias gc="git commit"
alias gp="git push"
alias gl="git pull"
alias gd="git diff"
alias gco="git checkout"
alias gb="git branch"
alias gf="git fetch"
alias gt="git log --graph --oneline --all"

# Python aliases
alias py="python3"
alias py3="python3"
alias pyactivate="source .venv/bin/activate"
alias pyenv="uv venv"

# VS Code profiles
alias vscode-coding="$SETUP_DIR/utils/vscode_profile.sh coding"
alias vscode-diagram="$SETUP_DIR/utils/vscode_profile.sh diagramming"

# System operations
alias df="df -h"
alias du="du -h"
alias free="top -l 1 | grep PhysMem"
alias meminfo="top -l 1 | head -n 10"
alias cpuinfo="sysctl -n machdep.cpu.brand_string"

# Utility
alias h="history"
alias c="clear"
alias reload="source ~/.zshrc"
alias brewup="brew update && brew upgrade && brew cleanup"
alias path='echo $PATH | tr ":" "\n"'

# Config Management
alias configs="$SETUP_DIR/utils/config_manager.sh"

# Credential management
alias creds="$SETUP_DIR/utils/credentials_manager.sh"
EOL

# Create functions.zsh
cat > "$SCRIPT_DIR/configs/shell/zsh/functions.zsh" << 'EOL'
# Shell functions

# Create a new directory and cd into it
mkcd() {
    mkdir -p "$1" && cd "$1" || return
}

# Extract various archive formats
extract() {
    if [ -f "$1" ]; then
        case "$1" in
            *.tar.bz2)   tar xjf "$1"     ;;
            *.tar.gz)    tar xzf "$1"     ;;
            *.bz2)       bunzip2 "$1"     ;;
            *.rar)       unrar e "$1"     ;;
            *.gz)        gunzip "$1"      ;;
            *.tar)       tar xf "$1"      ;;
            *.tbz2)      tar xjf "$1"     ;;
            *.tgz)       tar xzf "$1"     ;;
            *.zip)       unzip "$1"       ;;
            *.Z)         uncompress "$1"  ;;
            *.7z)        7z x "$1"        ;;
            *)           echo "'$1' cannot be extracted via extract()" ;;
        esac
    else
        echo "'$1' is not a valid file"
    fi
}

# Find a file by name
findfile() {
    if command -v fd >/dev/null 2>&1; then
        fd "$1"
    else
        find . -name "*$1*" -type f
    fi
}

# Find a directory by name
finddir() {
    if command -v fd >/dev/null 2>&1; then
        fd -t d "$1"
    else
        find . -name "*$1*" -type d
    fi
}

# Search for a string in files
findtext() {
    if command -v rg >/dev/null 2>&1; then
        rg "$1"
    else
        grep -r "$1" .
    fi
}

# Create a Python virtual environment with UV
pyvenv() {
    local env_name="${1:-.venv}"

    if command -v uv >/dev/null 2>&1; then
        uv venv "$env_name"
        echo "To activate: source $env_name/bin/activate"
    else
        python3 -m venv "$env_name"
        echo "To activate: source $env_name/bin/activate"
    fi
}

# Create a new Python project with UV
pycreate() {
    local project_name="$1"
    local project_type="${2:-app}"

    if [ -z "$project_name" ]; then
        echo "Project name is required"
        echo "Usage: pycreate <project_name> [app|lib|package]"
        return 1
    fi

    if command -v uv >/dev/null 2>&1; then
        case "$project_type" in
            lib)
                uv init --lib "$project_name"
                ;;
            package)
                uv init --package "$project_name"
                ;;
            app|*)
                uv init "$project_name"
                ;;
        esac

        # Change to project directory
        cd "$project_name" || return

        # Create virtual environment
        uv venv

        # Activate virtual environment
        source .venv/bin/activate

        # Print success message
        echo "Python project '$project_name' created successfully!"
        echo "Project type: $project_type"
        echo "Virtual environment created and activated"
    else
        echo "UV is not installed. Please install UV first."
        return 1
    fi
}

# Load environment variables from .env file
loadenv() {
    if [ -f "${1:-.env}" ]; then
        export $(grep -v '^#' "${1:-.env}" | xargs)
        echo "Environment variables loaded from ${1:-.env}"
    else
        echo "No ${1:-.env} file found"
    fi
}

# HTTP server in current directory
serve() {
    local port="${1:-8000}"
    python3 -m http.server "$port"
}

# Get the weather for a location
weather() {
    curl -s "wttr.in/${1:-}"
}

# Generate a random password
genpass() {
    local length="${1:-16}"
    LC_ALL=C tr -dc 'A-Za-z0-9!#$%&()*+,-./:;<=>?@[\]^_{|}~' </dev/urandom | head -c "$length"; echo
}

# Create a backup of a file
backup() {
    cp "$1" "$1.backup-$(date +%Y%m%d-%H%M%S)"
}

# Show system info
sysinfo() {
    echo "OS: $(sw_vers -productName) $(sw_vers -productVersion)"
    echo "Host: $(hostname)"
    echo "Kernel: $(uname -r)"
    echo "CPU: $(sysctl -n machdep.cpu.brand_string)"
    echo "Memory: $(top -l 1 | grep PhysMem: | awk '{print $2}')"
    echo "Shell: $SHELL"
    echo "Python: $(python3 --version 2>/dev/null)"
    echo "UV: $(uv --version 2>/dev/null)"
    echo "Git: $(git --version 2>/dev/null)"
    echo "Homebrew: $(brew --version | head -n 1)"
}

# Load API keys for a specific tool/environment
loadkeys() {
    local filter="$1"
    local env_file="${2:-.env}"

    if [ -z "$filter" ]; then
        echo "Usage: loadkeys <filter> [env_file]"
        echo "Example: loadkeys OPENAI .env.ai"
        return 1
    fi

    # Execute the credentials manager to export filtered keys
    "$SETUP_DIR/utils/credentials_manager.sh" export "$env_file" "$filter"

    # Load the environment file
    if [ -f "$env_file" ]; then
        loadenv "$env_file"
    fi
}

# Run a process in the background with notification when done
bg_notify() {
    ("$@" && osascript -e "display notification \"Process completed successfully\" with title \"Background Process\"") &
}
EOL

# Create theme.zsh
cat > "$SCRIPT_DIR/configs/shell/zsh/theme.zsh" << 'EOL'
# Shell theme and prompt customization

# Enable colors
autoload -U colors && colors

# Load version control information
autoload -Uz vcs_info
precmd() { vcs_info }

# Format the vcs_info_msg_0_ variable
zstyle ':vcs_info:git:*' formats '%F{blue}(%b)%f'
zstyle ':vcs_info:*' enable git

# Set prompt
PROMPT='%F{green}%n%f@%F{yellow}%m%f:%F{cyan}%~%f ${vcs_info_msg_0_} %F{red}%(?..✘)%f$ '

# Set right prompt with time
RPROMPT='%F{gray}%*%f'
EOL

# Create completion.zsh
cat > "$SCRIPT_DIR/configs/shell/zsh/completion.zsh" << 'EOL'
# Completion configuration

# Add zsh completion system
autoload -Uz compinit
compinit -d "$XDG_CACHE_HOME/zsh/zcompdump-$ZSH_VERSION"

# Load completions from Homebrew
if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
    FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"
fi

# Completion cache directory
ensure_dir_exists() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir"
    fi
}
ensure_dir_exists "$XDG_CACHE_HOME/zsh/zcompcache"

# Completion options
zstyle ':completion:*' menu select                   # Menu-driven completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case-insensitive completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Colored completion
zstyle ':completion:*' verbose yes                   # Verbose completion
zstyle ':completion:*:descriptions' format '%B%d%b'  # Format descriptions
zstyle ':completion:*:messages' format '%d'          # Format messages
zstyle ':completion:*:warnings' format 'No matches for: %d' # Format warnings
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b' # Format corrections
zstyle ':completion:*' group-name ''                 # Group by category
zstyle ':completion:*' squeeze-slashes true          # Remove slashes
zstyle ':completion:*' use-cache on                  # Use cache
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache" # Cache path
EOL

# Create Git configs
cat > "$SCRIPT_DIR/configs/git/gitconfig" << 'EOL'
[user]
    name = {{GIT_USERNAME}}
    email = {{GIT_EMAIL}}

[core]
    editor = micro
    autocrlf = input
    safecrlf = warn
    excludesfile = ~/.gitignore_global
    pager = less -FX
    whitespace = trailing-space,space-before-tab

[init]
    defaultBranch = main

[color]
    ui = auto

[push]
    default = simple
    followTags = true

[pull]
    rebase = false

[fetch]
    prune = true

[diff]
    tool = default-difftool
    colorMoved = zebra

[difftool "default-difftool"]
    cmd = code --wait --diff $LOCAL $REMOTE

[merge]
    tool = vscode
    conflictstyle = diff3

[mergetool "vscode"]
    cmd = code --wait $MERGED

[alias]
    st = status
    co = checkout
    ci = commit
    br = branch
    lg = log --color --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit
    unstage = reset HEAD --
    last = log -1 HEAD
    visual = !gitk
    staged = diff --staged
    current = rev-parse --abbrev-ref HEAD
    contributors = shortlog --summary --numbered
    branches = branch -a
    tags = tag -l
    stashes = stash list
    uncommit = reset --soft HEAD^
    amend = commit --amend
    nevermind = !git reset --hard HEAD && git clean -fd
    graph = log --graph --all --pretty=format:'%Cred%h%Creset - %Cgreen(%cr)%Creset %s%C(yellow)%d%Creset %C(bold blue)<%an>%Creset'
    remotes = remote -v
    whoami = config user.email

[credential]
    helper = osxkeychain

[filter "lfs"]
    clean = git-lfs clean -- %f
    smudge = git-lfs smudge -- %f
    process = git-lfs filter-process
    required = true

[url "git@github.com:"]
    insteadOf = gh:

[help]
    autocorrect = 1

[includeIf "gitdir:~/work/"]
    path = ~/.config/git/work.gitconfig
EOL

cat > "$SCRIPT_DIR/configs/git/gitignore" << 'EOL'
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
.AppleDouble
.
# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db
.AppleDouble
.LSOverride
Icon

# Files that might appear in the root of a volume
.DocumentRevisions-V100
.fseventsd
.Spotlight-V100
.TemporaryItems
.Trashes
.VolumeIcon.icns
.com.apple.timemachine.donotpresent

# Directories potentially created on remote AFP share
.AppleDB
.AppleDesktop
Network Trash Folder
Temporary Items
.apdisk

# Editor/IDE specific files
.idea/
.vscode/
*.sublime-project
*.sublime-workspace
*.swp
*~
.vs/
*.suo
*.ntvs*
*.njsproj
*.sln
*.sw?
.project
.classpath
.settings/
.history/

# Logs and databases
*.log
*.sql
*.sqlite
.local.json

# Compiled source
*.com
*.class
*.dll
*.exe
*.o
*.so
*.dylib
*.out
*.app

# Packages
*.7z
*.dmg
*.gz
*.iso
*.jar
*.rar
*.tar
*.zip

# Local environment files
.env
.env.local
.env.*.local
*.env.js
.env.development.local
.env.test.local
.env.production.local

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
env/
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
*.egg-info/
.installed.cfg
*.egg
.pytest_cache/
.coverage
.mypy_cache/
.venv/
venv/
ENV/

# JavaScript/Node.js
node_modules/
npm-debug.log*
yarn-debug.log*
yarn-error.log*
yarn.lock
package-lock.json
.pnp.*
.yarn/*
!.yarn/patches
!.yarn/plugins
!.yarn/releases
!.yarn/sdks
!.yarn/versions
.eslintcache
.env.local
.env.development.local
.env.test.local
.env.production.local

# C/C++
*.dSYM/
*.su
*.idb
*.pdb
.obj/
.objs/
Debug/
Release/
x64/
x86/
[Bb]in/
[Oo]bj/
cmake-build-*/
EOL

print_info "Creating VS Code profile settings..."

# Ensure VS Code directories exist
ensure_dir_exists "$SCRIPT_DIR/configs/vscode/profiles/coding"
ensure_dir_exists "$SCRIPT_DIR/configs/vscode/profiles/diagramming"

# Create VS Code main settings file
cat > "$SCRIPT_DIR/configs/vscode/settings.json" << 'EOL'
{
    "window.newWindowDimensions": "inherit",
    "window.restoreWindows": "all",
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    "security.workspace.trust.enabled": true,
    "telemetry.telemetryLevel": "off",
    "update.mode": "manual",
    "extensions.autoUpdate": false,
    "workbench.editor.untitled.hint": "hidden"
}
EOL

# Create VS Code coding profile settings
cat > "$SCRIPT_DIR/configs/vscode/profiles/coding/settings.json" << 'EOL'
{
    "editor.fontSize": 14,
    "editor.fontFamily": "JetBrains Mono, Menlo, Monaco, 'Courier New', monospace",
    "editor.fontLigatures": true,
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "editor.formatOnSave": true,
    "editor.rulers": [88, 120],
    "editor.bracketPairColorization.enabled": true,
    "editor.guides.bracketPairs": true,
    "editor.minimap.enabled": false,
    "editor.renderWhitespace": "boundary",
    "editor.suggestSelection": "first",
    "workbench.colorTheme": "GitHub Dark Default",
    "workbench.iconTheme": "vs-seti",
    "terminal.integrated.fontFamily": "JetBrains Mono, Menlo, Monaco, 'Courier New', monospace",
    "terminal.integrated.fontSize": 14,
    "window.zoomLevel": 0,
    "[python]": {
        "editor.defaultFormatter": "ms-python.black-formatter",
        "editor.formatOnSave": true,
        "editor.codeActionsOnSave": {
            "source.organizeImports": true
        }
    },
    "python.linting.enabled": true,
    "python.linting.mypyEnabled": true,
    "python.formatting.provider": "none",
    "[javascript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode",
        "editor.formatOnSave": true
    },
    "[typescript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode",
        "editor.formatOnSave": true
    },
    "git.autofetch": true,
    "git.confirmSync": false,
    "workbench.statusBar.visible": true
}
EOL

# Create VS Code diagramming profile settings
cat > "$SCRIPT_DIR/configs/vscode/profiles/diagramming/settings.json" << 'EOL'
{
    "editor.fontSize": 14,
    "editor.fontFamily": "JetBrains Mono, Menlo, Monaco, 'Courier New', monospace",
    "editor.fontLigatures": true,
    "editor.tabSize": 2,
    "editor.insertSpaces": true,
    "editor.formatOnSave": true,
    "editor.minimap.enabled": false,
    "workbench.colorTheme": "GitHub Light Default",
    "workbench.iconTheme": "vs-seti",
    "terminal.integrated.fontFamily": "JetBrains Mono, Menlo, Monaco, 'Courier New', monospace",
    "terminal.integrated.fontSize": 14,
    "window.zoomLevel": 0,
    "editor.renderWhitespace": "none",
    "workbench.statusBar.visible": true,
    "editor.wordWrap": "on"
}
EOL

# Create VS Code profile manager script
cat > "$SCRIPT_DIR/utils/vscode_profile.sh" << 'EOL'
#!/bin/bash

# VS Code profile switcher
# Usage: vscode_profile.sh [coding|diagramming]

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

# Get profile name
PROFILE="${1:-coding}"

# VS Code user directory
VS_CODE_USER_DIR="$HOME/Library/Application Support/Code/User"
VS_CODE_CONFIG_DIR="$SCRIPT_DIR/configs/vscode"

# Check if profile exists
if [ ! -f "$VS_CODE_CONFIG_DIR/profiles/$PROFILE/settings.json" ]; then
    print_error "Profile '$PROFILE' not found"
    echo "Available profiles:"
    ls -1 "$VS_CODE_CONFIG_DIR/profiles"
    exit 1
fi

# Backup current settings if not a symlink
if [ ! -L "$VS_CODE_USER_DIR/settings.json" ] && [ -f "$VS_CODE_USER_DIR/settings.json" ]; then
    backup_file "$VS_CODE_USER_DIR/settings.json"
fi

# Link profile settings
ln -sf "$VS_CODE_CONFIG_DIR/profiles/$PROFILE/settings.json" "$VS_CODE_USER_DIR/settings.json"

print_success "Switched to VS Code profile: $PROFILE"
EOL

# Make VS Code profile script executable
chmod +x "$SCRIPT_DIR/utils/vscode_profile.sh"

print_success "Configuration management system setup completed"
