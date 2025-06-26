#!/usr/bin/env bash
# shellcheck disable=all

COLOR_RESET="\033[0m"
COLOR_BLACK="\033[0;30m"
COLOR_RED="\033[0;31m"
COLOR_GREEN="\033[0;32m"
COLOR_YELLOW="\033[0;33m"
COLOR_BLUE="\033[0;34m"
COLOR_MAGENTA="\033[0;35m"
COLOR_CYAN="\033[0;36m"
COLOR_WHITE="\033[0;37m"
COLOR_BRIGHT_BLACK="\033[0;90m"
COLOR_BRIGHT_RED="\033[0;91m"
COLOR_BRIGHT_GREEN="\033[0;92m"
COLOR_BRIGHT_YELLOW="\033[0;93m"
COLOR_BRIGHT_BLUE="\033[0;94m"
COLOR_BRIGHT_MAGENTA="\033[0;95m"
COLOR_BRIGHT_CYAN="\033[0;96m"
COLOR_BRIGHT_WHITE="\033[0;97m"

STYLE_BOLD="\033[1m"
STYLE_DIM="\033[2m"
STYLE_ITALIC="\033[3m"
STYLE_UNDERLINE="\033[4m"

COLOR_DEBUG="${COLOR_BRIGHT_BLACK}"
COLOR_INFO="${COLOR_BRIGHT_BLUE}"
COLOR_SUCCESS="${COLOR_BRIGHT_GREEN}"
COLOR_WARN="${COLOR_BRIGHT_YELLOW}"
COLOR_ERROR="${COLOR_BRIGHT_RED}"
COLOR_CRITICAL="${STYLE_BOLD}${COLOR_BRIGHT_RED}"

LOG_LEVEL_DEBUG=0
LOG_LEVEL_INFO=1
LOG_LEVEL_SUCCESS=2
LOG_LEVEL_WARN=3
LOG_LEVEL_ERROR=4
LOG_LEVEL_CRITICAL=5

: ${LOG_LEVEL:=$LOG_LEVEL_INFO}

_log_timestamp() {
  date "+%Y-%m-%d %H:%M:%S"
}

_log_format_kv() {
  local key="$1"
  local value="$2"
  echo "${STYLE_BOLD}${key}${COLOR_RESET}=${value}"
}

_log() {
  local level="$1"
  local level_name="$2"
  local color="$3"
  local message="$4"
  shift 4

  if [ "$level" -lt "$LOG_LEVEL" ]; then
    return
  fi

  local timestamp="$(_log_timestamp)"

  local log_line="${STYLE_DIM}${timestamp}${COLOR_RESET} ${color}${level_name}${COLOR_RESET}"

  log_line="${log_line} ${message}"

  while [ "$#" -gt 0 ]; do
    if [[ "$1" == *"="* ]]; then
      local key="${1%%=*}"
      local value="${1#*=}"
      log_line="${log_line} $(_log_format_kv "$key" "$value")"
    fi
    shift
  done

  echo -e "$log_line"
}

log_debug() {
  _log $LOG_LEVEL_DEBUG "DEBUG" "$COLOR_DEBUG" "$@"
}

log_info() {
  _log $LOG_LEVEL_INFO "INFO " "$COLOR_INFO" "$@"
}

log_success() {
  _log $LOG_LEVEL_SUCCESS "OK   " "$COLOR_SUCCESS" "$@"
}

log_warn() {
  _log $LOG_LEVEL_WARN "WARN " "$COLOR_WARN" "$@"
}

log_error() {
  _log $LOG_LEVEL_ERROR "ERROR" "$COLOR_ERROR" "$@"
}

log_critical() {
  _log $LOG_LEVEL_CRITICAL "CRIT " "$COLOR_CRITICAL" "$@"
}

set_log_level() {
  case "${1^^}" in
    "DEBUG") LOG_LEVEL=$LOG_LEVEL_DEBUG ;;
    "INFO") LOG_LEVEL=$LOG_LEVEL_INFO ;;
    "SUCCESS") LOG_LEVEL=$LOG_LEVEL_SUCCESS ;;
    "WARN") LOG_LEVEL=$LOG_LEVEL_WARN ;;
    "ERROR") LOG_LEVEL=$LOG_LEVEL_ERROR ;;
    "CRITICAL") LOG_LEVEL=$LOG_LEVEL_CRITICAL ;;
    *)
      echo "Invalid log level: $1"
      echo "Valid levels: DEBUG, INFO, SUCCESS, WARN, ERROR, CRITICAL"
      return 1
      ;;
  esac
  return 0
}

