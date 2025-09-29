#!/usr/bin/env bash
set -euo pipefail

log_info() { echo -e "\033[0;34m[INFO]\033[0m $*"; }
log_warn() { echo -e "\033[1;33m[WARN]\033[0m $*" >&2; }
log_error() { echo -e "\033[1;31m[ERROR]\033[0m $*" >&2; }
log_success() { echo -e "\033[0;32m[SUCCESS]\033[0m $*"; }

log_info "Setting up git hooks..."

git config core.hooksPath .githooks
log_info "Configured git to use .githooks directory"

chmod +x .githooks/*
log_info "Made hooks executable"

git config core.autocrlf false
git config core.eol lf
log_info "Set git line ending configuration"

log_success "Git hooks and configuration set up successfully!"
log_info "Hooks will now run automatically on git operations."
