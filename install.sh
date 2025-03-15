#!/bin/bash
# shellcheck disable=all

# Colors for fancy logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color
BOLD='\033[1m'

# Logging functions
log_info() {
    printf "${BOLD}${GREEN}[INFO]${NC} $1\n"
}

log_warn() {
    printf "${BOLD}${YELLOW}[WARN]${NC} $1\n"
}

log_error() {
    printf "${BOLD}${RED}[ERROR]${NC} $1\n"
}

log_step() {
    printf "${BOLD}${BLUE}[STEP]${NC} $1\n"
}

# Define arrays for links and copies
link_sources=(
    "$PWD/starship"
    "$PWD/k9s"
    "$PWD/nvim"
    "$PWD/atuin"
    "$PWD/macchina"
    "$PWD/zellij"
    "$PWD/zsh/.zshrc"
    "$PWD/zsh/.zshutils"
    "$PWD/zsh/conf.d"
    "$PWD/git/.gitconfig"
    "$PWD/git/.gitconfig.personal"
    "$PWD/rio"
)

link_destinations=(
    "$HOME/.config/starship"
    "$HOME/.config/k9s"
    "$HOME/.config/nvim"
    "$HOME/.config/atuin"
    "$HOME/.config/macchina"
    "$HOME/.config/zellij"
    "$HOME/.zshrc"
    "$HOME/.zshutils"
    "$HOME/.config/zsh/conf.d"
    "$HOME/.gitconfig"
    "$HOME/.gitconfig.personal"
    "$HOME/.config/rio"
)

copy_sources=(
)

copy_destinations=(
)

create_symlink() {
    local src=$1
    local dest=$2
    
    # Helper function to get relative path using Python
    get_relative_path() {
        python3 -c "import os.path; print(os.path.relpath('$1', os.path.dirname('$2')))"
    }
    
    # Get absolute path of source
    src=$(python3 -c "import os.path; print(os.path.abspath('$src'))")
    
    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"
    
    # Check if destination is a symlink
    if [ -L "$dest" ]; then
        local current_target=$(readlink "$dest")
        local desired_target=$(get_relative_path "$src" "$dest")
        
        if [ "$current_target" = "$desired_target" ]; then
            log_info "Symlink already exists and points to correct location: $dest"
            return 0
        else
            log_warn "Symlink exists but points to different location: $dest -> $current_target"
            if [ -f "$dest" ] && [ ! -L "$dest" ]; then
                local backup="${dest}.backup.$(date +%Y%m%d_%H%M%S)"
                log_info "Creating backup: $backup"
                cp -L "$dest" "$backup"
            fi
        fi
    elif [ -e "$dest" ]; then
        log_warn "File/directory already exists: $dest"
    fi
    
    # Prompt for overwrite
    if [ -e "$dest" ] || [ -L "$dest" ]; then
        read -p "Do you want to overwrite? (y/n) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            log_info "Skipping $dest"
            return 0
        fi
        # Remove the symlink or file
        rm -f "$dest"
    fi
    
    # Create symlink using relative path
    local relative_src=$(get_relative_path "$src" "$dest")
    ln -s "$relative_src" "$dest"
    if [ $? -eq 0 ]; then
        log_info "Created symlink: $dest -> $relative_src"
    else
        log_error "Failed to create symlink for $dest"
    fi
}

# Add a new function for copying files
copy_file() {
    local src=$1
    local dest=$2
    
    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"

    cp -f "$src" "$dest"
    if [ $? -eq 0 ]; then
        log_info "Copied file: $src -> $dest"
    else
        log_warn "Failed to copy file from $src to $dest"
    fi
}

install_dependencies() {
    log_step "Installing required dependencies..."
    
    # Install Homebrew packages
    brew install \
        zsh-syntax-highlighting \
        zsh-autosuggestions \
        kubectl \
        stern \
        gh \
        fzf \
        goenv \
        direnv \
        starship
    
    # Create plugin directories
    mkdir -p "$HOME/.config/zsh/plugins"
    
    # Install evalcache if not exists
    if [ ! -d "$HOME/.config/zsh/plugins/evalcache" ]; then
        git clone https://github.com/mroth/evalcache "$HOME/.config/zsh/plugins/evalcache"
    fi
    
    # Install fzf-tab if not exists
    if [ ! -d "$HOME/.config/zsh/plugins/fzf-tab" ]; then
        git clone https://github.com/Aloxaf/fzf-tab "$HOME/.config/zsh/plugins/fzf-tab"
    fi

    # Create directory for Zellij plugins
    mkdir -p "$HOME/.config/zellij/bin"

    # Download latest zjstatus.wasm
    curl -L "https://github.com/dj95/zjstatus/releases/latest/download/zjstatus.wasm" \
        -o "$HOME/.config/zellij/bin/zjstatus.wasm"

    # Download latest zjframes.wasm
    curl -L "https://github.com/dj95/zjstatus/releases/latest/download/zjframes.wasm" \
        -o "$HOME/.config/zellij/bin/zjframes.wasm"

    # Make plugins executable
    chmod +x "$HOME/.config/zellij/bin/zjstatus.wasm"
    chmod +x "$HOME/.config/zellij/bin/zjframes.wasm"
}

# Modify main() to handle both operations
main() {
    log_step "Starting sysinit configuration installation..."
    
    install_dependencies
    
    # Handle symlinks
    local link_len=${#link_sources[@]}
    for (( i=0; i<$link_len; i++ )); do
        create_symlink "${link_sources[$i]}" "${link_destinations[$i]}"
    done
    
    # Handle copies
    local copy_len=${#copy_sources[@]}
    for (( i=0; i<$copy_len; i++ )); do
        copy_file "${copy_sources[$i]}" "${copy_destinations[$i]}"
    done
    
    log_step "Installation complete! 🎉"
}

main