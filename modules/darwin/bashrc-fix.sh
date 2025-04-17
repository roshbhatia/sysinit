#!/bin/bash
# Fixed bashrc to handle common issues
# This file is managed by nix-darwin

# Fix TERM_PROGRAM unbound variable issue
if [ -z "$TERM_PROGRAM" ]; then
  export TERM_PROGRAM=""
fi

# Make sure gettext is always available
if [ -d "/opt/homebrew/opt/gettext/bin" ]; then
  export PATH="/opt/homebrew/opt/gettext/bin:$PATH"
fi

# Set NOSYSBASHRC to prevent issues
export NOSYSBASHRC=1

# Only execute this file once per shell.
if [ -n "$__ETC_BASHRC_SOURCED" ]; then return; fi
__ETC_BASHRC_SOURCED=1

# Basic bash configuration
if [ -z "$__NIX_DARWIN_SET_ENVIRONMENT_DONE" ]; then
  if [ -f /nix/store/*/set-environment ]; then
    source /nix/store/*/set-environment
  fi
fi

# Return early if not running interactively, but after basic nix setup.
[[ $- != *i* ]] && return

# Make bash check its window size after a process completes
shopt -s checkwinsize

# Setup Homebrew if available
if command -v brew &>/dev/null; then
  eval "$(brew shellenv 2>/dev/null || true)"
fi

# Read system-wide modifications.
if test -f /etc/bash.local; then
  source /etc/bash.local
fi