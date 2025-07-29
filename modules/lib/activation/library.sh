#!/usr/bin/env bash
# shellcheck disable=all

COLOR_RESET="\033[0m"
COLOR_BRIGHT_BLACK="\033[0;90m"
COLOR_BRIGHT_BLUE="\033[0;94m"
COLOR_BRIGHT_GREEN="\033[0;92m"
COLOR_BRIGHT_RED="\033[0;91m"
STYLE_DIM="\033[2m"

LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_SUCCESS=2
LOG_LEVEL_ERROR=4

: ${LOG_LEVEL:=$LOG_LEVEL_INFO}

_log_timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

_log() {
  local level="$1"
  local level_name="$2"
  local color="$3"
  local message="$4"

  if [ "$level" -lt "$LOG_LEVEL" ]; then
    return
  fi

  local timestamp="$(_log_timestamp)"
  local log_line="${STYLE_DIM}${timestamp}${COLOR_RESET} ${color}${level_name}${COLOR_RESET} ${message}"

  echo -e "$log_line"
}

if [ -z "${XDG_CONFIG_HOME+x}" ]; then
  export XDG_CONFIG_HOME="$HOME/.config"
fi

if [ -z "${XDG_DATA_HOME+x}" ]; then
  export XDG_DATA_HOME="$HOME/.local/share"
fi

export PATH="/usr/bin:/usr/sbin:/bin:/sbin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$XDG_CONFIG_HOME/.cargo/bin:$PATH"
export PATH="$HOME/go/bin:$PATH"
export PATH="$HOME/.npm-global/bin:$PATH"
export PATH="$HOME/.npm-global/bin/yarn:$PATH"
export PATH="$HOME/.yarn/bin:$PATH"
export PATH="$HOME/.yarn/global/node_modules/.bin:$PATH"
export PATH="$XDG_CONFIG_HOME/yarn/global/node_modules/.bin:$PATH"
export PATH="/usr/local/opt/cython/bin:$PATH"
export PATH="$HOME/.uv/bin:$PATH"
export PATH="$HOME/.rvm/bin:$PATH"
export PATH="$HOME/.krew/bin:$PATH"
export PATH="$XDG_CONFIG_HOME/zsh/bin:$PATH"
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
export PATH="/etc/profiles/per-user/$USER/bin:$PATH"
export PATH="$XDG_DATA_HOME/.npm-packages/bin:$PATH"

log_info() {
  _log $LOG_LEVEL_INFO "INFO " "$COLOR_BRIGHT_BLUE" "$1"
}

log_debug() {
  _log $LOG_LEVEL_DEBUG "DEBUG" "$COLOR_BRIGHT_BLACK" "$1"
}

log_error() {
  _log $LOG_LEVEL_ERROR "ERROR" "$COLOR_BRIGHT_RED" "$1"
}

log_success() {
  _log $LOG_LEVEL_SUCCESS "OK   " "$COLOR_BRIGHT_GREEN" "$1"
}

log_command() {
  local cmd="$1"
  local description="$2"
  log_info "Running: $description"

  local output
  if output=$(eval "$cmd" 2>&1); then
    log_success "$description completed"
    [ -n "$output" ] && echo -e "$output"
    return 0
  else
    local exit_code=$?
    log_error "$description failed with exit code $exit_code"
    [ -n "$output" ] && echo -e "$output"
    return $exit_code
  fi
}

check_executable() {
  local executable="$1"
  if ! command -v "$executable" &>/dev/null; then
    log_error "$executable not found in PATH"
    return 1
  fi
  log_debug "Found $executable at $(command -v "$executable")"
  return 0
}

