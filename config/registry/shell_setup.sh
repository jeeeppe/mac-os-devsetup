#!/bin/bash

# Shell setup script
# Configures zsh and related configurations

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

# Create necessary directories
ensure_dir_exists "$HOME/.config/zsh"
ensure_dir_exists "$HOME/.cache/zsh"
ensure_dir_exists "$HOME/.cache/zsh/zcompcache"

# Create shell aliases file
print_info "Creating shell aliases file..."
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
alias pyvenv="uv venv"
alias pyrun="uv run"

# Environment management
alias denv="$SETUP_DIR/utils/env_manager.sh"
alias creds="$SETUP_DIR/utils/credentials_manager.sh"
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
EOL

# Create shell functions file
print_info "Creating shell functions file..."
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
        print_error "UV is not installed. Please install UV first."
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
    
    if command -v uv >/dev/null 2>&1; then
        echo "UV: $(uv --version 2>/dev/null)"
    fi
    
    echo "Git: $(git --version 2>/dev/null)"
    echo "Homebrew: $(brew --version | head -n 1)"
}

# Load API keys for a specific service
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
bgrun() {
    ("$@" && osascript -e "display notification \"Process completed successfully\" with title \"Background Process\"") &
}
EOL

# Create shell theme file
print_info "Creating shell theme file..."
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

# Right prompt with time
RPROMPT='%F{gray}%*%f'
EOL

# Create completion configuration
print_info "Creating completion configuration..."
cat > "$SCRIPT_DIR/configs/shell/zsh/completion.zsh" << 'EOL'
# Completion configuration

# Add zsh completion system
autoload -Uz compinit
compinit -d "$HOME/.cache/zsh/zcompdump"

# Load completions from Homebrew
if type brew &>/dev/null; then
    FPATH="$(brew --prefix)/share/zsh/site-functions:$FPATH"
    FPATH="$(brew --prefix)/share/zsh-completions:$FPATH"
fi

# Enable menu selection
zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' # Case-insensitive completion
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}" # Colored completion
zstyle ':completion:*' verbose yes                   # Verbose completion
zstyle ':completion:*:descriptions' format '%B%d%b'  # Format descriptions
zstyle ':completion:*:messages' format '%d'          # Format messages
zstyle ':completion:*:warnings' format 'No matches for: %d' # Format warnings
zstyle ':completion:*:corrections' format '%B%d (errors: %e)%b' # Format corrections
zstyle ':completion:*' group-name ''                # Group by category
zstyle ':completion:*' squeeze-slashes true         # Remove slashes
zstyle ':completion:*' use-cache on                 # Use cache
zstyle ':completion:*' cache-path "$HOME/.cache/zsh/zcompcache" # Cache path
EOL

# Create main zshrc
print_info "Creating main zshrc file..."
cat > "$SCRIPT_DIR/configs/shell/zshrc" << 'EOL'
#!/bin/zsh
# Main zsh configuration file

# Define XDG Base Directory paths
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# Path to the developer setup repository
export SETUP_DIR="${SETUP_DIR:-$HOME/macos-dev-setup}"

# Ensure XDG directories exist
mkdir -p "$XDG_CONFIG_HOME/zsh"
mkdir -p "$XDG_CACHE_HOME/zsh"
mkdir -p "$XDG_DATA_HOME/zsh"
mkdir -p "$XDG_STATE_HOME/zsh"

# Initialize Homebrew
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

# Add local bin to PATH
export PATH="$HOME/.local/bin:$PATH"

# Load syntax highlighting if installed
if [ -f "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]; then
    source "$(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"
fi

# Load autosuggestions if installed
if [ -f "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "$(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh"
fi

# Initialize fzf if installed
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# UV settings (Python manager)
export UV_PYTHON_BIN_DIR="$HOME/.local/bin"
export UV_TOOL_BIN_DIR="$HOME/.local/bin"
export UV_TOOL_DIR="$HOME/.local/share/uv/tools"
export UV_PYTHON_INSTALL_DIR="$HOME/.local/share/uv/pythons"
export UV_PYTHON_PREFERENCE="system"

# Welcome message
echo "Welcome to $(hostname -s)!"
echo "macOS $(sw_vers -productVersion)"
echo "Type 'sysinfo' for system information"
EOL

# Install shell configurations using config_manager
print_info "Installing shell configurations using config_manager..."
"$SCRIPT_DIR/utils/config_manager.sh" install shell

# Generate shell completions if tools are available
print_info "Setting up shell completions..."

# Mullvad VPN completions
if command_exists mullvad; then
    print_info "Generating Mullvad VPN shell completions..."
    ensure_dir_exists "$HOME/.config/zsh/completions"
    mullvad shell-completions zsh > "$HOME/.config/zsh/completions/_mullvad"
    print_success "Mullvad VPN shell completions generated"
fi

# Homebrew completions
print_info "Setting up Homebrew completions..."
if brew completions &>/dev/null; then
    brew completions link
    print_success "Homebrew completions linked"
fi

# UV completions
if command_exists uv; then
    print_info "Generating UV shell completions..."
    ensure_dir_exists "$HOME/.config/zsh/completions"
    uv generate-shell-completion zsh > "$HOME/.config/zsh/completions/_uv"
    print_success "UV shell completions generated"
fi

# Add completions directory to FPATH in zshrc if not already present
if ! grep -q "FPATH=\"\$HOME/.config/zsh/completions" "$HOME/.zshrc"; then
    print_info "Adding completions directory to FPATH in zshrc..."
    sed -i '' '/# Load modular configuration files/i\
# Add custom completions to FPATH\
FPATH="$HOME/.config/zsh/completions:$FPATH"\
\
' "$HOME/.zshrc"
    print_success "Completions directory added to FPATH"
fi

# Create a Terminal profile
print_info "Creating Terminal profile..."
mkdir -p "$SCRIPT_DIR/configs/apps"
cat > "$SCRIPT_DIR/configs/apps/terminal_profile.terminal" << 'EOL'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Font</key>
	<data>
	YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMS
	AAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGkCwwVFlUkbnVsbNQNDg8QERIT
	FFZOU1NpemVYTlNmRmxhZ3NWTlNOYW1lViRjbGFzcyNALAAAAAAAABAQgAKAA18QE0pl
	dEJyYWluc01vbm8tUmVndWxhctIXGBkaWiRjbGFzc25hbWVYJGNsYXNzZXNWTlNGb250
	ohkbWE5TT2JqZWN0CBEaJCkyN0lMUVNYXmdud36FjpCSlKOos7zDxgAAAAAAAAEBAAAA
	AAAAABwAAAAAAAAAAAAAAAAAAADP
	</data>
	<key>FontAntialias</key>
	<true/>
	<key>FontWidthSpacing</key>
	<real>1.004032258064516</real>
	<key>ProfileCurrentVersion</key>
	<real>2.0699999999999998</real>
	<key>BackgroundColor</key>
	<data>
	YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMS
	AAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGjCwwTVSRudWxs0w0ODxAREldO
	U1doaXRlXE5TQ29sb3JTcGFjZVYkY2xhc3NGMCAwLjkAEAOAAoAD0hMUFRZaJGNsYXNz
	bmFtZVgkY2xhc3Nlc1dOU0NvbG9yohUXWE5TT2JqZWN0CBEaJCkyN0lMUVNXXWRsed/g
	5OXm6OvxAAAAAAAAAgEAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAPM=
	</data>
	<key>CursorColor</key>
	<data>
	YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMS
	AAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGjCwwTVSRudWxs0w0ODxAREldO
	U1doaXRlXE5TQ29sb3JTcGFjZVYkY2xhc3NLMC4zMDI0MTkzNgAQA4AC0hMUFRZaJGNs
	YXNzbmFtZVgkY2xhc3Nlc1dOU0NvbG9yohUXWE5TT2JqZWN0CBEaJCkyN0lMUVNXXWRs
	eYCMjpCVoKmxtAAAAAAAAAEBAAAAAAAAABkAAAAAAAAAAAAAAAAAAAC9
	</data>
	<key>TextBoldColor</key>
	<data>
	YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMS
	AAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGjCwwTVSRudWxs0w0ODxAREldO
	U1doaXRlXE5TQ29sb3JTcGFjZVYkY2xhc3NCMQAQA4AC0hMUFRZaJGNsYXNzbmFtZVgk
	Y2xhc3Nlc1dOU0NvbG9yohUXWE5TT2JqZWN0CBEaJCkyN0lMUVNXXWRseYCDhYeMl5uf
	qAAAAAAAAAAAAQEAAAAAAAAAGQAAAAAAAAAAAAAAAAAAALI=
	</data>
	<key>TextColor</key>
	<data>
	YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMS
	AAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGjCwwTVSRudWxs0w0ODxAREldO
	U1doaXRlXE5TQ29sb3JTcGFjZVYkY2xhc3NGMCAwLjkAEAOAAoAD0hMUFRZaJGNsYXNz
	bmFtZVgkY2xhc3Nlc1dOU0NvbG9yohUXWE5TT2JqZWN0CBEaJCkyN0lMUVNXXWRsed/g
	5OXm6OvxAAAAAAAAAgEAAAAAAAAAGAAAAAAAAAAAAAAAAAAAAPM=
	</data>
	<key>columnCount</key>
	<integer>100</integer>
	<key>name</key>
	<string>DevSetup</string>
	<key>rowCount</key>
	<integer>30</integer>
	<key>type</key>
	<string>Window Settings</string>
	<key>useOptionAsMetaKey</key>
	<true/>
</dict>
</plist>
EOL

# Apply Terminal profile
print_info "Setting up Terminal.app profile..."
open "$SCRIPT_DIR/configs/apps/terminal_profile.terminal"
sleep 1
defaults write com.apple.Terminal "Default Window Settings" -string "DevSetup"
defaults write com.apple.Terminal "Startup Window Settings" -string "DevSetup"

print_success "Shell environment setup completed successfully"
exit 0
