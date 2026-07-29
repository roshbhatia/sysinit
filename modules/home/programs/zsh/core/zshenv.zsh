#!/usr/bin/env zsh
# shellcheck disable=all
# Source .zshenv for user-specific environment variables. In a fragment file
# rather than inline in default.nix so the parse check covers it.

[ -f "$HOME/.zshenv" ] && source "$HOME/.zshenv"
