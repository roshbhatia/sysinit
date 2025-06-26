#!/usr/bin/env bash
# shellcheck disable=all

# Simple logging library for shell scripts.
# Usage: log_info "message", log_warn "message", log_error "message"

log_timestamp() {
  date '+%Y-%m-%d %H:%M:%S'
}

log_debug() {
  echo "$(log_timestamp) [DEBUG] $*"
}

log_info() {
  echo "$(log_timestamp) [INFO ] $*"
}

log_warn() {
  echo "$(log_timestamp) [WARN ] $*" >&2
}

log_error() {
  echo "$(log_timestamp) [ERROR] $*" >&2
}

