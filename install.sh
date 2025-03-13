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

sources=(
    "$PWD/ghostty/config"
    "$PWD/starship/starship.toml"
    "$PWD/k9s"
    "$PWD/nvim"
    "$PWD/atuin"
    "$PWD/macchina"
    "$PWD/zellij"
    "$PWD/utils"
    "$PWD/zsh/.zshrc"
    "$PWD/zsh/conf.d"
    "$PWD/git/.gitconfig"
)

destinations=(
    "$HOME/.config/ghostty/config"
    "$HOME/.config/starship.toml"
    "$HOME/.config/k9s"
    "$HOME/.config/nvim"
    "$HOME/.config/atuin"
    "$HOME/.config/macchina"
    "$HOME/.config/zellij"
    "$HOME/.config/utils"
    "$HOME/.zshrc"
    "$HOME/.config/zsh/conf.d"
    "$HOME/.gitconfig"
)

create_symlink() {
    local src=$1
    local dest=$2
    
    # Create parent directory if it doesn't exist
    mkdir -p "$(dirname "$dest")"
    
    # Check if destination already exists
    if [ -L "$dest" ]; then
        local current_target=$(readlink "$dest")
        if [ "$current_target" = "$src" ]; then
            log_info "Symlink already exists and points to correct location: $dest"
            return 0
        else
            log_warn "Symlink exists but points to different location: $dest -> $current_target"
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
        rm -rf "$dest"
    fi
    
    # Create symlink
    ln -s "$src" "$dest"
    if [ $? -eq 0 ]; then
        log_info "Created symlink: $dest -> $src"
    else
        log_error "Failed to create symlink for $dest"
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
}

main() {
    log_step "Starting sysinit configuration installation..."
    
    install_dependencies
    
    local len=${#sources[@]}
    for (( i=0; i<$len; i++ )); do
        create_symlink "${sources[$i]}" "${destinations[$i]}"
    done
    
    log_step "Installation complete! 🎉"
    log_info "Remember to restart your terminal for changes to take effect"
}

main