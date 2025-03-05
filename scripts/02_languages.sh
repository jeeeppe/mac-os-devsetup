#!/bin/bash

# Programming languages installation script
# Installs Python (with UV), JavaScript, and C++ development tools

# Set script directory and load helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

print_header "Setting Up Programming Languages"

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

# Python setup
print_info "Setting up Python environment..."

# Install Python via Homebrew
brew_install "python" || exit 1

# Install UV package manager
print_info "Installing UV package manager..."
brew_install "uv" || exit 1

# Set up a default Python configuration
print_info "Setting up Python configuration..."

# Create a basic pyproject.toml template for future projects
mkdir -p "$SCRIPT_DIR/configs/python"
cat > "$SCRIPT_DIR/configs/python/pyproject.toml.template" << EOL
[build-system]
requires = ["hatchling"]
build-backend = "hatchling.build"

[project]
name = "project-name"
version = "0.1.0"
description = "Project description"
readme = "README.md"
requires-python = ">=3.9"
license = {file = "LICENSE"}
authors = [
    {name = "Your Name", email = "your.email@example.com"},
]
dependencies = []

[project.optional-dependencies]
dev = [
    "pytest",
    "pytest-cov",
    "black",
    "isort",
    "mypy",
    "ruff",
]

[tool.black]
line-length = 88

[tool.isort]
profile = "black"
line_length = 88

[tool.mypy]
python_version = "3.9"
warn_return_any = true
warn_unused_configs = true
disallow_untyped_defs = true
disallow_incomplete_defs = true

[tool.pytest.ini_options]
testpaths = ["tests"]
python_files = ["test_*.py"]
python_functions = ["test_*"]

[tool.ruff]
line-length = 88
target-version = "py39"
select = ["E", "F", "B", "I"]
ignore = []
EOL

print_success "Created Python project template at $SCRIPT_DIR/configs/python/pyproject.toml.template"

# Create Python utility script for creating new projects with UV
cat > "$SCRIPT_DIR/utils/create_python_project.sh" << 'EOL'
#!/bin/bash

# Script to create a new Python project with UV

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

# Get project name from argument or prompt
if [ -z "$1" ]; then
    read -p "Enter project name: " project_name
else
    project_name="$1"
fi

# Create project directory
mkdir -p "$project_name"
cd "$project_name" || exit 1

# Copy pyproject.toml template
cp "$SCRIPT_DIR/configs/python/pyproject.toml.template" "pyproject.toml"

# Update project name in pyproject.toml
sed -i '' "s/project-name/$project_name/g" "pyproject.toml"

# Create basic project structure
mkdir -p "src/$project_name"
mkdir -p "tests"

# Create __init__.py files
touch "src/$project_name/__init__.py"
touch "tests/__init__.py"

# Create a basic README.md
cat > "README.md" << EOF
# $project_name

Project description goes here.

## Installation

\`\`\`bash
uv pip install -e .
\`\`\`

## Development

\`\`\`bash
uv pip install -e ".[dev]"
\`\`\`
EOF

# Create a basic test file
cat > "tests/test_basic.py" << EOF
def test_import():
    import $project_name
    assert $project_name.__name__ == "$project_name"
EOF

# Create main module file
cat > "src/$project_name/main.py" << EOF
def main():
    print("Hello from $project_name!")

if __name__ == "__main__":
    main()
EOF

# Create virtual environment with UV
print_info "Creating virtual environment with UV..."
uv venv

# Activate virtual environment
print_info "To activate the virtual environment, run:"
print_info "source .venv/bin/activate"

print_success "Python project $project_name created successfully!"
EOL

chmod +x "$SCRIPT_DIR/utils/create_python_project.sh"
print_success "Created Python project creation utility at $SCRIPT_DIR/utils/create_python_project.sh"

# JavaScript setup (Node.js)
print_info "Setting up JavaScript environment..."
brew_install "node" || exit 1
brew_install "yarn" || exit 1

# Install some global npm packages
print_info "Installing global npm packages..."
npm install -g npm@latest
npm install -g typescript
npm install -g eslint
npm install -g prettier

# C++ setup
print_info "Setting up C++ environment..."
brew_install "gcc" || exit 1
brew_install "llvm" || exit 1
brew_install "boost" || exit 1
brew_install "fmt" || exit 1
brew_install "googletest" || exit 1

# Create C++ project template
mkdir -p "$SCRIPT_DIR/configs/cpp"
cat > "$SCRIPT_DIR/configs/cpp/CMakeLists.txt.template" << EOL
cmake_minimum_required(VERSION 3.15)
project(ProjectName VERSION 0.1.0)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Enable warnings
if(MSVC)
  add_compile_options(/W4)
else()
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

# Add include directories
include_directories(include)

# Add source files
file(GLOB_RECURSE SOURCES "src/*.cpp")

# Main library
add_library(${PROJECT_NAME} ${SOURCES})

# Executable
add_executable(${PROJECT_NAME}_run src/main.cpp)
target_link_libraries(${PROJECT_NAME}_run PRIVATE ${PROJECT_NAME})

# Tests
enable_testing()
add_subdirectory(tests)
EOL

# Create script for generating C++ projects
cat > "$SCRIPT_DIR/utils/create_cpp_project.sh" << 'EOL'
#!/bin/bash

# Script to create a new C++ project with CMake

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

# Get project name from argument or prompt
if [ -z "$1" ]; then
    read -p "Enter project name: " project_name
else
    project_name="$1"
fi

# Create project directory
mkdir -p "$project_name"
cd "$project_name" || exit 1

# Copy CMakeLists.txt template
cp "$SCRIPT_DIR/configs/cpp/CMakeLists.txt.template" "CMakeLists.txt"

# Update project name in CMakeLists.txt
sed -i '' "s/ProjectName/$project_name/g" "CMakeLists.txt"

# Create basic project structure
mkdir -p "src"
mkdir -p "include/$project_name"
mkdir -p "tests"

# Create a basic header file
cat > "include/$project_name/example.h" << EOF
#pragma once

namespace $project_name {

class Example {
public:
    Example();
    int getValue() const;

private:
    int value_;
};

} // namespace $project_name
EOF

# Create a basic source file
cat > "src/example.cpp" << EOF
#include "$project_name/example.h"

namespace $project_name {

Example::Example() : value_(42) {}

int Example::getValue() const {
    return value_;
}

} // namespace $project_name
EOF

# Create a main file
cat > "src/main.cpp" << EOF
#include <iostream>
#include "$project_name/example.h"

int main() {
    $project_name::Example example;
    std::cout << "Value: " << example.getValue() << std::endl;
    return 0;
}
EOF

# Create tests directory with CMakeLists.txt
cat > "tests/CMakeLists.txt" << EOF
find_package(GTest REQUIRED)
include_directories(\${GTEST_INCLUDE_DIRS})

add_executable(${project_name}_tests test_example.cpp)
target_link_libraries(${project_name}_tests 
    PRIVATE 
    ${project_name}
    \${GTEST_BOTH_LIBRARIES}
    pthread
)

add_test(NAME ${project_name}_tests COMMAND ${project_name}_tests)
EOF

# Create a basic test file
cat > "tests/test_example.cpp" << EOF
#include <gtest/gtest.h>
#include "$project_name/example.h"

TEST(ExampleTest, GetValue) {
    $project_name::Example example;
    EXPECT_EQ(example.getValue(), 42);
}

int main(int argc, char **argv) {
    ::testing::InitGoogleTest(&argc, argv);
    return RUN_ALL_TESTS();
}
EOF

# Create a basic README.md
cat > "README.md" << EOF
# $project_name

A C++ project.

## Building

\`\`\`bash
mkdir build && cd build
cmake ..
make
\`\`\`

## Running

\`\`\`bash
./build/${project_name}_run
\`\`\`

## Testing

\`\`\`bash
cd build
ctest
\`\`\`
EOF

# Create a basic .gitignore
cat > ".gitignore" << EOF
# Build directories
build/
cmake-build-*/

# IDE files
.idea/
.vscode/
*.swp
*~

# Compiled Object files
*.slo
*.lo
*.o
*.obj

# Precompiled Headers
*.gch
*.pch

# Compiled Dynamic libraries
*.so
*.dylib
*.dll

# Compiled Static libraries
*.lai
*.la
*.a
*.lib

# Executables
*.exe
*.out
*.app
EOF

print_success "C++ project $project_name created successfully!"
EOL

chmod +x "$SCRIPT_DIR/utils/create_cpp_project.sh"
print_success "Created C++ project creation utility at $SCRIPT_DIR/utils/create_cpp_project.sh"

print_success "Programming languages setup completed successfully"
exit 0
