#!/bin/bash

# Shell Integration Script for Developer Workflow Utilities
# Adds the workflow utilities to the shell configuration

# Set script directory and load helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

print_header "Integrating Developer Workflow Utilities"

# Ensure the developer workflow script is present
DEV_WORKFLOW_SRC="$SCRIPT_DIR/configs/shell/dev_workflow.sh"
DEV_WORKFLOW_DEST="$HOME/.config/shell/dev_workflow.sh"

if [ ! -f "$DEV_WORKFLOW_SRC" ]; then
    print_error "Developer workflow script not found at $DEV_WORKFLOW_SRC"
    exit 1
fi

# Ensure destination directory exists
ensure_dir_exists "$(dirname "$DEV_WORKFLOW_DEST")"

# Copy the developer workflow script
print_info "Installing developer workflow utilities..."
cp "$DEV_WORKFLOW_SRC" "$DEV_WORKFLOW_DEST"
chmod +x "$DEV_WORKFLOW_DEST"

# Add to zsh configuration if not already present
ZSHRC="$HOME/.zshrc"

if [ -f "$ZSHRC" ]; then
    if ! grep -q "dev_workflow.sh" "$ZSHRC"; then
        print_info "Adding developer workflow utilities to zsh configuration..."
        cat >> "$ZSHRC" << 'EOL'

# Developer workflow utilities
if [ -f "$HOME/.config/shell/dev_workflow.sh" ]; then
    source "$HOME/.config/shell/dev_workflow.sh"
fi

# Add aliases for dev workflow utilities
alias denv="$SCRIPT_DIR/utils/env_manager.sh"
alias pr="createpr"
alias vcinit="gitinit"
EOL
        print_success "Developer workflow utilities added to zsh configuration"
    else
        print_info "Developer workflow utilities already in zsh configuration"
    fi
else
    print_warning "zsh configuration file not found at $ZSHRC"
fi

# Create symbolic links for utilities in ~/.local/bin
LOCAL_BIN="$HOME/.local/bin"
ensure_dir_exists "$LOCAL_BIN"

# Create symbolic links for utilities
print_info "Creating symbolic links for utilities..."

# Link env_manager.sh
if [ -f "$SCRIPT_DIR/utils/env_manager.sh" ]; then
    ln -sf "$SCRIPT_DIR/utils/env_manager.sh" "$LOCAL_BIN/denv"
    chmod +x "$SCRIPT_DIR/utils/env_manager.sh"
    print_success "Created symbolic link for denv"
else
    print_error "Environment manager script not found"
fi

# Link credentials_manager.sh
if [ -f "$SCRIPT_DIR/utils/credentials_manager.sh" ]; then
    ln -sf "$SCRIPT_DIR/utils/credentials_manager.sh" "$LOCAL_BIN/creds"
    chmod +x "$SCRIPT_DIR/utils/credentials_manager.sh"
    print_success "Created symbolic link for creds"
else
    print_error "Credentials manager script not found"
fi

# Installing GitHub CLI if not already installed
if ! command_exists gh; then
    print_info "Installing GitHub CLI (required for PR creation)..."
    brew_install gh
    
    # Prompt user to log in to GitHub
    print_info "Please authenticate with GitHub by running: gh auth login"
else
    print_info "GitHub CLI already installed"
fi

print_success "Developer workflow utilities integration completed"
print_info "Please restart your shell or run 'source ~/.zshrc' to start using the utilities"
print_info "Usage examples:"
print_info "  - Create a development environment: denv create myproject python"
print_info "  - Initialize a Git repository: gitinit myproject"
print_info "  - Create a new branch: newbranch feature/my-feature"
print_info "  - Save changes: savepoint \"My commit message\""
print_info "  - Create a PR: createpr \"My PR title\""
print_info "  - Run a command in background: bgrun make build"
print_info "  - Set up a project: devsetup"
print_info "  - Start a development server: serve 8080"
print_info "  - Generate documentation: gendocs"


#zsh compinit: insecure directories, run compaudit for list.
#Ignore insecure directories and continue [y] or abort compinit [n]? ncompinit: initialization aborted
#/Users/jesperknutsson/Downloads/macos-dev-setup-main/configs/shell/completion.zsh:28: command not found: ensure_dir_exists