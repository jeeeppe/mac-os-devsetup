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

# Install VS Code
print_info "Installing Visual Studio Code..."
brew_cask_install "visual-studio-code" || exit 1

# Install Sublime Text
print_info "Installing Sublime Text..."
brew_cask_install "sublime-text" || exit 1

# Install other useful applications
print_info "Installing additional applications..."

# Development tools
brew_cask_install "iterm2" || exit 1           # Better terminal
brew_cask_install "postman" || exit 1          # API testing tool
brew_cask_install "docker" || exit 1           # Containerization

# Utilities
brew_cask_install "rectangle" || exit 1        # Window management
brew_cask_install "the-unarchiver" || exit 1   # Better archive extraction
brew_cask_install "alfred" || exit 1           # Spotlight alternative
brew_cask_install "appcleaner" || exit 1       # Clean app uninstallation

# Setup VS Code extensions
if command_exists code; then
    print_info "Installing VS Code extensions..."
    
    # Python extensions
    code --install-extension ms-python.python
    code --install-extension ms-python.vscode-pylance
    code --install-extension ms-python.black-formatter
    code --install-extension matangover.mypy
    
    # JavaScript/TypeScript extensions
    code --install-extension dbaeumer.vscode-eslint
    code --install-extension esbenp.prettier-vscode
    code --install-extension ms-vscode.vscode-typescript-next
    
    # C/C++ extensions
    code --install-extension ms-vscode.cpptools
    code --install-extension ms-vscode.cmake-tools
    
    # General extensions
    code --install-extension eamodio.gitlens
    code --install-extension github.copilot
    code --install-extension yzhang.markdown-all-in-one
    code --install-extension streetsidesoftware.code-spell-checker
    code --install-extension gruntfuggly.todo-tree
    code --install-extension ms-vsliveshare.vsliveshare
    
    # Theme
    code --install-extension GitHub.github-vscode-theme

    # Create VS Code settings directory if it doesn't exist
    VS_CODE_SETTINGS_DIR="$HOME/Library/Application Support/Code/User"
    ensure_dir_exists "$VS_CODE_SETTINGS_DIR"
    
    # Create VS Code settings.json
    VS_CODE_SETTINGS="$VS_CODE_SETTINGS_DIR/settings.json"
    
    if [ ! -f "$VS_CODE_SETTINGS" ]; then
        print_info "Creating VS Code settings.json..."
        cat > "$VS_CODE_SETTINGS" << EOL
{
    "editor.fontSize": 14,
    "editor.fontFamily": "JetBrains Mono, Menlo, Monaco, 'Courier New', monospace",
    "editor.fontLigatures": true,
    "editor.tabSize": 4,
    "editor.insertSpaces": true,
    "editor.formatOnSave": true,
    "editor.formatOnPaste": true,
    "editor.rulers": [88, 120],
    "editor.bracketPairColorization.enabled": true,
    "editor.guides.bracketPairs": true,
    "editor.minimap.enabled": false,
    "editor.cursorBlinking": "smooth",
    "editor.cursorSmoothCaretAnimation": "on",
    "editor.renderWhitespace": "boundary",
    "editor.suggestSelection": "first",
    "editor.renderControlCharacters": true,
    "editor.linkedEditing": true,
    "files.autoSave": "afterDelay",
    "files.autoSaveDelay": 1000,
    "files.trimTrailingWhitespace": true,
    "files.insertFinalNewline": true,
    "files.trimFinalNewlines": true,
    "workbench.editor.enablePreview": false,
    "workbench.startupEditor": "newUntitledFile",
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
    "python.linting.pylintEnabled": false,
    "python.linting.mypyEnabled": true,
    "python.formatting.provider": "none",
    "black-formatter.args": ["--line-length", "88"],
    "[javascript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode",
        "editor.formatOnSave": true
    },
    "[typescript]": {
        "editor.defaultFormatter": "esbenp.prettier-vscode",
        "editor.formatOnSave": true
    },
    "[cpp]": {
        "editor.defaultFormatter": "ms-vscode.cpptools",
        "editor.formatOnSave": true
    },
    "C_Cpp.clang_format_style": "file",
    "git.autofetch": true,
    "git.confirmSync": false,
    "gitlens.codeLens.enabled": true,
    "todo-tree.general.tags": [
        "BUG",
        "HACK",
        "FIXME",
        "TODO",
        "XXX",
        "NOTE"
    ],
    "terminal.integrated.defaultProfile.osx": "zsh"
}
EOL
        print_success "VS Code settings created"
    else
        print_info "VS Code settings already exist, skipping"
    fi
else
    print_warning "VS Code command-line tools not found, please install them manually"
    print_warning "You can do this by opening VS Code and pressing Cmd+Shift+P, then typing 'shell command' and selecting 'Install code command in PATH'"
fi

# Setup Sublime Text preferences
SUBLIME_SETTINGS_DIR="$HOME/Library/Application Support/Sublime Text/Packages/User"
ensure_dir_exists "$SUBLIME_SETTINGS_DIR"

# Sublime Text Preferences
SUBLIME_PREFS="$SUBLIME_SETTINGS_DIR/Preferences.sublime-settings"
if [ ! -f "$SUBLIME_PREFS" ]; then
    print_info "Creating Sublime Text preferences..."
    cat > "$SUBLIME_PREFS" << EOL
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
    print_success "Sublime Text preferences created"
else
    print_info "Sublime Text preferences already exist, skipping"
fi

# Install JetBrains Mono font (used in editor settings)
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

print_success "Applications installation completed successfully"
exit 0
