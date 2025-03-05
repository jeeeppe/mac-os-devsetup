#!/bin/bash

# Shell setup script
# Configures zsh and related plugins manually

# Set script directory and load helpers
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/utils/helpers.sh"

print_header "Setting Up Shell Environment"

# Make sure Homebrew is initialized for this session
if [[ $(uname -m) == "arm64" ]]; then
    # M1/M2 Mac
    eval "$(/opt/homebrew/bin/brew shellenv)"
else
    # Intel Mac
    eval "$(/usr/local/bin/brew shellenv)"
fi

# Check if zsh is the default shell
if [[ "$SHELL" != *"zsh"* ]]; then
    print_info "Setting zsh as the default shell..."
    chsh -s "$(which zsh)"
    print_success "zsh set as the default shell. You may need to restart your terminal."
else
    print_info "zsh is already the default shell"
fi

# Create XDG standard directories
print_info "Creating XDG standard directories..."
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

ensure_dir_exists "$XDG_CONFIG_HOME/zsh"
ensure_dir_exists "$XDG_CACHE_HOME/zsh"
ensure_dir_exists "$XDG_DATA_HOME/zsh"
ensure_dir_exists "$XDG_STATE_HOME/zsh"

# Create shell configuration files if they don't exist
print_info "Creating shell configuration files..."

# Make sure all the required subdirectories exist in the repository
ensure_dir_exists "$SCRIPT_DIR/configs/shell/zsh"

# Install shell configuration files using the configuration manager
print_info "Installing shell configuration files..."
"$SCRIPT_DIR/utils/config_manager.sh" install shell

# Install zsh plugins
print_info "Installing zsh plugins..."
brew_install "zsh-syntax-highlighting" || true
brew_install "zsh-autosuggestions" || true
brew_install "zsh-completions" || true

# Create Terminal.app profile (if needed)
if [ ! -f "$SCRIPT_DIR/configs/apps/terminal_profile.terminal" ]; then
    print_info "Creating Terminal.app profile..."
    mkdir -p "$SCRIPT_DIR/configs/apps"
    
    cat > "$SCRIPT_DIR/configs/apps/terminal_profile.terminal" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
	<key>Font</key>
	<data>
	YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMS
	AAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGkCwwVFlUkbnVsbNQNDg8QERIT
	FFZOU1NpemVYTlNmRmxhZ3NWTlNOYW1lViRjbGFzcyNALAAAAAAAABAQgAKAA18QE0pl
	dEJyYWluc01vbm8tUmVndWxhctIXGBkaWiRjbGFzc25hbWVYJGNsYXNzZXNWTlNGb250
	ohkbWE5TT2JqZWN0CBEaJCkyN0lMUVNYXmdud36FjpCSlKOos7zDxgAAAAAAAAEBAAAA
	AAAAABwAAAAAAAAAAAAAAAAAAADP
	</data>
	<key>FontAntialias</key>
	<true/>
	<key>FontWidthSpacing</key>
	<real>1.004032258064516</real>
	<key>ProfileCurrentVersion</key>
	<real>2.0699999999999998</real>
	<key>BackgroundColor</key>
	<data>
	YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMS
	AAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGjCwwTVSRudWxs0w0ODxAREldO
	U1doaXRlXE5TQ29sb3JTcGFjZVYkY2xhc3NNMCAwLjg1MDAwMDAyABADgALSFBUWF1ok
	Y2xhc3NuYW1lWCRjbGFzc2VzV05TQ29sb3KiFhhYTlNPYmplY3QIERokKTI3SUxRU1dd
	ZGx5gI6Qkpeiq7O2AAAAAAAAAQEAAAAAAAAAGQAAAAAAAAAAAAAAAAAAAL8=
	</data>
	<key>CursorColor</key>
	<data>
	YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMS
	AAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGjCwwTVSRudWxs0w0ODxAREldO
	U1doaXRlXE5TQ29sb3JTcGFjZVYkY2xhc3NLMC4zMDI0MTkzNgAQA4AC0hQVFhdaJGNs
	YXNzbmFtZVgkY2xhc3Nlc1dOU0NvbG9yohYYWE5TT2JqZWN0CBEaJCkyN0lMUVNXXWRs
	eYCMjpCVoKmxtAAAAAAAAAEBAAAAAAAAABkAAAAAAAAAAAAAAAAAAAC9
	</data>
	<key>TextBoldColor</key>
	<data>
	YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMS
	AAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGjCwwTVSRudWxs0w0ODxAREldO
	U1doaXRlXE5TQ29sb3JTcGFjZVYkY2xhc3NCMQAQA4AC0hQVFhdaJGNsYXNzbmFtZVgk
	Y2xhc3Nlc1dOU0NvbG9yohYYWE5TT2JqZWN0CBEaJCkyN0lMUVNXXWRseYCDhYeMl5uf
	qAAAAAAAAAAAAQEAAAAAAAAAGQAAAAAAAAAAAAAAAAAAALI=
	</data>
	<key>TextColor</key>
	<data>
	YnBsaXN0MDDUAQIDBAUGBwpYJHZlcnNpb25ZJGFyY2hpdmVyVCR0b3BYJG9iamVjdHMS
	AAGGoF8QD05TS2V5ZWRBcmNoaXZlctEICVRyb290gAGjCwwTVSRudWxs0w0ODxAREldO
	U1doaXRlXE5TQ29sb3JTcGFjZVYkY2xhc3NLMCAwLjg1MDAwMDAyABADgALSFBUWF1ok
	Y2xhc3NuYW1lWCRjbGFzc2VzV05TQ29sb3KiFhhYTlNPYmplY3QIERokKTI3SUxRU1dd
	ZGx5gI6Qkpeiq7O2AAAAAAAAAQEAAAAAAAAAGQAAAAAAAAAAAAAAAAAAAL8=
	</data>
	<key>columnCount</key>
	<integer>100</integer>
	<key>name</key>
	<string>DevSetup</string>
	<key>rowCount</key>
	<integer>30</integer>
	<key>type</key>
	<string>Window Settings</string>
	<key>useOptionAsMetaKey</key>
	<true/>
</dict>
</plist>
EOL
fi

# Apply Terminal profile
print_info "Setting up Terminal.app profile..."
open "$SCRIPT_DIR/configs/apps/terminal_profile.terminal"
sleep 1
defaults write com.apple.Terminal "Default Window Settings" -string "DevSetup"
defaults write com.apple.Terminal "Startup Window Settings" -string "DevSetup"

print_success "Shell environment setup completed successfully"
print_info "Please restart your terminal or run 'source ~/.zshrc' to apply changes"
exit 0
