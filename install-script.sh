#!/bin/bash

# macOS Developer Environment Setup
# Main installation script that orchestrates the setup process

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export SETUP_DIR="$SCRIPT_DIR"

# Source helper functions
source "$SCRIPT_DIR/utils/helpers.sh"

print_header "macOS Developer Environment Setup"
echo "This script will set up your macOS developer environment with your preferred tools and configurations."
echo "It centralizes configuration management and maintains a clean home directory structure."
echo ""
read -p "Do you want to proceed? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 1
fi

# Create logs directory
mkdir -p "$SCRIPT_DIR/logs"
LOG_FILE="$SCRIPT_DIR/logs/install_$(date +%Y%m%d-%H%M%S).log"
touch "$LOG_FILE"

# Function to run a script and log its output
run_script() {
    local script="$1"
    echo "" | tee -a "$LOG_FILE"
    print_header "Running: $script" | tee -a "$LOG_FILE"
    
    if [ -f "$SCRIPT_DIR/scripts/$script" ]; then
        bash "$SCRIPT_DIR/scripts/$script" 2>&1 | tee -a "$LOG_FILE"
        
        if [ ${PIPESTATUS[0]} -ne 0 ]; then
            print_error "Script $script failed. Check the log at $LOG_FILE"
            return 1
        else
            print_success "Script $script completed successfully!"
            return 0
        fi
    else
        print_error "Script $script not found!"
        return 1
    fi
}

# Execute scripts in sequence
# Phase 1: Core system setup
run_script "00_prerequisites.sh" || exit 1

# Ensure utilities are set up first
print_info "Setting up utility scripts..."
chmod +x "$SCRIPT_DIR/utils/"*.sh

# Phase 2: Essential tools and applications
run_script "01_core_tools.sh" || exit 1
run_script "02_applications.sh" || exit 1

# Phase 3: Configuration and shell
run_script "03_shell_setup.sh" || exit 1
run_script "04_os_preferences.sh" || exit 1

# Final cleanup and verification
run_script "99_cleanup.sh" || exit 1

print_header "Setup Complete!"
echo "Your macOS developer environment has been set up successfully!"
echo "You may need to restart your computer for some changes to take effect."
echo "Log file is available at: $LOG_FILE"
