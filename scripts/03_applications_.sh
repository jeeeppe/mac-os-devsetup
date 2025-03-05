#!/bin/bash

# Applications installation script
# Installs and configures VS Code, Sublime Text, and other applications

# Set script directory and load helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

print_header "Installing Applications"

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

# Install required casks
print_info "Installing specified casks..."
brew_cask_install "visual-studio-code" || exit 1
brew_cask_install "brave-browser" || exit 1
brew_cask_install "sublime-text" || exit 1

# Try to install Claude and ChatGPT (these may not exist as casks; fallback to manual)
if ! brew_cask_install "claude"; then
    print_warning "Claude not available as a cask, please install manually from the App Store"
fi

if ! brew_cask_install "chatgpt"; then
    print_warning "ChatGPT not available as a cask, please install manually from the App Store"
fi

# Setup VS Code with multiple profiles
if command_exists code; then
    print_info "Setting up VS Code with multiple profiles..."
    
    # Create directories for centralized VS Code configs
    VS_CODE_CONFIG_DIR="$SCRIPT_DIR/configs/vscode"
    ensure_dir_exists "$VS_CODE_CONFIG_DIR/profiles/coding"
    ensure_dir_exists "$VS_CODE_CONFIG_DIR/profiles/diagramming"
    
    # User settings directory
    VS_CODE_USER_DIR="$HOME/Library/Application Support/Code/User"
    ensure_dir_exists "$VS_CODE_USER_DIR"
    
    # Create coding profile
    cat > "$VS_CODE_CONFIG_DIR/profiles/coding/settings.json" << EOL
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

    # Create diagramming profile
    cat > "$VS_CODE_CONFIG_DIR/profiles/diagramming/settings.json" << EOL
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

    # Create global user settings that manages profiles
    cat > "$VS_CODE_CONFIG_DIR/settings.json" << EOL
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

    # Create profiles list
    cat > "$VS_CODE_CONFIG_DIR/profiles.json" << EOL
{
    "profiles": [
        {
            "name": "Coding",
            "settings": "$VS_CODE_CONFIG_DIR/profiles/coding/settings.json"
        },
        {
            "name": "Diagramming",
            "settings": "$VS_CODE_CONFIG_DIR/profiles/diagramming/settings.json"
        }
    ],
    "default": "Coding"
}
EOL

    # Link VS Code configs
    if [ -f "$VS_CODE_USER_DIR/settings.json" ]; then
        backup_file "$VS_CODE_USER_DIR/settings.json"
    fi
    ln -sf "$VS_CODE_CONFIG_DIR/settings.json" "$VS_CODE_USER_DIR/settings.json"
    
    # Create a script to switch profiles
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

    chmod +x "$SCRIPT_DIR/utils/vscode_profile.sh"
    
    # Python extensions
    print_info "Installing VS Code extensions for Python development..."
    code --install-extension ms-python.python
    code --install-extension ms-python.vscode-pylance
    code --install-extension ms-python.black-formatter
    code --install-extension matangover.mypy
    
    # JavaScript/TypeScript extensions
    print_info "Installing VS Code extensions for JavaScript/TypeScript development..."
    code --install-extension dbaeumer.vscode-eslint
    code --install-extension esbenp.prettier-vscode
    
    # Diagramming extensions
    print_info "Installing VS Code extensions for diagramming..."
    code --install-extension hediet.vscode-drawio
    code --install-extension bierner.markdown-mermaid
    code --install-extension jebbs.plantuml
    
    # General extensions
    print_info "Installing general VS Code extensions..."
    code --install-extension eamodio.gitlens
    code --install-extension yzhang.markdown-all-in-one
    code --install-extension streetsidesoftware.code-spell-checker
    
    # Theme
    code --install-extension GitHub.github-vscode-theme
    
    print_success "VS Code setup completed with multiple profiles"
else
    print_warning "VS Code command-line tools not found, please install them manually"
    print_warning "You can do this by opening VS Code and pressing Cmd+Shift+P, then typing 'shell command' and selecting 'Install code command in PATH'"
fi

# Setup Sublime Text preferences
print_info "Setting up Sublime Text..."
SUBLIME_CONFIG_DIR="$SCRIPT_DIR/configs/sublime"
ensure_dir_exists "$SUBLIME_CONFIG_DIR"

SUBLIME_USER_DIR="$HOME/Library/Application Support/Sublime Text/Packages/User"
ensure_dir_exists "$SUBLIME_USER_DIR"

# Sublime Text Preferences
cat > "$SUBLIME_CONFIG_DIR/Preferences.sublime-settings" << EOL
{
    "font_face": "JetBrains Mono",
    "font_size": 14,
    "theme": "Default Dark.sublime-theme",
    "color_scheme": "Packages/Color Scheme - Default/Monokai.sublime-color-scheme",
    "line_padding_top": 1,
    "line_padding_bottom": 1,
    "hardware_acceleration": "opengl",
    "highlight_line": true,
    "highlight_modified_tabs": true,
    "word_wrap": true,
    "tab_size": 4,
    "translate_tabs_to_spaces": true,
    "trim_trailing_white_space_on_save": true,
    "ensure_newline_at_eof_on_save": true,
    "rulers": [88, 120],
    "save_on_focus_lost": true,
    "bold_folder_labels": true,
    "fade_fold_buttons": false,
    "show_full_path": true,
    "show_encoding": true,
    "show_line_endings": true,
    "scroll_past_end": true
}
EOL

# Link Sublime Text preferences
if [ -f "$SUBLIME_USER_DIR/Preferences.sublime-settings" ]; then
    backup_file "$SUBLIME_USER_DIR/Preferences.sublime-settings"
fi
ln -sf "$SUBLIME_CONFIG_DIR/Preferences.sublime-settings" "$SUBLIME_USER_DIR/Preferences.sublime-settings"

# Install JetBrains Mono font
if [ ! -d "$HOME/Library/Fonts/JetBrainsMono" ]; then
    print_info "Installing JetBrains Mono font..."
    FONT_TMP="$(mktemp -d)"
    curl -fsSL https://download.jetbrains.com/fonts/JetBrainsMono-2.242.zip -o "$FONT_TMP/JetBrainsMono.zip"
    unzip -q "$FONT_TMP/JetBrainsMono.zip" -d "$FONT_TMP"
    ensure_dir_exists "$HOME/Library/Fonts/JetBrainsMono"
    cp "$FONT_TMP/fonts/ttf/"*.ttf "$HOME/Library/Fonts/JetBrainsMono/"
    rm -rf "$FONT_TMP"
    print_success "JetBrains Mono font installed"
else
    print_info "JetBrains Mono font already installed, skipping"
fi

# Create app configs directory for Claude and ChatGPT
print_info "Creating directories for app configurations..."
ensure_dir_exists "$SCRIPT_DIR/configs/claude"
ensure_dir_exists "$SCRIPT_DIR/configs/chatgpt"
ensure_dir_exists "$SCRIPT_DIR/configs/mullvad"
ensure_dir_exists "$SCRIPT_DIR/configs/docker"

# Link Docker config if it exists
DOCKER_CONFIG_DIR="$HOME/.docker"
if [ -d "$DOCKER_CONFIG_DIR" ]; then
    print_info "Linking Docker configuration..."
    backup_file "$DOCKER_CONFIG_DIR/config.json"
    cp -r "$DOCKER_CONFIG_DIR/"* "$SCRIPT_DIR/configs/docker/"
    # Create symlinks for Docker config files
    for file in "$SCRIPT_DIR/configs/docker/"*; do
        if [ -f "$file" ]; then
            ln -sf "$file" "$DOCKER_CONFIG_DIR/$(basename "$file")"
        fi
    done
    print_success "Docker configuration linked"
fi

# Create a note about Claude and ChatGPT config linking
cat > "$SCRIPT_DIR/configs/app_config_note.md" << EOL
# App Configuration Notes

## Claude and ChatGPT
As these applications store their configurations in non-standard locations or within app sandboxes, 
it may not be possible to directly link their configurations. When you discover where these apps 
store their data, you can:

1. Copy the configuration to the corresponding directory in \`configs/claude\` or \`configs/chatgpt\`
2. Create symlinks if possible, or document the location for future reference

## MullvadVPN
MullvadVPN configurations can be found in:
- Settings: \`/Library/Application Support/Mullvad VPN/\`
- Cache: \`~/Library/Caches/net.mullvad.vpn\`

## Docker
Docker configurations are stored in \`~/.docker/\` and have been linked to \`configs/docker/\`

## Manual configuration backups
You can periodically run:
\`\`\`bash
\$SCRIPT_DIR/utils/backup_config.sh
\`\`\`
to back up your configurations.
EOL

print_success "Applications installation completed successfully"
print_info "Note: Some configurations require manual linking. See $SCRIPT_DIR/configs/app_config_note.md for details."
exit 0
