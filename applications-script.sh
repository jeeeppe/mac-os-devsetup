#!/bin/bash

# Applications installation script
# Installs and configures major applications

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

# VS Code
print_info "Installing Visual Studio Code..."
brew_cask_install "visual-studio-code" || exit 1

# Brave Browser
print_info "Installing Brave Browser..."
brew_cask_install "brave-browser" || exit 1

# iTerm2
print_info "Installing iTerm2..."
brew_cask_install "iterm2" || exit 1

# Docker
print_info "Installing Docker..."
brew_cask_install "docker" || exit 1

# Mullvad VPN
print_info "Installing Mullvad VPN..."
brew_cask_install "mullvadvpn" || exit 1

# Other useful applications
print_info "Installing additional applications..."
brew_cask_install "rectangle" || exit 1    # Window management
brew_cask_install "alfred" || exit 1       # Spotlight replacement
brew_cask_install "sublime-text" || exit 1 # Text editor

# Setup VS Code configuration directories
print_info "Setting up VS Code configuration directories..."
ensure_dir_exists "$SCRIPT_DIR/configs/vscode/profiles/coding" || exit 1
ensure_dir_exists "$SCRIPT_DIR/configs/vscode/profiles/diagramming" || exit 1

# Setup VS Code main settings if they don't exist
if [ ! -f "$SCRIPT_DIR/configs/vscode/settings.json" ]; then
    print_info "Creating VS Code main settings..."
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
fi

# Setup VS Code coding profile settings if they don't exist
if [ ! -f "$SCRIPT_DIR/configs/vscode/profiles/coding/settings.json" ]; then
    print_info "Creating VS Code coding profile settings..."
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
fi

# Setup VS Code diagramming profile settings if they don't exist
if [ ! -f "$SCRIPT_DIR/configs/vscode/profiles/diagramming/settings.json" ]; then
    print_info "Creating VS Code diagramming profile settings..."
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
fi

# Create VS Code profile switcher
print_info "Creating VS Code profile switcher..."
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

# Make VS Code profile switcher executable
chmod +x "$SCRIPT_DIR/utils/vscode_profile.sh"

# Install JetBrains Mono font
if [ ! -d "$HOME/Library/Fonts/JetBrainsMono" ]; then
    print_info "Installing JetBrains Mono font..."
    FONT_TMP="$(mktemp -d)"
    curl -fsSL https://download.jetbrains.com/fonts/JetBrainsMono-2.242.zip -o "$FONT_TMP/JetBrainsMono.zip"
    unzip -q "$FONT_TMP/JetBrainsMono.zip" -d "$FONT_TMP"
    mkdir -p "$HOME/Library/Fonts/JetBrainsMono"
    cp "$FONT_TMP/fonts/ttf/"*.ttf "$HOME/Library/Fonts/JetBrainsMono/"
    rm -rf "$FONT_TMP"
    print_success "JetBrains Mono font installed"
else
    print_info "JetBrains Mono font already installed, skipping"
fi

# Install VS Code extensions if VS Code CLI is available
if command_exists code; then
    print_info "Installing VS Code extensions..."
    
    # Python extensions
    code --install-extension ms-python.python || true
    code --install-extension ms-python.vscode-pylance || true
    code --install-extension ms-python.black-formatter || true
    
    # JavaScript/TypeScript extensions
    code --install-extension dbaeumer.vscode-eslint || true
    code --install-extension esbenp.prettier-vscode || true
    
    # Diagramming extensions
    code --install-extension hediet.vscode-drawio || true
    code --install-extension bierner.markdown-mermaid || true
    
    # General extensions
    code --install-extension eamodio.gitlens || true
    code --install-extension yzhang.markdown-all-in-one || true
    code --install-extension github.github-vscode-theme || true
    
    print_success "VS Code extensions installed"
else
    print_warning "VS Code command-line tools not found. Install VS Code extensions manually."
    print_warning "To install VS Code CLI: Open VS Code, press Cmd+Shift+P, type 'shell command' and select 'Install code command in PATH'"
fi

# Create application config directories
print_info "Creating application config directories..."
ensure_dir_exists "$SCRIPT_DIR/configs/iterm2" || exit 1
ensure_dir_exists "$SCRIPT_DIR/configs/docker" || exit 1
ensure_dir_exists "$SCRIPT_DIR/configs/mullvad" || exit 1

# Create app config note file
print_info "Creating application configuration note..."
cat > "$SCRIPT_DIR/configs/app_config_note.md" << 'EOL'
# Application Configuration Notes

## Docker
Docker configuration is stored in `~/.docker/`. If you have custom Docker configurations, you can copy them to `configs/docker/` and they will be managed by the configuration system.

## Mullvad VPN
Mullvad VPN configurations can be found in:
- Settings: `/Library/Application Support/Mullvad VPN/`
- Cache: `~/Library/Caches/net.mullvad.vpn`

## iTerm2
iTerm2 configurations are stored in:
- `~/Library/Preferences/com.googlecode.iterm2.plist`
- `~/Library/Application Support/iTerm2/`

After configuring iTerm2 to your liking, you can export your profile by:
1. Open iTerm2
2. Go to Preferences -> Profiles
3. Select your profile
4. Click "Other Actions" -> "Save Profile as JSON..."
5. Save to `configs/iterm2/profile.json`

## Manual Configuration Backups
You can periodically back up your configurations by running:
```bash
$SETUP_DIR/utils/backup_config.sh
```
EOL

print_success "Applications installed successfully"
exit 0
