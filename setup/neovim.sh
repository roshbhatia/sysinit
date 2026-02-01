#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/roshbhatia/sysinit.git"
NVIM_RELEASES_BASE="https://github.com/neovim/neovim/releases"
INSTALL_DIR_LINUX="/opt/nvim"
INSTALL_DIR_MACOS="/usr/local/nvim"

INSTALL_NVIM=true
INSTALL_CONFIG=true

log() { echo "$*"; }
err() {
  echo "$*" >&2
  exit 1
}
maybe_sudo() {
  if [ "$(id -u)" -eq 0 ]; then
    "$@"
  else
    sudo "$@"
  fi
}

usage() {
  cat << EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --nvim-only     Install Neovim only
  --config-only   Install configuration only
  -h, --help      Show this help message

If no options are provided, both Neovim and configuration will be installed.
EOF
  exit 0
}

parse_args() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      --nvim-only)
        INSTALL_CONFIG=false
        shift
        ;;
      --config-only)
        INSTALL_NVIM=false
        shift
        ;;
      -h | --help)
        usage
        ;;
      *)
        err "Unknown option: $1"
        ;;
    esac
  done
}

detect_platform() {
  case "$(uname -s)" in
    Darwin*) OS="macos" ;;
    Linux*) OS="linux" ;;
    *) err "Unsupported OS: $(uname -s)" ;;
  esac

  case "$(uname -m)" in
    x86_64) ARCH="x86_64" ;;
    arm64 | aarch64) ARCH="arm64" ;;
    *) err "Unsupported architecture: $(uname -m)" ;;
  esac

  log "Platform: $OS ($ARCH)"
}

check_prerequisites() {
  local missing=()
  for cmd in git curl tar; do
    command -v "$cmd" &> /dev/null || missing+=("$cmd")
  done

  if [ ${#missing[@]} -gt 0 ]; then
    err "Missing required commands: ${missing[*]}"
  fi
}

nvim_exists() {
  if [ "$OS" = "macos" ]; then
    [ -d "$INSTALL_DIR_MACOS" ]
  else
    [ -d "$INSTALL_DIR_LINUX" ] || [ -d "${INSTALL_DIR_LINUX}-linux-x86_64" ]
  fi
}

install_neovim() {
  if nvim_exists; then
    log "Neovim already installed, skipping"
    return
  fi

  log "Installing Neovim for $OS ($ARCH)"

  case "$OS" in
    macos) install_neovim_macos ;;
    linux) install_neovim_linux ;;
  esac

  log "Neovim installed"
}

install_neovim_macos() {
  local archive="nvim-macos-${ARCH}.tar.gz"
  local url="${NVIM_RELEASES_BASE}/download/nightly/${archive}"
  local temp_dir="/tmp/nvim-install-$$"

  mkdir -p "$temp_dir"
  cd "$temp_dir"

  log "Downloading $archive"
  curl -LO "$url"

  log "Extracting"
  tar xzf "$archive"

  log "Installing to $INSTALL_DIR_MACOS"
  maybe_sudo rm -rf "$INSTALL_DIR_MACOS"
  maybe_sudo mv "nvim-macos-${ARCH}" "$INSTALL_DIR_MACOS"

  add_to_path "$INSTALL_DIR_MACOS/bin"
  cd - > /dev/null
  rm -rf "$temp_dir"
}

install_neovim_linux() {
  if command -v pacman &> /dev/null && pacman -Ss neovim-nightly-bin &> /dev/null; then
    log "Installing via pacman"
    maybe_sudo pacman -S --noconfirm neovim-nightly-bin || install_neovim_linux_tarball
    return
  fi

  install_neovim_linux_tarball
}

install_neovim_linux_tarball() {
  if [ "$ARCH" = "x86_64" ]; then
    local archive="nvim-linux-x86_64.tar.gz"
    local url="${NVIM_RELEASES_BASE}/latest/download/${archive}"
    local install_dir="${INSTALL_DIR_LINUX}-linux-x86_64"
    local temp_dir="/tmp/nvim-install-$$"

    mkdir -p "$temp_dir"
    cd "$temp_dir"

    log "Downloading $archive"
    curl -LO "$url"

    log "Extracting"
    tar xzf "$archive"

    log "Installing to $install_dir"
    maybe_sudo rm -rf "$install_dir"
    maybe_sudo mkdir -p /opt
    maybe_sudo mv nvim-linux-x86_64 "$install_dir"

    add_to_path "$install_dir/bin"
    cd - > /dev/null
    rm -rf "$temp_dir"
  else
    install_neovim_linux_appimage
  fi
}

install_neovim_linux_appimage() {
  local appimage="nvim-linux-${ARCH}.appimage"
  local url="${NVIM_RELEASES_BASE}/latest/download/${appimage}"
  local temp_dir="/tmp/nvim-install-$$"

  mkdir -p "$temp_dir"
  cd "$temp_dir"

  log "Downloading $appimage"
  curl -LO "$url"

  chmod u+x "$appimage"

  log "Extracting AppImage"
  ./"$appimage" --appimage-extract > /dev/null 2>&1

  log "Installing to $INSTALL_DIR_LINUX"
  maybe_sudo rm -rf "$INSTALL_DIR_LINUX"
  maybe_sudo mkdir -p "$(dirname "$INSTALL_DIR_LINUX")"
  maybe_sudo mv squashfs-root "$INSTALL_DIR_LINUX"

  add_to_path "$INSTALL_DIR_LINUX/usr/bin"
  cd - > /dev/null
  rm -rf "$temp_dir"
}

add_to_path() {
  local path_to_add="$1"
  local shell_configs=()

  [ -f "$HOME/.bashrc" ] && shell_configs+=("$HOME/.bashrc")
  [ -f "$HOME/.zshrc" ] && shell_configs+=("$HOME/.zshrc")
  [ -f "$HOME/.config/fish/config.fish" ] && shell_configs+=("$HOME/.config/fish/config.fish")

  if [ ${#shell_configs[@]} -eq 0 ]; then
    log "Add to your shell config: export PATH=\"\$PATH:$path_to_add\""
    return
  fi

  for config in "${shell_configs[@]}"; do
    if ! grep -q "$path_to_add" "$config" 2> /dev/null; then
      log "Adding to PATH in $config"
      echo "" >> "$config"
      echo "export PATH=\"\$PATH:$path_to_add\"" >> "$config"
    fi
  done

  log "Restart shell or run: export PATH=\"\$PATH:$path_to_add\""
}

install_config() {
  local nvim_config="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
  local temp_repo="/tmp/sysinit-$$"

  log "Installing config to $nvim_config"

  log "Cloning repository"
  git clone --depth 1 "$REPO_URL" "$temp_repo"

  if [ -d "$nvim_config" ]; then
    log "Removing existing config"
    rm -rf "$nvim_config"
  fi

  log "Copying config"
  mkdir -p "$(dirname "$nvim_config")"
  cp -r "$temp_repo/modules/home/configurations/neovim" "$nvim_config"

  rm -rf "$temp_repo"

  log "Config installed"
}

main() {
  parse_args "$@"

  check_prerequisites
  detect_platform

  if $INSTALL_NVIM; then
    install_neovim
  fi

  if $INSTALL_CONFIG; then
    install_config
  fi

  log "Done"
}

main "$@"
