#!/usr/bin/env bash
set -euo pipefail

echo "Running Lua LSP diagnostics"

total_warnings=0
total_errors=0

for dir in modules/home/configurations/neovim \
  modules/home/configurations/wezterm \
  modules/home/configurations/hammerspoon \
  modules/home/configurations/sketchybar; do
  if [ -d "$dir" ]; then
    echo "Checking $dir"
    output=$(lua-language-server --check "$dir" 2>&1 || true)

    # Count actual errors (not warnings)
    error_count=$(echo "$output" | grep -c "\[Error\]" || true)
    warning_count=$(echo "$output" | grep -c "\[Warning\]" || true)

    total_errors=$((total_errors + error_count))
    total_warnings=$((total_warnings + warning_count))

    if [ $error_count -gt 0 ]; then
      echo "Found $error_count errors in $dir"
    elif [ $warning_count -gt 0 ]; then
      echo "Found $warning_count warnings in $dir (non-blocking)"
    fi
  fi
done

if [ $total_errors -gt 0 ]; then
  echo "Lua LSP found $total_errors errors across all directories"
  exit 1
fi

if [ $total_warnings -gt 0 ]; then
  echo "Lua LSP complete: $total_warnings warnings, 0 errors"
else
  echo "All Lua files passed LSP checks with no issues"
fi
