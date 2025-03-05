#!/bin/bash

# Cleanup script
# Performs final cleanup and verification of setup

# Set script directory and load helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

print_header "Performing Final Cleanup and Verification"

# Make sure Homebrew is initialized for this session
if [[ $(uname -m) == "arm64" ]]; then
    # M1/M2 Mac
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    # Intel Mac
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Check for system updates
print_info "Checking for system updates..."
softwareupdate -l

# Clean up Homebrew
print_info "Cleaning up Homebrew..."
brew cleanup

# Verify key software installations
print_info "Verifying key software installations..."

verify_installation() {
    local name="$1"
    local command="$2"
    
    if command_exists "$command"; then
        local version
        version=$($3)
        print_success "$name is installed: $version"
    else
        print_error "$name is not installed"
    fi
}

verify_installation "Git" "git" "git --version"
verify_installation "Python" "python3" "python3 --version"
verify_installation "Node.js" "node" "node --version"
verify_installation "UV" "uv" "uv --version"
verify_installation "Micro" "micro" "micro --version"
verify_installation "VS Code" "code" "code --version | head -n 1"

# Check zsh configuration
print_info "Verifying shell configuration..."
if [[ "$SHELL" == *"zsh"* ]]; then
    print_success "zsh is the default shell"
else
    print_warning "zsh is not the default shell"
fi

if [ -f "$HOME/.zshrc" ]; then
    print_success ".zshrc exists"
else
    print_error ".zshrc does not exist"
fi

# Clean up caches and temporary files
print_info "Cleaning up caches and temporary files..."

# Clean Homebrew cache
brew cleanup --prune=all

# Clean various caches
rm -rf ~/Library/Caches/com.apple.dt.Xcode 2>/dev/null
rm -rf ~/Library/Developer/Xcode/DerivedData 2>/dev/null
rm -rf ~/Library/Developer/Xcode/Archives 2>/dev/null

# Clean Python cache files
find ~ -name "__pycache__" -type d -exec rm -rf {} +  2>/dev/null || true
find ~ -name "*.pyc" -delete 2>/dev/null || true
find ~ -name "*.pyo" -delete 2>/dev/null || true

# Clean npm cache
if command_exists npm; then
    npm cache clean --force
fi

# Clean yarn cache
if command_exists yarn; then
    yarn cache clean
fi

# Create a credentials manager for API keys
print_info "Setting up secure API credentials manager..."

mkdir -p "$SCRIPT_DIR/utils"
cat > "$SCRIPT_DIR/utils/credentials_manager.sh" << 'EOL'
#!/bin/bash

# API Credentials Manager
# A utility to securely store and access API keys

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

CREDENTIALS_DIR="$HOME/.config/credentials"
ENCRYPTED_FILE="$CREDENTIALS_DIR/api_keys.enc"

# Make sure directory exists
ensure_dir_exists "$CREDENTIALS_DIR"
chmod 700 "$CREDENTIALS_DIR"

# Function to encrypt the credentials file
encrypt_credentials() {
    local temp_file="$CREDENTIALS_DIR/temp_keys.json"
    
    # Write JSON to temp file
    echo "$1" > "$temp_file"
    
    # Encrypt the file
    openssl enc -aes-256-cbc -salt -in "$temp_file" -out "$ENCRYPTED_FILE"
    
    # Remove temp file
    rm "$temp_file"
    
    print_success "Credentials encrypted and saved"
}

# Function to decrypt the credentials file
decrypt_credentials() {
    if [ ! -f "$ENCRYPTED_FILE" ]; then
        echo "{}"
        return
    fi
    
    # Decrypt the file
    openssl enc -aes-256-cbc -d -salt -in "$ENCRYPTED_FILE" 2>/dev/null || echo "{}"
}

# Function to list all stored API keys
list_keys() {
    local credentials
    credentials=$(decrypt_credentials)
    
    if [ "$credentials" == "{}" ]; then
        print_info "No API keys stored yet"
        return
    fi
    
    echo "$credentials" | jq -r 'keys[]'
}

# Function to add or update an API key
add_key() {
    local key_name="$1"
    local key_value="$2"
    
    if [ -z "$key_name" ] || [ -z "$key_value" ]; then
        print_error "Both key name and value are required"
        return 1
    fi
    
    local credentials
    credentials=$(decrypt_credentials)
    
    # Update or add the key
    local updated_credentials
    updated_credentials=$(echo "$credentials" | jq --arg name "$key_name" --arg value "$key_value" '. + {($name): $value}')
    
    # Encrypt and save
    encrypt_credentials "$updated_credentials"
}

# Function to get an API key
get_key() {
    local key_name="$1"
    
    if [ -z "$key_name" ]; then
        print_error "Key name is required"
        return 1
    fi
    
    local credentials
    credentials=$(decrypt_credentials)
    
    # Get the key value
    local key_value
    key_value=$(echo "$credentials" | jq -r --arg name "$key_name" '.[$name] // "Key not found"')
    
    if [ "$key_value" == "Key not found" ]; then
        print_error "Key '$key_name' not found"
        return 1
    fi
    
    echo "$key_value"
}

# Function to remove an API key
remove_key() {
    local key_name="$1"
    
    if [ -z "$key_name" ]; then
        print_error "Key name is required"
        return 1
    fi
    
    local credentials
    credentials=$(decrypt_credentials)
    
    # Remove the key
    local updated_credentials
    updated_credentials=$(echo "$credentials" | jq --arg name "$key_name" 'del(.[$name])')
    
    # Encrypt and save
    encrypt_credentials "$updated_credentials"
}

# Function to load API keys into the environment
load_keys() {
    local credentials
    credentials=$(decrypt_credentials)
    
    # Check if we have any keys
    if [ "$credentials" == "{}" ]; then
        print_info "No API keys to load"
        return
    fi
    
    # Extract keys and values and set them as environment variables
    local keys
    keys=$(echo "$credentials" | jq -r 'keys[]')
    
    for key in $keys; do
        local value
        value=$(echo "$credentials" | jq -r --arg name "$key" '.[$name]')
        export "$key"="$value"
        print_info "Loaded $key into environment"
    done
}

# Main functionality based on first argument
case "$1" in
    list)
        list_keys
        ;;
    add)
        add_key "$2" "$3"
        ;;
    get)
        get_key "$2"
        ;;
    remove)
        remove_key "$2"
        ;;
    load)
        load_keys
        ;;
    *)
        echo "Usage: credentials_manager.sh [list|add|get|remove|load] [key_name] [key_value]"
        echo "  list                List all stored API keys"
        echo "  add <key> <value>   Add or update an API key"
        echo "  get <key>           Get the value of an API key"
        echo "  remove <key>        Remove an API key"
        echo "  load                Load all API keys into environment"
        ;;
esac
EOL

chmod +x "$SCRIPT_DIR/utils/credentials_manager.sh"
print_success "Created API credentials manager at $SCRIPT_DIR/utils/credentials_manager.sh"

# Create a README.md file with instructions
print_info "Creating README.md with instructions..."
cat > "$SCRIPT_DIR/README.md" << 'EOL'
# macOS Developer Environment Setup

This repository contains scripts and configurations to automate the setup of a macOS developer environment. It's designed to be run on a fresh macOS installation to set up a complete development environment with all necessary tools and configurations.

## What's Included

This setup includes:

- Core development tools (Git, terminal utilities, etc.)
- Programming languages (Python with UV, JavaScript, C++)
- Applications (VS Code, Sublime Text, iTerm2, etc.)
- Shell configuration (zsh with plugins and customizations)
- macOS system preferences
- Utilities for creating new projects

## Usage

1. Clone this repository:

```bash
git clone https://github.com/yourusername/macos-dev-setup.git
cd macos-dev-setup
```

2. Make the install script executable:

```bash
chmod +x install.sh
```

3. Run the install script:

```bash
./install.sh
```

The script will guide you through the installation process and will require your input at various stages.

## Manual Steps After Installation

After running the installation script, you may need to:

1. Restart your computer to apply all changes
2. Run `source ~/.zshrc` to reload your shell configuration
3. Complete any additional setup steps for specific applications (like signing in to accounts)

## Project Structure

- `install.sh`: Main orchestration script
- `scripts/`: Individual installation scripts for different components
- `configs/`: Configuration files for applications and tools
- `utils/`: Utility scripts and helpers

## Included Utilities

### Python Project Creation

To create a new Python project with UV:

```bash
pycreate my_project
```

### C++ Project Creation

To create a new C++ project:

```bash
cppcreate my_cpp_project
```

### API Credentials Manager

To manage your API keys securely:

```bash
# List all stored keys
credentials_manager.sh list

# Add a new key
credentials_manager.sh add OPENAI_API_KEY your_api_key_here

# Get a key
credentials_manager.sh get OPENAI_API_KEY

# Remove a key
credentials_manager.sh remove OPENAI_API_KEY

# Load all keys into environment
credentials_manager.sh load
```

## Customization

You can customize this setup by:

1. Editing the configuration files in the `configs/` directory
2. Modifying the installation scripts in the `scripts/` directory
3. Adding your own scripts to the `utils/` directory

## Maintenance

To update your environment:

1. Pull the latest changes from the repository
2. Run the install script again to apply the updates

## License

This project is licensed under the MIT License - see the LICENSE file for details.
EOL

print_success "README.md created with instructions"

# Add instruction to add the API credentials manager to the shell configuration
if [ -f "$HOME/.zshrc" ]; then
    append_if_not_exists "$HOME/.zshrc" '
# Function to load API credentials into current environment
load_api_keys() {
    "$SETUP_DIR/utils/credentials_manager.sh" load
}

# Add an alias for credentials manager
alias creds="$SETUP_DIR/utils/credentials_manager.sh"
'
fi

# Create a git repository for version control
if [ -d "$SCRIPT_DIR/.git" ]; then
    print_info "Git repository already exists"
else
    print_info "Initializing git repository for version control..."
    cd "$SCRIPT_DIR" || exit 1
    git init
    
    # Create a .gitignore file
    cat > "$SCRIPT_DIR/.gitignore" << 'EOL'
# Logs
logs/
*.log

# OS generated files
.DS_Store
.DS_Store?
._*
.Spotlight-V100
.Trashes
ehthumbs.db
Thumbs.db

# Local configuration files that might contain sensitive information
*.local.sh
EOL
    
    # Make initial commit
    git add .
    git commit -m "Initial commit: Developer environment setup"
    
    print_success "Git repository initialized"
fi

# Remind user to restart
print_header "Setup Complete!"
print_info "Your macOS developer environment has been set up successfully!"
print_info ""
print_info "Please restart your computer to ensure all changes take effect."
print_info ""
print_info "After restarting:"
print_info "1. Open Terminal.app to see your new shell configuration"
print_info "2. Check VS Code and other applications to make sure they're correctly set up"
print_info "3. You can use the utilities in the 'utils/' directory to create new projects"
print_info "4. Use 'creds' to manage your API credentials"
print_info ""
print_info "For more information, see the README.md file."

exit 0
