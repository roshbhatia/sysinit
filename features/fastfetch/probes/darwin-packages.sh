#!/usr/bin/env bash
set -euo pipefail

brew_count="$({ ls -1 /opt/homebrew/Cellar 2> /dev/null || true; } | wc -l | tr -d ' ')"
cask_count="$({ ls -1 /opt/homebrew/Caskroom 2> /dev/null || true; } | wc -l | tr -d ' ')"
mas_count="$({ mas list 2> /dev/null || true; } | wc -l | tr -d ' ')"

printf '%s (brew), %s (brew-cask), %s (mas)' "${brew_count}" "${cask_count}" "${mas_count}"
