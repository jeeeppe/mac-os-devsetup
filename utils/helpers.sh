#!/bin/bash

# Helper functions for macOS setup scripts
# These functions are used across all setup scripts

# Colors for better output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Print a header with decoration
print_header() {
    local text="$1"
    local width=$(( ${#text} + 4 ))
    local line=$(printf "%${width}s" | tr ' ' '=')
    
    echo -e "${BLUE}${line}${NC}"
    echo -e "${BLUE}| ${CYAN}${text}${BLUE} |${NC}"
    echo -e "${BLUE}${line}${NC}"
}

# Print an info message
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Print a success message
print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# Print a warning message
print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Print an error message
print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check if a homebrew formula is installed
brew_formula_installed() {
    brew list "$1" >/dev/null 2>&1
}

# Check if a homebrew cask is installed
brew_cask_installed() {
    brew list --cask "$1" >/dev/null 2>&1
}

# Install a homebrew formula if not already installed
brew_install() {
    local formula="$1"
    
    if brew_formula_installed "$formula"; then
        print_info "Formula $formula is already installed"
    else
        print_info "Installing formula: $formula"
        brew install "$formula"
        if [ $? -eq 0 ]; then
            print_success "Formula $formula installed successfully"
        else
            print_error "Failed to install formula $formula"
            return 1
        fi
    fi
    
    return 0
}

# Install a homebrew cask if not already installed
brew_cask_install() {
    local cask="$1"
    
    if brew_cask_installed "$cask"; then
        print_info "Cask $cask is already installed"
    else
        print_info "Installing cask: $cask"
        brew install --cask "$cask"
        if [ $? -eq 0 ]; then
            print_success "Cask $cask installed successfully"
        else
            print_error "Failed to install cask $cask"
            return 1
        fi
    fi
    
    return 0
}

# Safely create a backup of a file before modifying it
backup_file() {
    local file="$1"
    
    if [ -f "$file" ]; then
        local backup="${file}.backup-$(date +%Y%m%d-%H%M%S)"
        print_info "Backing up $file to $backup"
        cp "$file" "$backup"
        return $?
    fi
    
    return 0
}

# Create a directory if it doesn't exist
ensure_dir_exists() {
    local dir="$1"
    
    if [ ! -d "$dir" ]; then
        print_info "Creating directory: $dir"
        mkdir -p "$dir"
        if [ $? -eq 0 ]; then
            print_success "Directory created successfully"
        else
            print_error "Failed to create directory $dir"
            return 1
        fi
    fi
    
    return 0
}

# Check macOS version
check_macos_version() {
    local min_version="$1"
    local current_version=$(sw_vers -productVersion)
    
    print_info "Current macOS version: $current_version"
    
    if [[ "$current_version" < "$min_version" ]]; then
        print_error "This script requires macOS $min_version or higher"
        return 1
    fi
    
    return 0
}

# Install or update Homebrew
ensure_homebrew() {
    if command_exists brew; then
        print_info "Homebrew is already installed, updating..."
        brew update
    else
        print_info "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for the current session
        if [[ $(uname -m) == "arm64" ]]; then
            # M1/M2 Mac
            eval "$(/opt/homebrew/bin/brew shellenv)"
        else
            # Intel Mac
            eval "$(/usr/local/bin/brew shellenv)"
        fi
    fi
    
    # Verify installation
    if command_exists brew; then
        print_success "Homebrew installed successfully: $(brew --version | head -n 1)"
        return 0
    else
        print_error "Failed to install Homebrew"
        return 1
    fi
}

# Safely copy a configuration file, creating a backup if the destination exists
safe_copy() {
    local src="$1"
    local dest="$2"
    
    if [ ! -f "$src" ]; then
        print_error "Source file $src does not exist"
        return 1
    fi
    
    # Create directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"
    
    # Backup existing file
    backup_file "$dest"
    
    # Copy file
    print_info "Copying $src to $dest"
    cp "$src" "$dest"
    
    if [ $? -eq 0 ]; then
        print_success "File copied successfully"
        return 0
    else
        print_error "Failed to copy file"
        return 1
    fi
}

# Append text to a file if it doesn't already contain it
append_if_not_exists() {
    local file="$1"
    local text="$2"
    
    if [ ! -f "$file" ]; then
        mkdir -p "$(dirname "$file")"
        echo "$text" > "$file"
        print_info "Created $file with content"
        return 0
    fi
    
    if grep -q "$text" "$file"; then
        print_info "Text already exists in $file"
        return 0
    else
        print_info "Appending text to $file"
        echo "$text" >> "$file"
        return 0
    fi
}
