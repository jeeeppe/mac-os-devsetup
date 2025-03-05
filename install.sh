#!/bin/bash

# macOS developer environment setup main installation script
# This script orchestrates the setup of a complete macOS developer environment

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCRIPTS_PATH="$SCRIPT_DIR/scripts"
CONFIG_PATH="$SCRIPT_DIR/configs"
UTILS_PATH="$SCRIPT_DIR/utils"

# Source helper functions
source "$UTILS_PATH/helpers.sh"

# Print welcome message
print_header "macOS Developer Environment Setup"
echo "This script will set up your macOS developer environment with your preferred tools and configurations."
echo "Make sure you're running this on a fresh macOS installation or be aware that some settings may be overwritten."
echo ""
read -p "Do you want to proceed? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Setup cancelled."
    exit 1
fi

# Create a log file
mkdir -p "$SCRIPT_DIR/logs"
LOG_FILE="$SCRIPT_DIR/logs/install_$(date +%Y%m%d-%H%M%S).log"
touch "$LOG_FILE"

# Function to run a script and log its output
run_script() {
    local script="$1"
    echo "" | tee -a "$LOG_FILE"
    print_header "Running: $script" | tee -a "$LOG_FILE"
    
    if [ -f "$SCRIPTS_PATH/$script" ]; then
        bash "$SCRIPTS_PATH/$script" 2>&1 | tee -a "$LOG_FILE"
        
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

# Set up configuration management system first
print_header "Setting up configuration management system"
source "$UTILS_PATH/config_setup.sh"

# Execute scripts in sequence
# Each script returns a status code - non-zero indicates failure

# Phase 1: Core system setup
run_script "00_prerequisites.sh" || exit 1
run_script "01_core_tools.sh" || exit 1

# Phase 2: Programming languages and environments
run_script "02_languages.sh" || exit 1

# Phase 3: Applications and editors
run_script "03_applications.sh" || exit 1

# Phase 4: Shell configuration
run_script "04_shell_setup.sh" || exit 1

# Phase 5: OS Preferences
run_script "05_os_preferences.sh" || exit 1

# Final cleanup and verification
run_script "99_cleanup.sh" || exit 1

print_header "Setup Complete!"
echo "Your macOS developer environment has been set up successfully!"
echo "You may need to restart your computer for some changes to take effect."
echo "Log file is available at: $LOG_FILE"
