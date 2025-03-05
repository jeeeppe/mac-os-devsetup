#!/bin/bash

# Development Environment Manager
# Creates, activates, and manages isolated development environments

# Set script directory and load helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

ENVIRONMENTS_DIR="$HOME/.dev_environments"

# Make sure environments directory exists
ensure_dir_exists "$ENVIRONMENTS_DIR"

# Function to create a new environment
create_environment() {
    local env_name="$1"
    local env_type="$2"
    
    if [ -z "$env_name" ]; then
        read -p "Enter environment name: " env_name
    fi
    
    if [ -z "$env_type" ]; then
        echo "Select environment type:"
        echo "1) Python (UV)"
        echo "2) Node.js"
        echo "3) C++"
        echo "4) Generic"
        read -p "Enter choice (1-4): " type_choice
        
        case $type_choice in
            1) env_type="python" ;;
            2) env_type="node" ;;
            3) env_type="cpp" ;;
            4) env_type="generic" ;;
            *) print_error "Invalid choice"; return 1 ;;
        esac
    fi
    
    # Validate environment name
    if [[ ! "$env_name" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        print_error "Environment name must only contain letters, numbers, hyphens, and underscores"
        return 1
    fi
    
    # Check if environment already exists
    if [ -d "$ENVIRONMENTS_DIR/$env_name" ]; then
        print_error "Environment '$env_name' already exists"
        return 1
    fi
    
    # Create environment directory
    print_info "Creating environment '$env_name' of type '$env_type'..."
    mkdir -p "$ENVIRONMENTS_DIR/$env_name"
    
    # Create environment metadata
    local env_meta="$ENVIRONMENTS_DIR/$env_name/.env_meta"
    echo "name=$env_name" > "$env_meta"
    echo "type=$env_type" >> "$env_meta"
    echo "created=$(date +%Y-%m-%d)" >> "$env_meta"
    
    # Create environment activation script
    local env_activate="$ENVIRONMENTS_DIR/$env_name/activate.sh"
    
    # Create the activation script based on environment type
    case $env_type in
        python)
            # Create Python virtual environment
            print_info "Creating Python virtual environment with UV..."
            
            if command_exists uv; then
                (cd "$ENVIRONMENTS_DIR/$env_name" && uv venv)
            else
                print_error "UV is not installed. Please install UV first."
                return 1
            fi
            
            # Create .python-version file
            echo "3.13" > "$ENVIRONMENTS_DIR/$env_name/.python-version"
            
            # Create activation script
            cat > "$env_activate" << 'EOL'
#!/bin/bash

# Get the directory of this script
ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="$(basename "$ENV_DIR")"

# Activate Python virtual environment
source "$ENV_DIR/.venv/bin/activate"

# Set environment variables
export DEV_ENV_NAME="$ENV_NAME"
export DEV_ENV_TYPE="python"
export DEV_ENV_DIR="$ENV_DIR"

# Add bin directory to PATH
export PATH="$ENV_DIR/bin:$PATH"

# Create a custom prompt
PS1_BACKUP="$PS1"
export PS1="(env:$ENV_NAME) $PS1"

# Function to deactivate the environment
deactivate_dev_env() {
    # Deactivate Python virtual environment
    deactivate

    # Restore original prompt
    export PS1="$PS1_BACKUP"
    
    # Unset environment variables
    unset DEV_ENV_NAME
    unset DEV_ENV_TYPE
    unset DEV_ENV_DIR
    unset PS1_BACKUP
    
    # Remove deactivate function
    unset -f deactivate_dev_env
}

# Register the deactivation function
alias deactivate=deactivate_dev_env

echo "Development environment '$ENV_NAME' activated"
echo "Type 'deactivate' to exit the environment"
EOL
            ;;
            
        node)
            # Create Node.js environment
            print_info "Creating Node.js environment..."
            
            # Create a package.json if it doesn't exist
            if [ ! -f "$ENVIRONMENTS_DIR/$env_name/package.json" ]; then
                (cd "$ENVIRONMENTS_DIR/$env_name" && npm init -y)
            fi
            
            # Create bin directory
            mkdir -p "$ENVIRONMENTS_DIR/$env_name/bin"
            mkdir -p "$ENVIRONMENTS_DIR/$env_name/node_modules/.bin"
            
            # Create activation script
            cat > "$env_activate" << 'EOL'
#!/bin/bash

# Get the directory of this script
ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="$(basename "$ENV_DIR")"

# Set environment variables
export DEV_ENV_NAME="$ENV_NAME"
export DEV_ENV_TYPE="node"
export DEV_ENV_DIR="$ENV_DIR"

# Add node_modules/.bin and bin directory to PATH
export PATH_BACKUP="$PATH"
export PATH="$ENV_DIR/node_modules/.bin:$ENV_DIR/bin:$PATH"

# Create a custom prompt
PS1_BACKUP="$PS1"
export PS1="(env:$ENV_NAME) $PS1"

# Function to deactivate the environment
deactivate_dev_env() {
    # Restore original PATH
    export PATH="$PATH_BACKUP"
    
    # Restore original prompt
    export PS1="$PS1_BACKUP"
    
    # Unset environment variables
    unset DEV_ENV_NAME
    unset DEV_ENV_TYPE
    unset DEV_ENV_DIR
    unset PS1_BACKUP
    unset PATH_BACKUP
    
    # Remove deactivate function
    unset -f deactivate_dev_env
}

# Register the deactivation function
alias deactivate=deactivate_dev_env

echo "Development environment '$ENV_NAME' activated"
echo "Type 'deactivate' to exit the environment"
EOL
            ;;
            
        cpp)
            # Create C++ environment
            print_info "Creating C++ environment..."
            
            # Create basic directory structure
            mkdir -p "$ENVIRONMENTS_DIR/$env_name/src"
            mkdir -p "$ENVIRONMENTS_DIR/$env_name/include"
            mkdir -p "$ENVIRONMENTS_DIR/$env_name/build"
            mkdir -p "$ENVIRONMENTS_DIR/$env_name/bin"
            
            # Create a basic CMakeLists.txt
            cat > "$ENVIRONMENTS_DIR/$env_name/CMakeLists.txt" << EOF
cmake_minimum_required(VERSION 3.15)
project($env_name VERSION 0.1.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Add include directories
include_directories(include)

# Add source files
file(GLOB_RECURSE SOURCES "src/*.cpp")

# Main library
add_library(\${PROJECT_NAME} \${SOURCES})

# Executable
add_executable(\${PROJECT_NAME}_run src/main.cpp)
target_link_libraries(\${PROJECT_NAME}_run PRIVATE \${PROJECT_NAME})

# Set output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY \${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY \${CMAKE_BINARY_DIR}/lib)
EOF
            
            # Create a sample source file
            mkdir -p "$ENVIRONMENTS_DIR/$env_name/src"
            cat > "$ENVIRONMENTS_DIR/$env_name/src/main.cpp" << EOF
#include <iostream>

int main() {
    std::cout << "Hello from $env_name environment!" << std::endl;
    return 0;
}
EOF
            
            # Create activation script
            cat > "$env_activate" << 'EOL'
#!/bin/bash

# Get the directory of this script
ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="$(basename "$ENV_DIR")"

# Set environment variables
export DEV_ENV_NAME="$ENV_NAME"
export DEV_ENV_TYPE="cpp"
export DEV_ENV_DIR="$ENV_DIR"

# Add bin directory to PATH
export PATH_BACKUP="$PATH"
export PATH="$ENV_DIR/bin:$ENV_DIR/build/bin:$PATH"

# Set environment variables for build
export CMAKE_BUILD_DIR="$ENV_DIR/build"

# Create a custom prompt
PS1_BACKUP="$PS1"
export PS1="(env:$ENV_NAME) $PS1"

# Add helper function for building
build() {
    local build_type="${1:-Debug}"
    
    echo "Building in $build_type mode..."
    mkdir -p "$CMAKE_BUILD_DIR"
    (cd "$CMAKE_BUILD_DIR" && \
     cmake -DCMAKE_BUILD_TYPE="$build_type" .. && \
     cmake --build .)
     
    if [ $? -eq 0 ]; then
        echo "Build successful!"
    else
        echo "Build failed!"
    fi
}

# Function to deactivate the environment
deactivate_dev_env() {
    # Restore original PATH
    export PATH="$PATH_BACKUP"
    
    # Restore original prompt
    export PS1="$PS1_BACKUP"
    
    # Unset environment variables
    unset DEV_ENV_NAME
    unset DEV_ENV_TYPE
    unset DEV_ENV_DIR
    unset PS1_BACKUP
    unset PATH_BACKUP
    unset CMAKE_BUILD_DIR
    
    # Remove helper functions
    unset -f build
    unset -f deactivate_dev_env
}

# Register the deactivation function
alias deactivate=deactivate_dev_env

echo "Development environment '$ENV_NAME' activated"
echo "Type 'build' to compile the project"
echo "Type 'deactivate' to exit the environment"
EOL
            ;;
            
        generic)
            # Create generic environment
            print_info "Creating generic environment..."
            
            # Create basic directory structure
            mkdir -p "$ENVIRONMENTS_DIR/$env_name/bin"
            
            # Create activation script
            cat > "$env_activate" << 'EOL'
#!/bin/bash

# Get the directory of this script
ENV_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ENV_NAME="$(basename "$ENV_DIR")"

# Set environment variables
export DEV_ENV_NAME="$ENV_NAME"
export DEV_ENV_TYPE="generic"
export DEV_ENV_DIR="$ENV_DIR"

# Add bin directory to PATH
export PATH_BACKUP="$PATH"
export PATH="$ENV_DIR/bin:$PATH"

# Create a custom prompt
PS1_BACKUP="$PS1"
export PS1="(env:$ENV_NAME) $PS1"

# Function to deactivate the environment
deactivate_dev_env() {
    # Restore original PATH
    export PATH="$PATH_BACKUP"
    
    # Restore original prompt
    export PS1="$PS1_BACKUP"
    
    # Unset environment variables
    unset DEV_ENV_NAME
    unset DEV_ENV_TYPE
    unset DEV_ENV_DIR
    unset PS1_BACKUP
    unset PATH_BACKUP
    
    # Remove deactivate function
    unset -f deactivate_dev_env
}

# Register the deactivation function
alias deactivate=deactivate_dev_env

echo "Development environment '$ENV_NAME' activated"
echo "Type 'deactivate' to exit the environment"
EOL
            ;;
    esac
    
    # Make activation script executable
    chmod +x "$env_activate"
    
    print_success "Environment '$env_name' created successfully"
    print_info "To activate, run: source $env_activate"
}

# Function to list all environments
list_environments() {
    print_header "Development Environments"
    
    # Check if any environments exist
    if [ ! "$(ls -A "$ENVIRONMENTS_DIR" 2>/dev/null)" ]; then
        print_info "No environments found"
        return
    fi
    
    # List all environments
    for env_dir in "$ENVIRONMENTS_DIR"/*; do
        if [ -d "$env_dir" ]; then
            env_name=$(basename "$env_dir")
            env_meta="$env_dir/.env_meta"
            
            if [ -f "$env_meta" ]; then
                env_type=$(grep "type=" "$env_meta" | cut -d= -f2)
                env_created=$(grep "created=" "$env_meta" | cut -d= -f2)
                echo "- $env_name (Type: $env_type, Created: $env_created)"
            else
                echo "- $env_name (Type: unknown)"
            fi
        fi
    done
}

# Function to activate an environment
activate_environment() {
    local env_name="$1"
    
    if [ -z "$env_name" ]; then
        # List available environments for selection
        echo "Available environments:"
        list_environments
        
        read -p "Enter environment name to activate: " env_name
    fi
    
    if [ -z "$env_name" ]; then
        print_error "Environment name is required"
        return 1
    fi
    
    # Check if environment exists
    if [ ! -d "$ENVIRONMENTS_DIR/$env_name" ]; then
        print_error "Environment '$env_name' does not exist"
        return 1
    fi
    
    # Check if activation script exists
    local env_activate="$ENVIRONMENTS_DIR/$env_name/activate.sh"
    if [ ! -f "$env_activate" ]; then
        print_error "Activation script for '$env_name' not found"
        return 1
    fi
    
    # Print the command to run
    print_info "To activate, run: source $env_activate"
}

# Function to remove an environment
remove_environment() {
    local env_name="$1"
    
    if [ -z "$env_name" ]; then
        # List available environments for selection
        echo "Available environments:"
        list_environments
        
        read -p "Enter environment name to remove: " env_name
    fi
    
    if [ -z "$env_name" ]; then
        print_error "Environment name is required"
        return 1
    fi
    
    # Check if environment exists
    if [ ! -d "$ENVIRONMENTS_DIR/$env_name" ]; then
        print_error "Environment '$env_name' does not exist"
        return 1
    fi
    
    # Confirm removal
    read -p "Are you sure you want to remove environment '$env_name'? This cannot be undone. (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Operation cancelled"
        return
    fi
    
    # Remove the environment
    rm -rf "$ENVIRONMENTS_DIR/$env_name"
    print_success "Environment '$env_name' removed successfully"
}

# Create a Python project with UV
create_python_project() {
    local project_name="$1"
    local project_type="${2:-app}"
    
    if [ -z "$project_name" ]; then
        read -p "Enter project name: " project_name
    fi
    
    if [ -z "$project_name" ]; then
        print_error "Project name is required"
        return 1
    fi
    
    # Check if UV is installed
    if ! command_exists uv; then
        print_error "UV is not installed. Please install UV first."
        return 1
    fi
    
    # Create project using UV
    print_info "Creating Python project '$project_name'..."
    
    case "$project_type" in
        lib)
            uv init --lib "$project_name"
            ;;
        package)
            uv init --package "$project_name"
            ;;
        app|*)
            uv init "$project_name"
            ;;
    esac
    
    if [ $? -ne 0 ]; then
        print_error "Failed to create project"
        return 1
    fi
    
    # Change to project directory
    cd "$project_name" || return 1
    
    # Create virtual environment with UV
    print_info "Creating virtual environment..."
    uv venv
    
    print_success "Python project '$project_name' created successfully"
    print_info "To activate the virtual environment, run: source .venv/bin/activate"
    print_info "Directory: $(pwd)"
}

# Function to print usage information
print_usage() {
    echo "Development Environment Manager"
    echo "Usage: env_manager.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  create [name] [type]   Create a new environment"
    echo "  list                   List all environments"
    echo "  activate [name]        Activate an environment"
    echo "  remove [name]          Remove an environment"
    echo "  python [name] [type]   Create a Python project with UV (types: app, lib, package)"
    echo "  help                   Show this help message"
    echo ""
    echo "Environment Types:"
    echo "  - python               Python environment with UV"
    echo "  - node                 Node.js environment"
    echo "  - cpp                  C++ environment with CMake"
    echo "  - generic              Generic environment"
    echo ""
    echo "Examples:"
    echo "  env_manager.sh create myproject python"
    echo "  env_manager.sh list"
    echo "  env_manager.sh activate myproject"
    echo "  env_manager.sh remove myproject"
    echo "  env_manager.sh python myapp app"
}

# Main functionality based on first argument
case "$1" in
    create)
        create_environment "$2" "$3"
        ;;
    list)
        list_environments
        ;;
    activate)
        activate_environment "$2"
        ;;
    remove)
        remove_environment "$2"
        ;;
    python)
        create_python_project "$2" "$3"
        ;;
    help)
        print_usage
        ;;
    *)
        print_usage
        ;;
esac
