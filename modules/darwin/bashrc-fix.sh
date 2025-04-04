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

# Include the standard bashrc if it exists
if [ -r "/etc/bashrc_original" ]; then
  source "/etc/bashrc_original"
fi