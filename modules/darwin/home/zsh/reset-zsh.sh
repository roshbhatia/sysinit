#!/usr/bin/env bash
# This script resets ZSH configuration for a clean start

set -e

echo "Resetting ZSH configuration..."

# Remove zcompdump files
rm -f ~/.zcompdump*
rm -f ~/.zcompcache/*

# Remove plugins directory
echo "Would you like to remove the ZSH plugins directory? (y/n)"
read -r response
if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
  rm -rf ~/.zsh/plugins
  echo "Removed ZSH plugins directory"
else
  echo "Keeping ZSH plugins directory"
fi

# Clean up ZSH caches
rm -rf "$HOME/.zsh/cache"
rm -rf "$XDG_DATA_HOME/zsh/evalcache" "$HOME/.zsh/evalcache"

echo "ZSH configuration reset completed"
echo "Please run the following command to rebuild your configuration:"
echo "cd /projects/roshbhatia/sysinit && task refresh"
