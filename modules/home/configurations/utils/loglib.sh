#!/usr/bin/env bash

# loglib.sh - Simple logging helpers for shell scripts
# Usage: source this file in your scripts and use log_info, log_warn, log_error, log_success

log_info() {
  echo "[INFO] $*"
}

log_warn() {
  echo "[WARN] $*" >&2
}

log_error() {
  echo "[ERROR] $*" >&2
}

log_success() {
  echo "[SUCCESS] $*"
}

