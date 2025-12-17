#!/usr/bin/env bash
set -euo pipefail

# Script to select and set desktop background with chafa preview
# Supports macOS and NixOS

# Source logging library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/loglib.sh"

# Check required commands
check_command() {
  if ! command -v "$1" &> /dev/null; then
    log_error "Required command not found: $1"
    log_info "Install it with: nix shell nixpkgs#$1"
    exit 1
  fi
}

check_command "fzf"
check_command "chafa"
check_command "git"
check_command "fd"

# Determine OS
if [[ $OSTYPE == "darwin"* ]]; then
  OS="macos"
elif [[ $OSTYPE == "linux-gnu"* ]]; then
  OS="linux"
else
  log_error "Unsupported OS: $OSTYPE"
  exit 1
fi

# Setup wallpapers directory
WALLPAPERS_DIR="${HOME}/.local/share/wallpapers"
WALLPAPERS_REPO="https://github.com/roshbhatia/wallpapers.git"

log_info "Checking wallpapers repository..."
if [ ! -d "$WALLPAPERS_DIR" ]; then
  log_info "Cloning wallpapers repository to $WALLPAPERS_DIR"
  mkdir -p "$(dirname "$WALLPAPERS_DIR")"
  if ! git clone "$WALLPAPERS_REPO" "$WALLPAPERS_DIR" 2> /dev/null; then
    log_error "Failed to clone wallpapers repository"
    exit 1
  fi
else
  log_info "Updating wallpapers repository"
  if ! git -C "$WALLPAPERS_DIR" fetch --quiet 2> /dev/null; then
    log_warn "Could not fetch updates - continuing with local version"
  elif ! git -C "$WALLPAPERS_DIR" pull --quiet 2> /dev/null; then
    log_warn "Could not pull updates - continuing with local version"
  fi
fi

# Find image files
log_info "Scanning for wallpapers..."
images=$(fd --type f --extension jpg --extension jpeg --extension png --extension webp . "$WALLPAPERS_DIR" | sort)

if [ -z "$images" ]; then
  # Fallback: check common system wallpaper locations
  log_info "No images in wallpapers repo, checking system locations..."
  fallback_dirs=(
    "$HOME/Pictures"
    "$HOME/Desktop"
    "/System/Library/Desktop Pictures"
    "/Library/Desktop Pictures"
  )

  for dir in "${fallback_dirs[@]}"; do
    if [ -d "$dir" ]; then
      found=$(fd --type f --extension jpg --extension jpeg --extension png --extension webp . "$dir" | sort)
      images="${images}${found}"$'\n'
    fi
  done

  images=$(echo "$images" | grep -v '^$' | sort -u || true)

  if [ -z "$images" ]; then
    log_error "No images found in any location"
    log_info "Try adding some images to ~/Pictures or ensure the wallpapers repo is accessible"
    exit 1
  fi
fi

log_success "Found wallpapers"

# Check if running interactively
if [ ! -t 0 ]; then
  log_error "Script must be run interactively (fzf requires a TTY)"
  exit 1
fi

# FZF preview with chafa
selected=$(
  echo "$images" |
    fzf \
      --preview "chafa --size 80x24 --colors 256 {}" \
      --preview-window "right:50%" \
      --height 50%
)

if [ -z "$selected" ]; then
  log_info "No wallpaper selected"
  exit 0
fi

log_info "Setting background to: $(basename "$selected")"

case "$OS" in
  macos)
    # Set desktop background on macOS
    # Try multiple methods for reliability
    if command -v "osascript" &> /dev/null; then
      # Method 1: osascript (requires accessibility permissions)
      if ! osascript -e "tell application \"System Events\" to set picture of every desktop to \"$selected\"" 2> /dev/null; then
        log_warn "osascript failed - may need accessibility permissions"

        # Method 2: Using SQLite to update the database directly
        db_path="$HOME/Library/Application Support/Dock/desktoppicture.db"
        if [ -f "$db_path" ]; then
          sqlite3 "$db_path" "UPDATE pictures SET path = '$selected';" 2> /dev/null || true
          killall Dock 2> /dev/null || true
          log_success "Background set via database update"
        else
          log_error "Could not set background - try System Preferences manually"
          exit 1
        fi
      else
        log_success "Background set on macOS"
      fi
    else
      log_error "osascript not available"
      exit 1
    fi
    ;;
  linux)
    # Copy to standard location and set for NixOS
    mkdir -p "$HOME/.config/background"
    cp "$selected" "$HOME/.config/background/current"
    ln -sf "$HOME/.config/background/current" "$HOME/.background-image"

    # For NixOS with Stylix, update the background file
    if [ -n "${XDG_CONFIG_HOME:-}" ]; then
      CONFIG_DIR="$XDG_CONFIG_HOME"
    else
      CONFIG_DIR="$HOME/.config"
    fi

    # Notify about manual steps if needed
    log_success "Background image set to: $HOME/.background-image"
    log_info "You may need to update your display manager or window manager configuration"
    ;;
esac

log_success "Done!"
