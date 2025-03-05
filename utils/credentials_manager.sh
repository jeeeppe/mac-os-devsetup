#!/bin/bash

# Enhanced API Credentials Manager
# Securely store and access API keys for different environments

# Set script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

# XDG Base Directory paths
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"

# Centralized credentials storage
CREDENTIALS_DIR="$XDG_CONFIG_HOME/credentials"
ensure_dir_exists "$CREDENTIALS_DIR"
chmod 700 "$CREDENTIALS_DIR"  # Secure permissions

# Default encrypted files for different environments
MAIN_KEYS_FILE="$CREDENTIALS_DIR/api_keys.enc"
KEYCHAIN_PREFIX="dev_env_credentials"

# Function to get password from keychain or prompt user
get_password() {
    local environment="${1:-main}"
    local keychain_entry="${KEYCHAIN_PREFIX}_${environment}"
    local password
    
    # Try to get password from keychain
    if password=$(security find-generic-password -a "$USER" -s "$keychain_entry" -w 2>/dev/null); then
        echo "$password"
        return 0
    else
        # Password not in keychain, prompt user
        read -s -p "Enter encryption password for '$environment' environment: " password
        echo
        
        # Offer to save in keychain
        read -p "Save password in keychain? (y/n) " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            security add-generic-password -a "$USER" -s "$keychain_entry" -w "$password"
            print_success "Password saved to keychain"
            echo "$password"
        else
            echo "$password"
        fi
    fi
}

# Get the encryption file path for a specific environment
get_env_file() {
    local environment="${1:-main}"
    
    if [ "$environment" = "main" ]; then
        echo "$MAIN_KEYS_FILE"
    else
        echo "$CREDENTIALS_DIR/api_keys_${environment}.enc"
    fi
}

# Function to encrypt credentials
encrypt_credentials() {
    local json_data="$1"
    local environment="${2:-main}"
    local enc_file=$(get_env_file "$environment")
    local temp_file="$CREDENTIALS_DIR/temp_keys_${environment}.json"
    local password
    
    # Get password
    password=$(get_password "$environment")
    
    # Write JSON to temp file
    echo "$json_data" > "$temp_file"
    
    # Encrypt the file
    echo "$password" | openssl enc -aes-256-cbc -salt -pbkdf2 -in "$temp_file" -out "$enc_file" -pass stdin
    
    # Remove temp file
    rm "$temp_file"
    
    print_success "Credentials for '$environment' environment encrypted and saved"
}

# Function to decrypt credentials
decrypt_credentials() {
    local environment="${1:-main}"
    local enc_file=$(get_env_file "$environment")
    
    if [ ! -f "$enc_file" ]; then
        echo "{}"
        return
    fi
    
    local password
    local decrypted
    
    # Get password
    password=$(get_password "$environment")
    
    # Decrypt the file
    decrypted=$(echo "$password" | openssl enc -aes-256-cbc -d -salt -pbkdf2 -in "$enc_file" -pass stdin 2>/dev/null)
    
    if [ $? -ne 0 ]; then
        print_error "Decryption failed for '$environment' environment. Wrong password?"
        echo "{}"
        return 1
    fi
    
    echo "$decrypted"
}

# Function to list all environments
list_environments() {
    print_header "Available Credential Environments"
    
    # Find all encrypted files
    local files=$(find "$CREDENTIALS_DIR" -name "api_keys*.enc" -type f)
    
    if [ -z "$files" ]; then
        print_info "No credential environments found"
        return
    fi
    
    # Extract environment names
    for file in $files; do
        local env_name=$(basename "$file" | sed -E 's/api_keys_?(.*)\.enc/\1/')
        if [ -z "$env_name" ]; then
            env_name="main"
        fi
        echo "- $env_name"
    done
}

# Function to list all stored API keys in an environment
list_keys() {
    local environment="${1:-main}"
    local credentials
    
    credentials=$(decrypt_credentials "$environment")
    
    if [ "$credentials" = "{}" ]; then
        print_info "No API keys stored in '$environment' environment"
        return
    fi
    
    print_header "API Keys in '$environment' Environment"
    
    # Parse JSON with jq and format output
    echo "$credentials" | jq -r 'to_entries | .[] | "\(.key): \(.value | if length > 20 then (.[:10] + "..." + .[-10:]) else . end)"'
}

# Function to add or update an API key
add_key() {
    local key_name="$1"
    local key_value="$2"
    local environment="${3:-main}"
    
    if [ -z "$key_name" ]; then
        read -p "Enter API key name (e.g. OPENAI_API_KEY): " key_name
    fi
    
    if [ -z "$key_value" ]; then
        read -s -p "Enter API key value: " key_value
        echo
    fi
    
    if [ -z "$key_name" ] || [ -z "$key_value" ]; then
        print_error "Both key name and value are required"
        return 1
    fi
    
    local credentials
    credentials=$(decrypt_credentials "$environment")
    
    # Update or add the key
    local updated_credentials
    updated_credentials=$(echo "$credentials" | jq --arg name "$key_name" --arg value "$key_value" '. + {($name): $value}')
    
    # Encrypt and save
    encrypt_credentials "$updated_credentials" "$environment"
    
    print_success "API key '$key_name' added/updated successfully in '$environment' environment"
}

# Function to get an API key
get_key() {
    local key_name="$1"
    local environment="${2:-main}"
    
    if [ -z "$key_name" ]; then
        read -p "Enter API key name to retrieve: " key_name
    fi
    
    if [ -z "$key_name" ]; then
        print_error "Key name is required"
        return 1
    fi
    
    local credentials
    credentials=$(decrypt_credentials "$environment")
    
    # Get the key value
    local key_value
    key_value=$(echo "$credentials" | jq -r --arg name "$key_name" '.[$name] // "Key not found"')
    
    if [ "$key_value" = "Key not found" ]; then
        print_error "Key '$key_name' not found in '$environment' environment"
        return 1
    fi
    
    print_info "Value for '$key_name' in '$environment' environment:"
    echo "$key_value"
}

# Function to remove an API key
remove_key() {
    local key_name="$1"
    local environment="${2:-main}"
    
    if [ -z "$key_name" ]; then
        read -p "Enter API key name to remove: " key_name
    fi
    
    if [ -z "$key_name" ]; then
        print_error "Key name is required"
        return 1
    fi
    
    local credentials
    credentials=$(decrypt_credentials "$environment")
    
    # Check if key exists
    local key_exists
    key_exists=$(echo "$credentials" | jq --arg name "$key_name" 'has($name)')
    
    if [ "$key_exists" != "true" ]; then
        print_error "Key '$key_name' not found in '$environment' environment"
        return 1
    fi
    
    # Remove the key
    local updated_credentials
    updated_credentials=$(echo "$credentials" | jq --arg name "$key_name" 'del(.[$name])')
    
    # Encrypt and save
    encrypt_credentials "$updated_credentials" "$environment"
    
    print_success "API key '$key_name' removed successfully from '$environment' environment"
}

# Function to load API keys into the environment
load_keys() {
    local filter="$1"
    local environment="${2:-main}"
    local credentials
    
    credentials=$(decrypt_credentials "$environment")
    
    # Check if we have any keys
    if [ "$credentials" = "{}" ]; then
        print_info "No API keys to load from '$environment' environment"
        return
    fi
    
    print_header "Loading API Keys from '$environment' Environment"
    
    # Extract keys and values and set them as environment variables
    if [ -z "$filter" ]; then
        # Load all keys
        local keys
        keys=$(echo "$credentials" | jq -r 'keys[]')
        
        for key in $keys; do
            local value
            value=$(echo "$credentials" | jq -r --arg name "$key" '.[$name]')
            export "$key"="$value"
            print_info "Loaded $key into environment"
        done
    else
        # Load only keys matching the filter
        local filtered_keys
        filtered_keys=$(echo "$credentials" | jq -r --arg filter "$filter" 'keys[] | select(. | contains($filter))')
        
        if [ -z "$filtered_keys" ]; then
            print_info "No keys matching '$filter' in '$environment' environment"
            return
        fi
        
        for key in $filtered_keys; do
            local value
            value=$(echo "$credentials" | jq -r --arg name "$key" '.[$name]')
            export "$key"="$value"
            print_info "Loaded $key into environment"
        done
    fi
}

# Function to create a template .env file
export_env() {
    local output_file="$1"
    local filter="$2"
    local environment="${3:-main}"
    
    if [ -z "$output_file" ]; then
        output_file=".env"
    fi
    
    if [ -f "$output_file" ]; then
        read -p "File $output_file already exists. Overwrite? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "Operation cancelled"
            return
        fi
    fi
    
    local credentials
    credentials=$(decrypt_credentials "$environment")
    
    # Check if we have any keys
    if [ "$credentials" = "{}" ]; then
        print_info "No API keys to export from '$environment' environment"
        return
    fi
    
    # Create .env file
    > "$output_file"
    
    if [ -z "$filter" ]; then
        # Export all keys
        local keys
        keys=$(echo "$credentials" | jq -r 'keys[]')
        
        for key in $keys; do
            local value
            value=$(echo "$credentials" | jq -r --arg name "$key" '.[$name]')
            echo "$key=$value" >> "$output_file"
        done
    else
        # Export only keys matching the filter
        local filtered_keys
        filtered_keys=$(echo "$credentials" | jq -r --arg filter "$filter" 'keys[] | select(. | contains($filter))')
        
        if [ -z "$filtered_keys" ]; then
            print_info "No keys matching '$filter' in '$environment' environment"
            rm "$output_file"
            return
        fi
        
        for key in $filtered_keys; do
            local value
            value=$(echo "$credentials" | jq -r --arg name "$key" '.[$name]')
            echo "$key=$value" >> "$output_file"
        done
    fi
    
    chmod 600 "$output_file"
    print_success "Created .env file at $output_file with keys from '$environment' environment"
}

# Function to create a new environment
create_environment() {
    local environment="$1"
    
    if [ -z "$environment" ]; then
        read -p "Enter new environment name: " environment
    fi
    
    if [ -z "$environment" ]; then
        print_error "Environment name is required"
        return 1
    fi
    
    if [ "$environment" = "main" ]; then
        print_error "Cannot create environment named 'main' (it already exists)"
        return 1
    fi
    
    local enc_file=$(get_env_file "$environment")
    
    if [ -f "$enc_file" ]; then
        print_error "Environment '$environment' already exists"
        return 1
    fi
    
    # Create empty environment
    encrypt_credentials "{}" "$environment"
    
    print_success "Created new environment '$environment'"
}

# Function to copy keys between environments
copy_keys() {
    local source_env="$1"
    local target_env="$2"
    local filter="$3"
    
    if [ -z "$source_env" ] || [ -z "$target_env" ]; then
        print_error "Both source and target environments are required"
        echo "Usage: copy_keys <source_env> <target_env> [filter]"
        return 1
    fi
    
    local source_credentials
    local target_credentials
    
    source_credentials=$(decrypt_credentials "$source_env")
    target_credentials=$(decrypt_credentials "$target_env")
    
    if [ "$source_credentials" = "{}" ]; then
        print_error "Source environment '$source_env' has no keys"
        return 1
    fi
    
    local updated_target
    
    if [ -z "$filter" ]; then
        # Copy all keys
        updated_target=$(echo "$source_credentials $target_credentials" | jq -s '.[0] + .[1]')
    else
        # Copy only keys matching the filter
        local filtered_keys
        filtered_keys=$(echo "$source_credentials" | jq -r --arg filter "$filter" 'keys[] | select(. | contains($filter))')
        
        if [ -z "$filtered_keys" ]; then
            print_error "No keys matching '$filter' in '$source_env' environment"
            return 1
        fi
        
        # Build a new object with just the filtered keys
        local filtered_obj="{}"
        
        for key in $filtered_keys; do
            local value
            value=$(echo "$source_credentials" | jq -r --arg name "$key" '.[$name]')
            filtered_obj=$(echo "$filtered_obj" | jq --arg name "$key" --arg value "$value" '. + {($name): $value}')
        done
        
        # Merge with target
        updated_target=$(echo "$filtered_obj $target_credentials" | jq -s '.[0] + .[1]')
    fi
    
    # Encrypt and save the target environment
    encrypt_credentials "$updated_target" "$target_env"
    
    print_success "Copied keys from '$source_env' to '$target_env' environment"
}

# Function to print usage information
print_usage() {
    echo "Enhanced API Credentials Manager"
    echo "Usage: credentials_manager.sh [command] [options]"
    echo ""
    echo "Commands:"
    echo "  environments                           List all credential environments"
    echo "  create_env <environment>               Create a new environment"
    echo "  list [environment]                     List all stored API keys in an environment"
    echo "  add <key> <value> [environment]        Add or update an API key"
    echo "  get <key> [environment]                Get the value of an API key"
    echo "  remove <key> [environment]             Remove an API key"
    echo "  load [filter] [environment]            Load API keys into the current shell"
    echo "  export <file> [filter] [environment]   Export keys to a .env file"
    echo "  copy <source_env> <target_env> [filter] Copy keys between environments"
    echo "  help                                   Show this help message"
    echo ""
    echo "Environment:"
    echo "  The default environment is 'main'. You can create and use multiple environments"
    echo "  for different projects or contexts."
    echo ""
    echo "Examples:"
    echo "  credentials_manager.sh add OPENAI_API_KEY sk-1234567890"
    echo "  credentials_manager.sh get OPENAI_API_KEY"
    echo "  credentials_manager.sh create_env ai-tools"
    echo "  credentials_manager.sh add OPENAI_API_KEY sk-1234567890 ai-tools"
    echo "  credentials_manager.sh load OPENAI ai-tools"
    echo "  credentials_manager.sh export .env.ai OPENAI ai-tools"
    echo "  credentials_manager.sh copy main ai-tools OPENAI"
}

# Main functionality based on first argument
case "$1" in
    environments|envs)
        list_environments
        ;;
    create_env)
        create_environment "$2"
        ;;
    list)
        list_keys "$2"
        ;;
    add)
        add_key "$2" "$3" "$4"
        ;;
    get)
        get_key "$2" "$3"
        ;;
    remove)
        remove_key "$2" "$3"
        ;;
    load)
        load_keys "$2" "$3"
        ;;
    export)
        export_env "$2" "$3" "$4"
        ;;
    copy)
        copy_keys "$2" "$3" "$4"
        ;;
    help)
        print_usage
        ;;
    *)
        print_usage
        ;;
esac
