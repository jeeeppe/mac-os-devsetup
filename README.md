# macOS Developer Environment Setup

A comprehensive system to automate the setup and maintenance of a macOS development environment. This project provides scripts to install essential developer tools, configure applications, and maintain consistent environments across machines.

## Features

- **Modular Installation**: Separate scripts for prerequisites, core tools, applications, and OS preferences
- **Configuration Management**: Centralized configuration with registry-based tracking
- **Credential Management**: Securely store and manage API keys and sensitive credentials
- **Environment Management**: Create isolated development environments for different projects
- **Application Management**: Curated installation and configuration of developer tools
- **Backup and Maintenance**: Tools to back up and maintain your configurations

## Requirements

- macOS 10.15 (Catalina) or later
- Administrative access to your machine
- Internet connection

## Quick Start

```bash
# Clone the repository
git clone https://github.com/jeeeppe/mac-os-devsetup.git
cd mac-os-devsetup

# Make scripts executable
chmod +x install.sh
chmod +x utils/*.sh
chmod +x scripts/*.sh

# Run the installation
./install.sh
```

## What's Included

### Core Development Tools

- **Version Control**: Git with sensible defaults and LFS support
- **Shell**: Enhanced ZSH configuration with modern plugins
- **Terminal**: Configured Terminal.app and iTerm2 (optional)
- **Python Management**: UV for Python package and environment management
- **Editors**: VS Code with multiple profiles (coding, diagramming)
- **Utilities**: Modern replacements for core Unix tools (exa, bat, fd, ripgrep, etc.)
- **Security**: Mullvad VPN for secure connections
- **Containers**: Docker for containerized development

### Directory Structure

```
├── install.sh                   # Main orchestration script
├── scripts/                     # Installation phases
│   ├── 00_prerequisites.sh      # System checks, Homebrew
│   ├── 01_core_tools.sh         # Core dev tools (git, etc.)
│   ├── 02_applications.sh       # Main applications
│   ├── 03_shell_setup.sh        # Shell configuration
│   ├── 04_os_preferences.sh     # macOS system preferences
│   └── 99_cleanup.sh            # Verification and cleanup
├── configs/                     # Configuration templates
│   ├── git/                     # Git configurations
│   ├── vscode/                  # VS Code settings and profiles
│   ├── shell/                   # Shell configurations
│   │   ├── zsh/                 # Modular zsh components
│   └── registry/                # Configuration registries
└── utils/                       # Utility scripts
    ├── helpers.sh               # Common utility functions
    ├── config_manager.sh        # Configuration management
    ├── credentials_manager.sh   # API key/credentials management
    ├── env_manager.sh           # Dev environment management
    ├── backup_config.sh         # Configuration backup
    └── vscode_profile.sh        # VS Code profile switching
```

## Usage Guide

### Configuration Manager

The configuration manager centralizes and manages configuration files:

```bash
# Install configurations from a registry
./utils/config_manager.sh install shell

# Check if configurations are correctly installed
./utils/config_manager.sh check git

# List all available configuration registries
./utils/config_manager.sh list

# Scan for existing configuration files
./utils/config_manager.sh scan
```

### Credentials Manager

Securely store and manage API keys:

```bash
# List all environments
./utils/credentials_manager.sh environments

# Create a new environment
./utils/credentials_manager.sh create_env ai-tools

# List stored API keys in an environment
./utils/credentials_manager.sh list ai-tools

# Add a new API key
./utils/credentials_manager.sh add OPENAI_API_KEY sk-abcdef123456 ai-tools

# Get an API key
./utils/credentials_manager.sh get OPENAI_API_KEY ai-tools

# Load API keys into environment
./utils/credentials_manager.sh load OPENAI ai-tools

# Export keys to an .env file
./utils/credentials_manager.sh export .env.ai OPENAI ai-tools
```

### Environment Manager

Create and manage isolated development environments:

```bash
# Create a new environment
./utils/env_manager.sh create myproject python

# List all environments
./utils/env_manager.sh list

# Activate an environment
./utils/env_manager.sh activate myproject

# Create a Python project with UV
./utils/env_manager.sh python new-app app

# Remove an environment
./utils/env_manager.sh remove myproject
```

### VS Code Profile Switcher

Switch between different VS Code profiles:

```bash
# Switch to coding profile
./utils/vscode_profile.sh coding

# Switch to diagramming profile
./utils/vscode_profile.sh diagramming
```

### Backup Utility

Backup your configuration files:

```bash
# Backup configuration files
./utils/backup_config.sh
```

## Customization

### Adding New Applications

Edit `scripts/02_applications.sh` to add or remove applications:

```bash
# Add a new application
brew_cask_install "your-application-name"
```

### Adding Configuration Files

1. Create a new registry file in `configs/registry/` (see existing ones for examples)
2. Add your configuration files to the appropriate subdirectory in `configs/`
3. Run `./utils/config_manager.sh install your-registry`

### Modifying macOS Preferences

Edit `scripts/04_os_preferences.sh` to change macOS system preferences.

## Maintenance

### Keeping Configurations Updated

Run the backup utility to copy your latest configurations:

```bash
./utils/backup_config.sh
```

### Updating the System

Pull the latest changes from the repository and run the install script again:

```bash
git pull
./install.sh
```

Or run individual scripts to update specific components:

```bash
./scripts/01_core_tools.sh
```

## License

This project is released under the MIT License.
