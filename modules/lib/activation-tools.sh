#!/usr/bin/env bash

# Set default XDG_CONFIG_HOME if not set
if [ -z "${XDG_CONFIG_HOME+x}" ]; then
  export XDG_CONFIG_HOME="$HOME/.config"
fi

# Set up paths
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/usr/local/opt/cython/bin:/usr/sbin:$HOME/.krew/bin:$HOME/.local/bin:$HOME/.npm-global/bin:$HOME/.npm-global/bin/yarn:$HOME/.rvm/bin:$HOME/.yarn/bin:$HOME/bin:$HOME/go/bin:$XDG_CONFIG_HOME/.cargo/bin:$XDG_CONFIG_HOME/yarn/global/node_modules/.bin:$XDG_CONFIG_HOME/zsh/bin:$HOME/.uv/bin:$HOME/.yarn/global/node_modules/.bin:$HOME/.cargo/bin:/bin:/sbin:$PATH"

# Set up logging
LOG_DIR="/tmp/sysinit-logs"
LOG_PREFIX="sysinit"
mkdir -p "$LOG_DIR"

log_info() {
  echo -e "[\033[0;36m$(date '+%Y-%m-%d %H:%M:%S')\033[0m] [\033[0;34mINFO\033[0m] $1"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1" >> "$LOG_DIR/${LOG_PREFIX}.log"
}

log_debug() {
  echo -e "[\033[0;36m$(date '+%Y-%m-%d %H:%M:%S')\033[0m] [\033[0;35mDEBUG\033[0m] $1"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] $1" >> "$LOG_DIR/${LOG_PREFIX}.log"
}

log_error() {
  echo -e "[\033[0;36m$(date '+%Y-%m-%d %H:%M:%S')\033[0m] [\033[0;31mERROR\033[0m] $1"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1" >> "$LOG_DIR/${LOG_PREFIX}.log"
}

log_success() {
  echo -e "[\033[0;36m$(date '+%Y-%m-%d %H:%M:%S')\033[0m] [\033[0;32mSUCCESS\033[0m] $1"
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [SUCCESS] $1" >> "$LOG_DIR/${LOG_PREFIX}.log"
}

log_command() {
  local cmd="$1"
  local description="$2"
  log_info "Running: $description"
  
  # Execute the command and capture its output
  local output
  if output=$(eval "$cmd" 2>&1); then
    log_success "$description completed"
    [ -n "$output" ] && echo "$output"
    return 0
  else
    local exit_code=$?
    log_error "$description failed with exit code $exit_code"
    [ -n "$output" ] && echo "$output"
    return $exit_code
  fi
}

check_executable() {
  local executable="$1"
  if ! command -v "$executable" &> /dev/null; then
    log_error "$executable not found in PATH"
    return 1
  fi
  log_debug "Found $executable at $(command -v "$executable")"
  return 0
}

log_debug "Activation tools loaded"
log_debug "PATH: $PATH"
