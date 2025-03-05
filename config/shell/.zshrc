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
