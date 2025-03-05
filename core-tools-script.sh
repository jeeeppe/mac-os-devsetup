#!/bin/bash

# Core development tools installation script
# Installs essential development tools via Homebrew

# Set script directory and load helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

print_header "Installing Core Development Tools"

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

# Install Git
print_info "Installing Git and related tools..."
brew_install "git" || exit 1
brew_install "git-lfs" || exit 1

# Install UV (Python package manager)
print_info "Installing UV for Python management..."
brew_install "uv" || exit 1

# Install terminal utilities
print_info "Installing terminal utilities..."
brew_install "micro" || exit 1  # Terminal editor
brew_install "bat" || exit 1    # Better cat
brew_install "exa" || exit 1    # Better ls
brew_install "fd" || exit 1     # Better find
brew_install "ripgrep" || exit 1 # Better grep
brew_install "fzf" || exit 1    # Fuzzy finder
brew_install "jq" || exit 1     # JSON processor
brew_install "yq" || exit 1     # YAML processor
brew_install "htop" || exit 1   # Process viewer
brew_install "tmux" || exit 1   # Terminal multiplexer
brew_install "tree" || exit 1   # Directory tree view

# Install shell enhancements (for zsh)
print_info "Installing shell enhancements..."
brew_install "zsh-syntax-highlighting" || exit 1
brew_install "zsh-autosuggestions" || exit 1
brew_install "zsh-completions" || exit 1

# Install additional core tools
print_info "Installing additional core tools..."
brew_install "wget" || exit 1
brew_install "curl" || exit 1
brew_install "rsync" || exit 1
brew_install "openssl" || exit 1
brew_install "ssh-copy-id" || exit 1

# Install build tools
print_info "Installing build tools..."
brew_install "cmake" || exit 1
brew_install "make" || exit 1
brew_install "automake" || exit 1
brew_install "pkg-config" || exit 1

# Setup fzf
print_info "Setting up fzf..."
$(brew --prefix)/opt/fzf/install --key-bindings --completion --no-update-rc --no-bash --no-fish

# Create base gitconfig template if it doesn't exist
if [ ! -f "$SCRIPT_DIR/configs/git/gitconfig" ]; then
    print_info "Creating Git configuration template..."
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
EOL
fi

# Create base gitignore if it doesn't exist
if [ ! -f "$SCRIPT_DIR/configs/git/gitignore" ]; then
    print_info "Creating global Git ignore template..."
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
fi

# Configure Git with user information
if ! git config --global user.name >/dev/null 2>&1 || ! git config --global user.email >/dev/null 2>&1; then
    print_info "Setting up Git user information..."
    
    echo "You'll need to provide some basic information for Git:"
    read -p "Enter your full name for Git: " git_name
    read -p "Enter your email for Git: " git_email
    
    git config --global user.name "$git_name"
    git config --global user.email "$git_email"
    
    # Replace placeholders in the template
    sed -i '' "s/{{GIT_USERNAME}}/$git_name/g" "$SCRIPT_DIR/configs/git/gitconfig"
    sed -i '' "s/{{GIT_EMAIL}}/$git_email/g" "$SCRIPT_DIR/configs/git/gitconfig"
    
    print_success "Git configured with name: $git_name and email: $git_email"
else
    # Use existing Git information
    git_name=$(git config --global user.name)
    git_email=$(git config --global user.email)
    
    # Replace placeholders in the template
    sed -i '' "s/{{GIT_USERNAME}}/$git_name/g" "$SCRIPT_DIR/configs/git/gitconfig"
    sed -i '' "s/{{GIT_EMAIL}}/$git_email/g" "$SCRIPT_DIR/configs/git/gitconfig"
    
    print_info "Using existing Git configuration: $git_name <$git_email>"
fi

# Setup SSH key for Git if it doesn't exist
ssh_key="$HOME/.ssh/id_ed25519"
if [ ! -f "$ssh_key" ]; then
    print_info "Setting up SSH key for Git..."
    
    # Ensure .ssh directory exists with proper permissions
    mkdir -p "$HOME/.ssh"
    chmod 700 "$HOME/.ssh"
    
    # Create SSH key
    ssh-keygen -t ed25519 -C "$git_email" -f "$ssh_key"
    
    # Start the ssh-agent and add the key
    eval "$(ssh-agent -s)"
    ssh-add "$ssh_key"
    
    # Copy public key to clipboard
    if command_exists pbcopy; then
        pbcopy < "$ssh_key.pub"
        print_success "SSH public key copied to clipboard"
    else
        print_info "Your SSH public key is:"
        cat "$ssh_key.pub"
    fi
    
    print_info "Please add this SSH key to your GitHub/GitLab accounts"
else
    print_info "SSH key already exists at $ssh_key"
fi

print_success "Core development tools installed successfully"
exit 0
