#!/bin/bash

# Shell setup script
# Configures zsh and related plugins manually (no oh-my-zsh)

# Set script directory and load helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

print_header "Setting Up Shell Environment"

# Make sure Homebrew is initialized for this session
if [[ $(uname -m) == "arm64" ]]; then
    # M1/M2 Mac
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    # Intel Mac
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Check if zsh is the default shell
if [[ "$SHELL" != *"zsh"* ]]; then
    print_info "Setting zsh as the default shell..."
    chsh -s "$(which zsh)"
    print_success "zsh set as the default shell. You may need to restart your terminal."
else
    print_info "zsh is already the default shell"
fi

# Create centralized shell configuration directories
SHELL_CONFIG_DIR="$SCRIPT_DIR/configs/shell"
ensure_dir_exists "$SHELL_CONFIG_DIR"
ensure_dir_exists "$HOME/.config/zsh"
ensure_dir_exists "$HOME/.cache/zsh"

# Back up existing .zshrc if it exists
if [ -f "$HOME/.zshrc" ]; then
    backup_file "$HOME/.zshrc"
fi

# Create shell configuration files
print_info "Creating shell configuration files..."

# Create shell aliases file
cat > "$SHELL_CONFIG_DIR/aliases.zsh" << 'EOL'
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

# VS Code profiles
alias vscode-coding="$SCRIPT_DIR/utils/vscode_profile.sh coding"
alias vscode-diagram="$SCRIPT_DIR/utils/vscode_profile.sh diagramming"

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

# Credential management
alias creds="$SCRIPT_DIR/utils/credentials_manager.sh"
EOL

# Create shell functions file
cat > "$SHELL_CONFIG_DIR/functions.zsh" << 'EOL'
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
    if command -v uv >/dev/null 2>&1; then
        uv venv "${1:-.venv}"
        echo "To activate: source ${1:-.venv}/bin/activate"
    else
        python3 -m venv "${1:-.venv}"
        echo "To activate: source ${1:-.venv}/bin/activate"
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
    $SCRIPT_DIR/utils/credentials_manager.sh export "$env_file" "$filter"
    
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

# Create shell theme file
cat > "$SHELL_CONFIG_DIR/theme.zsh" << 'EOL'
# Shell theme and prompt customization

# Enable colors
autoload -U colors && colors

# Custom prompt with git info
autoload -Uz vcs_info
precmd() { vcs_info }

# Format the vcs_info_msg_0_ variable
zstyle ':vcs_info:git:*' formats '%F{blue}(%b)%f '
zstyle ':vcs_info:*' enable git

# Set the prompt
PROMPT='%F{green}%n%f@%F{yellow}%m%f:%F{cyan}%~%f ${vcs_info_msg_0_}%F{red}%(?..✘)%f$ '

# Right prompt with time
RPROMPT='%F{gray}%*%f'
EOL

# Create shell paths file
cat > "$SHELL_CONFIG_DIR/paths.zsh" << 'EOL'
# Shell paths and environment variables

# Add local bin directory to PATH
export PATH="$HOME/.local/bin:$PATH"

# Add Homebrew paths
if [[ $(uname -m) == "arm64" ]]; then
    # M1/M2 Mac
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    # Intel Mac
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Add additional brew paths
export PATH="$(brew --prefix)/opt/curl/bin:$PATH"
export PATH="$(brew --prefix)/opt/openssl/bin:$PATH"

# Add brew sbin
export PATH="$(brew --prefix)/sbin:$PATH"

# Python settings
export PYTHONDONTWRITEBYTECODE=1
export PYTHONUNBUFFERED=1

# Editor
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

# Homebrew options
export HOMEBREW_NO_ANALYTICS=1
export HOMEBREW_NO_ENV_HINTS=1

# FZF settings
if [ -f ~/.fzf.zsh ]; then
    export FZF_DEFAULT_OPTS="--height 40% --layout=reverse --border --inline-info"
    export FZF_DEFAULT_COMMAND="fd --type f --hidden --follow --exclude .git"
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Custom location for zsh cache and history
export HISTFILE="$HOME/.cache/zsh/zsh_history"
export ZSH_COMPDUMP="$HOME/.cache/zsh/zcompdump"

# Ensure cache directories exist
mkdir -p "$HOME/.cache/zsh"
EOL

# Create completion setup
cat > "$SHELL_CONFIG_DIR/completion.zsh" << 'EOL'
# Completion configuration

# Load completions from Homebrew
if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
    FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"
fi

# Initialize completion system
autoload -Uz compinit
compinit -d $ZSH_COMPDUMP

# Completion options
zstyle ':completion:*' menu select                  # Menu-driven completion
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case-insensitive completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Colored completion
zstyle ':completion:*' verbose yes                  # Verbose completion
zstyle ':completion:*:descriptions' format '%B%d%b' # Format descriptions
zstyle ':completion:*:messages' format '%d'         # Format messages
zstyle ':completion:*:warnings' format 'No matches for: %d' # Format warnings
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b' # Format corrections
zstyle ':completion:*' group-name ''                # Group by category
zstyle ':completion:*' squeeze-slashes true         # Remove slashes

# Cache completions
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$HOME/.cache/zsh/zcompcache"
ensure_dir_exists "$HOME/.cache/zsh/zcompcache"
EOL

# Create main .zshrc file
cat > "$SHELL_CONFIG_DIR/.zshrc" << EOL
#!/bin/zsh
# Main zsh configuration file

# Path to the setup directory
SETUP_DIR="$SCRIPT_DIR"

# Load shell configuration files
source "\$SETUP_DIR/configs/shell/paths.zsh"
source "\$SETUP_DIR/configs/shell/theme.zsh"
source "\$SETUP_DIR/configs/shell/completion.zsh"
source "\$SETUP_DIR/configs/shell/aliases.zsh"
source "\$SETUP_DIR/configs/shell/functions.zsh"

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

# Enable color in ls
export CLICOLOR=1
export LSCOLORS=ExFxBxDxCxegedabagacad

# Load syntax highlighting if installed
if [ -f "\$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "\$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Load autosuggestions if installed
if [ -f "\$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "\$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Load fzf if installed
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# Welcome message
echo "Welcome to $(hostname -s)!"
echo "macOS $(sw_vers -productVersion)"
echo "Type 'sysinfo' for system information"
EOL

# Link the zshrc to the home directory
ln -sf "$SHELL_CONFIG_DIR/.zshrc" "$HOME/.zshrc"

# Make all config files executable
chmod +x "$SHELL_CONFIG_DIR"/*.zsh
chmod +x "$HOME/.zshrc"

print_success "Shell configuration set up successfully"
print_info "Please restart your terminal or run 'source ~/.zshrc' to apply changes"
exit 0
